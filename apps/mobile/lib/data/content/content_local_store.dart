import '../local/app_database.dart';

/// Yerelde saklanan içerik (sürüm + ham JSON gövdesi).
class CachedContent {
  const CachedContent(this.version, this.body);
  final String version;
  final String body;
}

/// İçerik anlık görüntüsü yerel deposu (çevrimdışı önbellek). Test edilebilirlik için arayüz:
/// cihazda drift, testlerde bellek-içi sahte.
abstract class ContentLocalStore {
  Future<CachedContent?> read();
  Future<void> write({required String version, required String body});
}

/// Gerçek depo — drift (SQLite). Cihazda kullanılır.
class DriftContentLocalStore implements ContentLocalStore {
  DriftContentLocalStore(this._db);
  final AppDatabase _db;
  static const _key = 'content-snapshot';

  @override
  Future<CachedContent?> read() async {
    final doc = await _db.getDocument(_key);
    if (doc == null) return null;
    return CachedContent(doc.version, doc.body);
  }

  @override
  Future<void> write({required String version, required String body}) =>
      _db.putDocument(key: _key, version: version, body: body);
}

/// Bellek-içi depo — testler (platform kanalı / native SQLite gerektirmez).
class MemoryContentLocalStore implements ContentLocalStore {
  MemoryContentLocalStore([this._cached]);
  CachedContent? _cached;

  @override
  Future<CachedContent?> read() async => _cached;

  @override
  Future<void> write({required String version, required String body}) async {
    _cached = CachedContent(version, body);
  }
}
