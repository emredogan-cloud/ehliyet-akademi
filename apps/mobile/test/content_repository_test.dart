import 'dart:convert';

import 'package:ehliyet_akademi/data/content/content_api.dart';
import 'package:ehliyet_akademi/data/content/content_local_store.dart';
import 'package:ehliyet_akademi/data/content/content_repository.dart';
import 'package:ehliyet_akademi/domain/content/content_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Configurable fake content API — no network.
class FakeContentApi implements ContentApi {
  FakeContentApi({this.snapshot, this.notModified = false, this.throwError = false});
  ContentSnapshot? snapshot;
  bool notModified;
  bool throwError;
  int calls = 0;
  String? lastEtag;

  @override
  Future<SnapshotFetch> fetch({String? etag}) async {
    calls++;
    lastEtag = etag;
    if (throwError) throw Exception('offline');
    if (notModified) return const SnapshotFetch(notModified: true);
    final s = snapshot!;
    return SnapshotFetch(
      notModified: false,
      snapshot: s,
      rawJson: jsonEncode(s.toJson()),
      version: s.version,
    );
  }
}

void main() {
  group('ContentRepository (offline-first)', () {
    test('no cache + online → fetches, caches, returns snapshot', () async {
      final store = MemoryContentLocalStore();
      final api = FakeContentApi(snapshot: sampleSnapshot());
      final repo = ContentRepository(api, store);

      final snap = await repo.load();

      expect(snap.version, 'test-v1');
      expect(api.calls, 1);
      expect(api.lastEtag, isNull); // no cache → no If-None-Match
      expect((await store.read())!.version, 'test-v1'); // now cached
    });

    test('cache present + server unchanged (304) → returns cached, sends ETag', () async {
      final cached = sampleSnapshot();
      final store = MemoryContentLocalStore(
        CachedContent(cached.version, jsonEncode(cached.toJson())),
      );
      final api = FakeContentApi(notModified: true);
      final repo = ContentRepository(api, store);

      final snap = await repo.load();

      expect(snap.version, 'test-v1');
      expect(api.calls, 1);
      expect(api.lastEtag, '"test-v1"');
    });

    test('cache present + offline (fetch throws) → returns cached', () async {
      final cached = sampleSnapshot();
      final store = MemoryContentLocalStore(
        CachedContent(cached.version, jsonEncode(cached.toJson())),
      );
      final api = FakeContentApi(throwError: true);
      final repo = ContentRepository(api, store);

      final snap = await repo.load();

      expect(snap.signs.length, cached.signs.length);
      expect(api.calls, 1);
    });

    test('no cache + offline → throws (first run needs network)', () async {
      final store = MemoryContentLocalStore();
      final api = FakeContentApi(throwError: true);
      final repo = ContentRepository(api, store);

      expect(repo.load(), throwsA(isA<Exception>()));
    });
  });
}
