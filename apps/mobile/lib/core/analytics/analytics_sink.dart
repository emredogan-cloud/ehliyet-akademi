import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics.dart';

/// Bir olayın gideceği yer.
abstract class AnalyticsSink {
  Future<void> add(AnalyticsRecord record);

  /// Bekleyen kayıtları gönder. Bellek-içi sink için işlemsizdir.
  Future<void> flush() async {}
}

/// Testlerin ve hata ayıklamanın kullandığı sink — hiçbir yere gitmez, listede tutar.
class MemoryAnalyticsSink implements AnalyticsSink {
  final List<AnalyticsRecord> records = [];

  /// Gönderilen olay adları (testte okunması en kolay biçim).
  List<String> get names => [for (final r in records) r.name];

  /// Belirli bir olayın kaç kez gönderildiği.
  int count(String name) => records.where((r) => r.name == name).length;

  /// Bir olayın SON gönderiminin boyutları (yoksa null).
  Map<String, Object?>? propsOf(String name) {
    for (final r in records.reversed) {
      if (r.name == name) return r.props;
    }
    return null;
  }

  @override
  Future<void> add(AnalyticsRecord record) async => records.add(record);

  @override
  Future<void> flush() async {}
}

/// Hata ayıklama derlemesinde olayları konsola yazan sink (üretimde kullanılmaz).
class DebugAnalyticsSink implements AnalyticsSink {
  @override
  Future<void> add(AnalyticsRecord record) async {
    debugPrint('[analytics] ${record.name} ${record.props}');
  }

  @override
  Future<void> flush() async {}
}

/// Birden çok sink'e aynı olayı verir. Biri patlarsa DİĞERLERİ ETKİLENMEZ.
class FanOutAnalyticsSink implements AnalyticsSink {
  FanOutAnalyticsSink(this._sinks);
  final List<AnalyticsSink> _sinks;

  @override
  Future<void> add(AnalyticsRecord record) async {
    for (final s in _sinks) {
      try {
        await s.add(record);
      } catch (_) {}
    }
  }

  @override
  Future<void> flush() async {
    for (final s in _sinks) {
      try {
        await s.flush();
      } catch (_) {}
    }
  }
}

const _kQueue = 'ea:analytics:queue:v1';

/// Kaç kayıt gönderilmemiş hâlde tutulur.
///
/// NEDEN SINIR VAR: uzun süre çevrimdışı kalan bir cihazda kuyruk sınırsız büyürse hem tercihler
/// dosyası şişer hem de ilk bağlantıda tek seferde çok büyük bir gövde gönderilir. Sınıra
/// gelindiğinde **en ESKİ** kayıtlar düşer: yeni davranış, eski davranıştan daha değerlidir.
const int kAnalyticsQueueLimit = 500;

/// Tek istekte gönderilen kayıt sayısı.
const int kAnalyticsBatchSize = 50;

/// Beta Faz 3 — kalıcı kuyruklu, çevrimdışına DAYANIKLI sunucu sink'i.
///
/// Olay önce diske yazılır, sonra gönderilmeye çalışılır. Gönderim başarısızsa kayıt kuyrukta
/// KALIR ve bir sonraki denemede tekrar gönderilir.
///
/// NEDEN diske yazıp sonra gönderiyoruz: tersi (gönder, olmazsa diske yaz) uygulamanın gönderim
/// sırasında kapanmasında olayı kaybeder. Sıralama böyle olduğunda kaybedilebilecek tek şey
/// **çift gönderim**dir; onu da sunucu tarafındaki kayıt kimliği (`analytics_events.id` tekil)
/// eler. Kayıp yerine tekrar seçilir; tekrar düzeltilebilir, kayıp düzeltilemez.
class RemoteAnalyticsSink implements AnalyticsSink {
  RemoteAnalyticsSink(this._dio);
  final Dio _dio;

  bool _flushing = false;

  @override
  Future<void> add(AnalyticsRecord record) async {
    await _appendToQueue(record);
    // Beklemeden tetikle: olay kaydetmek çağıranı ağ gecikmesi kadar bekletmemeli.
    flush().ignore();
  }

  Future<void> _appendToQueue(AnalyticsRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queued = decodeRecords(prefs.getString(_kQueue) ?? '[]')..add(record);
      final trimmed = queued.length > kAnalyticsQueueLimit
          ? queued.sublist(queued.length - kAnalyticsQueueLimit)
          : queued;
      await prefs.setString(_kQueue, encodeRecords(trimmed));
    } catch (_) {}
  }

  @override
  Future<void> flush() async {
    // Aynı anda iki boşaltma, aynı kayıtları iki kez gönderir ve kuyruğu yarışa sokar.
    if (_flushing) return;
    _flushing = true;
    try {
      for (;;) {
        final prefs = await SharedPreferences.getInstance();
        final queued = decodeRecords(prefs.getString(_kQueue) ?? '[]');
        if (queued.isEmpty) return;

        final batch = queued.take(kAnalyticsBatchSize).toList();
        final sent = await _send(batch);
        // Gönderilemedi: kuyruk OLDUĞU GİBİ kalır, bir sonraki tetiklemede tekrar denenir.
        if (!sent) return;

        // Boşaltma sırasında yeni olaylar eklenmiş olabilir; kuyruğu YENİDEN okuyup yalnız
        // gönderilenleri çıkar — `sublist` yapmak arada eklenen olayı silerdi.
        final sentIds = {for (final r in batch) r.id};
        final after = decodeRecords(prefs.getString(_kQueue) ?? '[]')
            .where((r) => !sentIds.contains(r.id))
            .toList();
        await prefs.setString(_kQueue, encodeRecords(after));
        if (after.isEmpty) return;
      }
    } catch (_) {
    } finally {
      _flushing = false;
    }
  }

  /// Gövde gönderildi mi? Sunucu 2xx dönerse evet.
  ///
  /// 4xx **kalıcı** bir hatadır (gövde biçimi/yetki): tekrar denemek sonsuz döngü olur, bu yüzden
  /// kayıtlar kuyruktan DÜŞÜRÜLÜR (true). 5xx ve ağ hatası geçicidir → kuyrukta kalır (false).
  Future<bool> _send(List<AnalyticsRecord> batch) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/analytics/collect',
        data: {'events': [for (final r in batch) r.toJson()]},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      final code = res.statusCode ?? 0;
      return code >= 200 && code < 500;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Kuyrukta bekleyen kayıt sayısı (tanılama ve test için).
  static Future<int> pendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return decodeRecords(prefs.getString(_kQueue) ?? '[]').length;
    } catch (_) {
      return 0;
    }
  }
}
