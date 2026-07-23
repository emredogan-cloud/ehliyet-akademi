import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

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

/// Sahip olunan ürünler (yetenek kaynağı). Yerelde önbelleklenir (`ea:entitlements:v1`, SET —
/// sunucu kazanır), oturum açıkken sunucudan tazelenir.
class EntitlementsController extends Notifier<List<String>> {
  @override
  List<String> build() {
    Future.microtask(_load);
    return const [];
  }

  EntitlementsApi get _api => ref.read(entitlementsApiProvider);

  Future<void> _load() async {
    // Önce yerel önbellek (çevrimdışı gösterim), sonra sunucudan tazele.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kEntitlements);
      if (raw != null) {
        state = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    await refresh();
  }

  /// Sunucudan sahiplik listesini yeniden türet (SET, bayat haklar temizlenir).
  Future<void> refresh() async {
    try {
      final owned = await _api.fetchOwned();
      await _cache(owned);
      state = owned;
    } catch (_) {
      // ağ/oturum yok → önbellek korunur
    }
  }

  /// Doğrulanmış satın almadan gelen güncel sahipliği uygula.
  Future<void> applyOwned(List<String> owned) async {
    await _cache(owned);
    state = owned;
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
