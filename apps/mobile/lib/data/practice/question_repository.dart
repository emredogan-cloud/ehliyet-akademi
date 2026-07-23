import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../domain/practice/question_bank.dart';
import '../content/content_repository.dart' show appDatabaseProvider;
import '../local/app_database.dart';

/// Soru bankası çekme sonucu (304 ise notModified → yerel geçerli).
class BankFetch {
  const BankFetch({required this.notModified, this.bank, this.rawJson, this.version});
  final bool notModified;
  final QuestionBank? bank;
  final String? rawJson;
  final String? version;
}

abstract class QuestionApi {
  Future<BankFetch> fetch({String? etag});
}

class DioQuestionApi implements QuestionApi {
  DioQuestionApi(this._dio);
  final Dio _dio;

  @override
  Future<BankFetch> fetch({String? etag}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/mobile/question-bank',
      options: Options(
        headers: etag != null ? {'if-none-match': etag} : null,
        responseType: ResponseType.json,
        validateStatus: (s) => s == 200 || s == 304,
      ),
    );
    if (res.statusCode == 304) return const BankFetch(notModified: true);
    final data = res.data!;
    final bank = QuestionBank.fromJson(data);
    return BankFetch(notModified: false, bank: bank, rawJson: jsonEncode(data), version: bank.version);
  }
}

/// Yerelde saklanan bankanın sürüm + gövdesi.
class CachedBank {
  const CachedBank(this.version, this.body);
  final String version;
  final String body;
}

/// Soru bankası yerel deposu (drift; testlerde bellek-içi sahte).
abstract class QuestionLocalStore {
  Future<CachedBank?> read();
  Future<void> write({required String version, required String body});
}

class DriftQuestionLocalStore implements QuestionLocalStore {
  DriftQuestionLocalStore(this._db);
  final AppDatabase _db;
  static const _key = 'question-bank';

  @override
  Future<CachedBank?> read() async {
    final doc = await _db.getDocument(_key);
    return doc == null ? null : CachedBank(doc.version, doc.body);
  }

  @override
  Future<void> write({required String version, required String body}) =>
      _db.putDocument(key: _key, version: version, body: body);
}

class MemoryQuestionLocalStore implements QuestionLocalStore {
  MemoryQuestionLocalStore([this._cached]);
  CachedBank? _cached;

  @override
  Future<CachedBank?> read() async => _cached;

  @override
  Future<void> write({required String version, required String body}) async {
    _cached = CachedBank(version, body);
  }
}

/// Çevrimdışı-öncelik soru bankası deposu (içerik deposuyla aynı desen).
class QuestionRepository {
  QuestionRepository(this._api, this._store);
  final QuestionApi _api;
  final QuestionLocalStore _store;

  Future<QuestionBank> load() async {
    final cached = await _store.read();
    if (cached != null) {
      try {
        final res = await _api.fetch(etag: '"${cached.version}"');
        if (res.notModified) return _decode(cached.body);
        await _store.write(version: res.version!, body: res.rawJson!);
        return res.bank!;
      } catch (_) {
        return _decode(cached.body);
      }
    }
    final res = await _api.fetch();
    await _store.write(version: res.version!, body: res.rawJson!);
    return res.bank!;
  }

  QuestionBank _decode(String body) =>
      QuestionBank.fromJson(jsonDecode(body) as Map<String, dynamic>);
}

final questionLocalStoreProvider = Provider<QuestionLocalStore>(
  (ref) => DriftQuestionLocalStore(ref.watch(appDatabaseProvider)),
);

final questionApiProvider = Provider<QuestionApi>((ref) => DioQuestionApi(ref.watch(dioProvider)));

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(ref.watch(questionApiProvider), ref.watch(questionLocalStoreProvider)),
);

/// Uygulama genelinde soru bankası (yükleniyor / hata / veri).
final questionBankProvider = FutureProvider<QuestionBank>(
  (ref) => ref.watch(questionRepositoryProvider).load(),
);
