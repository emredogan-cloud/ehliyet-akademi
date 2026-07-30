import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/content/content_snapshot.dart';
import '../local/app_database.dart';
import 'content_api.dart';
import 'content_local_store.dart';

/// İçerik deposu — çevrimdışı-öncelik. Yerel önbellek varsa hemen onu kullanır; çevrimiçiyse ETag
/// ile arka planda tazeler; sürüm değiştiyse yeni anlık görüntüyü kaydeder.
class ContentRepository {
  ContentRepository(this._api, this._store);
  final ContentApi _api;
  final ContentLocalStore _store;

  /// İçeriği getir.
  ///
  /// ## Beta Faz 5 — önbellek ARTIK BEKLETMİYOR (cihazda ölçülerek bulundu)
  ///
  /// Eski davranış "çevrimdışı-öncelik" idi ama yalnız **depolamada**; gecikmede değildi. Önbellek
  /// dolu olsa bile şu sıra izleniyordu:
  ///
  ///   önbelleği oku → **ağı bekle** → hata gelirse önbelleği döndür
  ///
  /// Ağ yokken o "hata" hemen gelmez: bağlantı zaman aşımı dolana kadar (12 sn) beklenir. Yani
  /// uçaktaki kullanıcı, telefonunda ZATEN DURAN dersleri görmek için on iki saniye bekliyordu.
  /// Cihazda görüldü: Öğren ekranında sayıların bir kısmı hemen çıkarken içerikten gelen satır
  /// uzun süre "—" kalıyordu.
  ///
  /// Yeni sıra: **önbellek varsa ANINDA döner**, tazeleme arka planda yapılır. Tazeleme yeni bir
  /// sürüm getirirse diske yazılır ve bir sonraki açılışta görünür — içeriğin kullanıcı okurken
  /// altından değişmesi zaten istenmez.
  Future<ContentSnapshot> load() async {
    final cached = await _store.read();

    if (cached != null) {
      // Arka planda tazele; BEKLEME. Hata yutulur — çevrimdışı olmak bir arıza değildir.
      _refreshInBackground(cached.version);
      return _decode(cached.body);
    }

    // Önbellek yok → ilk kez çevrimiçi indirilmeli (ağ yoksa hata fırlatır → dürüst hata durumu
    // ve "tekrar dene" gösterilir; `ContentBuilder`).
    final res = await _api.fetch();
    await _store.write(version: res.version!, body: res.rawJson!);
    return res.snapshot!;
  }

  /// Sürüm değiştiyse yeni anlık görüntüyü diske al. Beklenmez, hata yutulur.
  ///
  /// Test edilebilir olması için ayrı: `load()` artık dönüşünü beklemediğinden, tazelemenin
  /// gerçekten yapıldığı ancak buraya bakarak doğrulanabilir.
  @visibleForTesting
  Future<void> refreshFromNetwork(String cachedVersion) async {
    final res = await _api.fetch(etag: '"$cachedVersion"');
    if (res.notModified) return;
    await _store.write(version: res.version!, body: res.rawJson!);
  }

  void _refreshInBackground(String cachedVersion) {
    refreshFromNetwork(cachedVersion).catchError((Object _) {});
  }

  ContentSnapshot _decode(String body) =>
      ContentSnapshot.fromJson(jsonDecode(body) as Map<String, dynamic>);
}

/// Yerel drift veritabanı (cihaz). Testlerde [contentLocalStoreProvider] override edilir → burası kurulmaz.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final contentLocalStoreProvider = Provider<ContentLocalStore>(
  (ref) => DriftContentLocalStore(ref.watch(appDatabaseProvider)),
);

final contentApiProvider = Provider<ContentApi>((ref) => DioContentApi(ref.watch(dioProvider)));

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(contentApiProvider), ref.watch(contentLocalStoreProvider)),
);

/// Uygulama genelinde içerik anlık görüntüsü (yükleniyor / hata / veri).
final contentSnapshotProvider = FutureProvider<ContentSnapshot>(
  (ref) => ref.watch(contentRepositoryProvider).load(),
);
