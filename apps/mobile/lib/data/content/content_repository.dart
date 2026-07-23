import 'dart:convert';

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

  Future<ContentSnapshot> load() async {
    final cached = await _store.read();

    if (cached != null) {
      // Önbellek var → ETag ile tazelemeyi dene; her ağ hatasında önbelleği koru (çevrimdışı çalışır).
      try {
        final res = await _api.fetch(etag: '"${cached.version}"');
        if (res.notModified) return _decode(cached.body);
        await _store.write(version: res.version!, body: res.rawJson!);
        return res.snapshot!;
      } catch (_) {
        return _decode(cached.body);
      }
    }

    // Önbellek yok → ilk kez çevrimiçi indirilmeli (ağ yoksa hata fırlatır → hata durumu gösterilir).
    final res = await _api.fetch();
    await _store.write(version: res.version!, body: res.rawJson!);
    return res.snapshot!;
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
