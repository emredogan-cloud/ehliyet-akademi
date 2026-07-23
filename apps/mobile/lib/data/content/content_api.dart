import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/content/content_snapshot.dart';

/// İçerik anlık görüntüsü çekme sonucu. 304 ise [notModified] true (yerel önbellek geçerli).
class SnapshotFetch {
  const SnapshotFetch({required this.notModified, this.snapshot, this.rawJson, this.version});
  final bool notModified;
  final ContentSnapshot? snapshot;
  final String? rawJson;
  final String? version;
}

/// İçerik API sözleşmesi (testlerde sahte ile değiştirilebilir).
abstract class ContentApi {
  /// [etag] verilirse `If-None-Match` gönderir; sunucu değişmediyse 304 → notModified.
  Future<SnapshotFetch> fetch({String? etag});
}

class DioContentApi implements ContentApi {
  DioContentApi(this._dio);
  final Dio _dio;

  @override
  Future<SnapshotFetch> fetch({String? etag}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/content-snapshot',
      options: Options(
        headers: etag != null ? {'if-none-match': etag} : null,
        responseType: ResponseType.json,
        // 200 (yeni içerik) veya 304 (değişmedi) kabul; diğerleri hata.
        validateStatus: (s) => s == 200 || s == 304,
      ),
    );
    if (res.statusCode == 304) {
      return const SnapshotFetch(notModified: true);
    }
    final data = res.data!;
    final snapshot = ContentSnapshot.fromJson(data);
    return SnapshotFetch(
      notModified: false,
      snapshot: snapshot,
      rawJson: jsonEncode(data),
      version: snapshot.version,
    );
  }
}
