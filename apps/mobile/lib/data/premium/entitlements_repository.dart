import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';
import '../../core/network/api_client.dart';
import '../../domain/premium/products.dart';
import 'store_purchase_store.dart';

const _kEntitlements = 'ea:entitlements:v1';

/// Satın alma / yetenek API'si. Sahiplik SUNUCUDAN türetilir (purchases tablosu) — asla senkron
/// edilen bir anahtara güvenilmez (web P0: aynı tarayıcıda kullanıcı sızıntısı).
abstract class EntitlementsApi {
  /// GET /api/purchases → sahip olunan ürün id listesi. Oturum yoksa boş.
  Future<List<String>> fetchOwned();

  /// POST /api/iap/validate → Google Play makbuzunu doğrula + hak ver → güncel sahiplik.
  Future<List<String>> validatePurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  });
}

class DioEntitlementsApi implements EntitlementsApi {
  DioEntitlementsApi(this._dio);
  final Dio _dio;

  @override
  Future<List<String>> fetchOwned() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/purchases',
      options: Options(responseType: ResponseType.json, validateStatus: (s) => s == 200 || s == 401),
    );
    if (res.statusCode != 200) return const [];
    final list = (res.data?['purchases'] as List?) ?? const [];
    return list.map((e) => (e as Map)['productId'].toString()).toSet().toList();
  }

  @override
  Future<List<String>> validatePurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/iap/validate',
      data: {'productId': productId, 'purchaseToken': purchaseToken, 'packageName': packageName},
      options: Options(responseType: ResponseType.json, validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode != 200) {
      throw Exception('validate failed (${res.statusCode})');
    }
    final owned = (res.data?['owned'] as List?) ?? const [];
    return owned.map((e) => e.toString()).toList();
  }
}

/// Sahip olunan ürünler — yetenek kaynağı.
///
/// Faz 2: sahiplik artık İKİ kaynağın BİRLEŞİMİDİR ve bu, kök nedenin doğrudan karşılığıdır:
///
/// · **Sunucu** (`GET /api/purchases`) — çapraz cihaz senkronunun kaynağı, oturum ŞART.
/// · **Cihazdaki mağaza defteri** ([StorePurchaseStore]) — Play'in `purchased`/`restored` olarak
///   onayladığı satın almalar. Oturum GEREKTİRMEZ.
///
/// Eskiden yalnız birincisi vardı. Uygulama misafir kullanımına açık olduğu için, misafirken
/// satın alan kullanıcının hakkı hiçbir yere yazılamıyor ve özellikler kilitli kalıyordu.
/// İkisinin birleşimi bunu kapatır: para ödendiyse erişim açıktır, oturum olsun ya da olmasın.
class EntitlementsController extends Notifier<List<String>> {
  @override
  List<String> build() {
    Future.microtask(_load);
    return const [];
  }

  EntitlementsApi get _api => ref.read(entitlementsApiProvider);
  StorePurchaseStore get _store => ref.read(storePurchaseStoreProvider);

  /// Sunucudan gelen sahiplik (önbelleklenmiş hâli dâhil). Birleşimin bir yarısı.
  List<String> _serverOwned = const [];

  Future<void> _load() async {
    // Önce yerel önbellek (çevrimdışı gösterim), sonra sunucudan tazele.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kEntitlements);
      if (raw != null) {
        _serverOwned = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    await _publish();
    await refresh();
    // Açılışta bekleyen makbuz varsa sunucuya bağlamayı dene (ağ/oturum o sırada gelmiş olabilir).
    await bindPendingPurchases();
  }

  /// Sunucudan sahiplik listesini yeniden türet (SET, bayat haklar temizlenir).
  Future<void> refresh() async {
    try {
      _serverOwned = await _api.fetchOwned();
      await _cache(_serverOwned);
    } catch (_) {
      // ağ/oturum yok → önbellek korunur
    }
    await _publish();
  }

  /// Doğrulanmış satın almadan gelen güncel sunucu sahipliğini uygula.
  Future<void> applyOwned(List<String> owned) async {
    _serverOwned = owned;
    await _cache(owned);
    await _publish();
  }

  /// Faz 2 — MAĞAZANIN onayladığı bir satın almayı hakka çevir.
  ///
  /// Sıra önemlidir: **önce cihaza yaz, sonra sunucuya bağlamayı dene**. Tersi yapıldığında
  /// (eski davranış) sunucu 401 dönünce istisna fırlıyor ve hak hiç verilmiyordu. Artık sunucu
  /// ulaşılamazsa bile erişim açılır; makbuz kuyrukta bekler.
  ///
  /// Dönüş: sunucuya bağlanabildiyse `true`.
  Future<bool> grantFromStore({
    required String storeProductId,
    String? purchaseToken,
    required int nowMs,
  }) async {
    await _store.add(
      StorePurchase(storeProductId: storeProductId, purchaseToken: purchaseToken, atMs: nowMs),
    );
    await _publish();
    return _bind(storeProductId: storeProductId, purchaseToken: purchaseToken);
  }

  /// Kuyrukta bekleyen makbuzları sunucuya bağlamayı dene (oturum açılınca / açılışta / geri
  /// yüklemede çağrılır). Sessizdir: başarısızlık kullanıcıya yansımaz, erişim zaten açıktır.
  Future<void> bindPendingPurchases() async {
    for (final p in await _store.read()) {
      final token = p.purchaseToken;
      if (token == null || token.isEmpty) continue;
      await _bind(storeProductId: p.storeProductId, purchaseToken: token);
    }
  }

  Future<bool> _bind({required String storeProductId, String? purchaseToken}) async {
    if (purchaseToken == null || purchaseToken.isEmpty) return false;
    final serverId = productByStoreId(storeProductId)?.id ?? storeProductId.replaceAll('_', '-');
    try {
      final owned = await _api.validatePurchase(
        productId: serverId,
        purchaseToken: purchaseToken,
        packageName: AppConfig.androidPackage,
      );
      _serverOwned = owned;
      await _cache(owned);
      await _store.markBound(storeProductId);
      await _publish();
      return true;
    } catch (_) {
      // Oturum yok / ağ yok / sunucu hatası → makbuz kuyrukta kalır, erişim açık kalır.
      return false;
    }
  }

  /// Çıkışta yalnız SUNUCU tarafı sahiplik silinir.
  ///
  /// `ea:entitlements:v1` kullanıcıya aittir; aynı telefonda oturum açan ikinci kullanıcı
  /// birincinin premium'unu görmemeli (web'deki P0'ın mobil karşılığı).
  ///
  /// Cihazdaki mağaza defteri KORUNUR: o kayıt kullanıcıya değil, cihazdaki **Play hesabına**
  /// aittir. Silinseydi, çıkış yapan kullanıcı kendi satın aldığı paketi kaybederdi.
  Future<void> clearForSignOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kEntitlements);
    } catch (_) {}
    _serverOwned = const [];
    await _publish();
  }

  /// İki kaynağı birleştirip yayımla.
  Future<void> _publish() async {
    final fromStore = <String>[
      for (final p in await _store.read())
        productByStoreId(p.storeProductId)?.id ?? p.storeProductId.replaceAll('_', '-'),
    ];
    state = {..._serverOwned, ...fromStore}.toList();
  }

  Future<void> _cache(List<String> owned) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEntitlements, jsonEncode(owned));
    } catch (_) {}
  }
}

final entitlementsApiProvider = Provider<EntitlementsApi>(
  (ref) => DioEntitlementsApi(ref.watch(dioProvider)),
);

final entitlementsProvider = NotifierProvider<EntitlementsController, List<String>>(
  EntitlementsController.new,
);
