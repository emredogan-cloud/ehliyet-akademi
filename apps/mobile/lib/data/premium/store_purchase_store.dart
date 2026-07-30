import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 2 — MAĞAZANIN onayladığı satın almaların CİHAZ defteri.
///
/// ## Neden böyle bir defter gerekti (kök neden)
///
/// Sahiplik yalnız sunucudan türetiliyordu (`GET /api/purchases`, oturum ŞART). Uygulama ise
/// misafir kullanımına açık. Sonuç, sahada görülen hata zinciriydi:
///
///   misafir → satın al → Play ödemeyi alır → `POST /api/iap/validate` **401** → istisna →
///   hak verilmez → özellikler KİLİTLİ → tekrar denerse Play "bu ürüne zaten sahipsin" der.
///
/// Yani kullanıcı parayı ödemiş, Play satın almayı kaydetmiş, ama uygulama bunu göremiyordu.
/// "Zaten sahipsin" hatası bir sebep değil, SONUÇTU.
///
/// ## Çözüm ve sınırı
///
/// Play'in `purchased`/`restored` olarak bildirdiği her satın alma buraya yazılır ve erişim
/// ANINDA açılır. Sunucu hâlâ çapraz cihaz senkronunun kaynağıdır; bağlanamadığımızda satın alma
/// [pendingTokens] kuyruğunda bekler ve oturum açılınca/uygulama açılınca yeniden denenir.
///
/// **Oturum kapatınca bu defter SİLİNMEZ** — ve bu bilinçlidir. Sunucu tarafı sahiplik
/// (`ea:entitlements:v1`) kullanıcıya aittir, çıkışta silinir. Buradaki kayıt ise CİHAZDAKİ Play
/// hesabına aittir: lisansın gerçek sahibi odur. Silinseydi, çıkış yapan kullanıcı kendi satın
/// aldığı paketi kaybederdi.
///
/// Dürüst sınır: kök erişimi olan bir cihazda bu dosya elle düzenlenebilir. Bu, istemci tarafında
/// hak tutan HER uygulamanın sınırıdır; sunucuya bağlı yüzeyler yine sunucudaki kayda bakar.

/// Mağazanın onayladığı tek bir satın alma.
class StorePurchase {
  const StorePurchase({
    required this.storeProductId,
    this.purchaseToken,
    this.atMs = 0,
    this.bound = false,
  });

  final String storeProductId;

  /// Play makbuzu. Sunucuya bağlama denemesi bunu kullanır; RevenueCat yolunda `null`'dır.
  final String? purchaseToken;
  final int atMs;

  /// Beta Faz 2 — bu satın alma sunucuya BAŞARIYLA bağlandı mı.
  ///
  /// NEDEN GEREKLİ: iade/geri alma tespitinin tek güvenli dayanağı budur. Sunucu bir ürünü
  /// vermiyorsa bunun iki farklı anlamı olabilir:
  ///   · "hiç bilmiyordum" (misafirken alınmış, hiç bağlanmamış) → hak KORUNMALI,
  ///   · "biliyordum, artık vermiyorum" (iade edildi) → hak DÜŞMELİ.
  /// İkisini ayırmadan defterden silmek, ödenmiş bir paketi kaybettirirdi.
  final bool bound;

  Map<String, dynamic> toJson() => {
    'p': storeProductId,
    if (purchaseToken != null) 't': purchaseToken,
    'at': atMs,
    if (bound) 'b': true,
  };

  static StorePurchase fromJson(Map<String, dynamic> j) => StorePurchase(
    storeProductId: (j['p'] ?? '').toString(),
    purchaseToken: j['t'] as String?,
    atMs: (j['at'] as num?)?.toInt() ?? 0,
    bound: j['b'] == true,
  );
}

const _kStorePurchases = 'ea:storePurchases:v1';

abstract class StorePurchaseStore {
  Future<List<StorePurchase>> read();

  /// Aynı ürün iki kez yazılmaz (ürün kimliğine göre tekil).
  Future<List<StorePurchase>> add(StorePurchase purchase);

  /// Sunucuya bağlanmayı bekleyen makbuzlar (bağlanınca çıkarılır).
  Future<void> markBound(String storeProductId);

  /// Beta Faz 2 — bir kaydı defterden ÇIKAR (iade/geri alma).
  ///
  /// Defter eskiden yalnız büyüyordu. Sahiplik `birleşim(sunucu, defter)` olarak yayımlandığı için
  /// iade edilmiş bir satın alma o cihazda SONSUZA KADAR premium veriyordu. Çıkarma yolu olmadan
  /// bunu düzeltmek imkânsızdı. Ne zaman çağrılacağının kuralı `EntitlementsController.refresh`
  /// içindedir — orada üç koşul birlikte aranır.
  Future<void> remove(String storeProductId);
}

class PrefsStorePurchaseStore implements StorePurchaseStore {
  @override
  Future<List<StorePurchase>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorePurchases);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List)
          .map((e) => StorePurchase.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<StorePurchase>> add(StorePurchase purchase) async {
    final all = [...await read()];
    final i = all.indexWhere((p) => p.storeProductId == purchase.storeProductId);
    if (i >= 0) {
      // Yeni makbuz eskisinin yerine geçer; token yenilenmiş olabilir.
      all[i] = purchase;
    } else {
      all.add(purchase);
    }
    await _write(all);
    return all;
  }

  @override
  Future<void> markBound(String storeProductId) async {
    final all = [...await read()];
    final i = all.indexWhere((p) => p.storeProductId == storeProductId);
    if (i < 0) return;
    // Kayıt SİLİNMEZ — erişimin kaynağı odur. Yalnız makbuz düşürülür: sunucuya bağlandı,
    // tekrar denemeye gerek yok. `bound` işareti KALIR: iade tespiti ona dayanır.
    all[i] = StorePurchase(
      storeProductId: all[i].storeProductId,
      atMs: all[i].atMs,
      bound: true,
    );
    await _write(all);
  }

  @override
  Future<void> remove(String storeProductId) async {
    final all = [...await read()]..removeWhere((p) => p.storeProductId == storeProductId);
    await _write(all);
  }

  Future<void> _write(List<StorePurchase> all) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStorePurchases, jsonEncode([for (final p in all) p.toJson()]));
    } catch (_) {}
  }
}

/// Testlerde kullanılan bellek-içi defter.
class MemoryStorePurchaseStore implements StorePurchaseStore {
  MemoryStorePurchaseStore([List<StorePurchase>? initial]) : _all = [...?initial];
  final List<StorePurchase> _all;

  @override
  Future<List<StorePurchase>> read() async => List.unmodifiable(_all);

  @override
  Future<List<StorePurchase>> add(StorePurchase purchase) async {
    final i = _all.indexWhere((p) => p.storeProductId == purchase.storeProductId);
    if (i >= 0) {
      _all[i] = purchase;
    } else {
      _all.add(purchase);
    }
    return List.unmodifiable(_all);
  }

  @override
  Future<void> markBound(String storeProductId) async {
    final i = _all.indexWhere((p) => p.storeProductId == storeProductId);
    if (i < 0) return;
    _all[i] = StorePurchase(
      storeProductId: _all[i].storeProductId,
      atMs: _all[i].atMs,
      bound: true,
    );
  }

  @override
  Future<void> remove(String storeProductId) async {
    _all.removeWhere((p) => p.storeProductId == storeProductId);
  }
}

final storePurchaseStoreProvider = Provider<StorePurchaseStore>(
  (ref) => PrefsStorePurchaseStore(),
);
