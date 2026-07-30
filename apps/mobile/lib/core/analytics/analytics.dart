import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_version.dart';
import 'analytics_event.dart';
import 'analytics_sink.dart';

/// Bir olayın yanına eklenen değişmez bağlam.
///
/// `userId` YOK OLABİLİR: misafir kullanım gerçektir. Kimliksiz olayları [anonId] birbirine bağlar —
/// cihaz başına bir kez üretilen rastgele bir dize; kişiyi tanımlamaz, reklam kimliği DEĞİLDİR ve
/// hiçbir yerden satın alınmamıştır.
@immutable
class AnalyticsContext {
  const AnalyticsContext({
    required this.anonId,
    required this.appVersion,
    this.userId,
    this.platform = 'android',
  });

  final String anonId;
  final String appVersion;
  final String? userId;
  final String platform;

  AnalyticsContext withUser(String? id) => AnalyticsContext(
    anonId: anonId,
    appVersion: appVersion,
    userId: id,
    platform: platform,
  );
}

/// Kuyruğa/sunucuya giden tek kayıt.
@immutable
class AnalyticsRecord {
  const AnalyticsRecord({
    required this.id,
    required this.name,
    required this.props,
    required this.at,
    required this.context,
  });

  /// İstemcide üretilen kimlik — sunucu aynı kaydı İKİ KEZ yazmasın diye (kuyruk yeniden gönderir).
  final String id;
  final String name;
  final Map<String, Object?> props;
  final DateTime at;
  final AnalyticsContext context;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'props': props,
    'at': at.toUtc().toIso8601String(),
    'anonId': context.anonId,
    if (context.userId != null) 'userId': context.userId,
    'platform': context.platform,
    'appVersion': context.appVersion,
  };

  static AnalyticsRecord? fromJson(Map<String, Object?> j) {
    final id = j['id'];
    final name = j['name'];
    final at = DateTime.tryParse((j['at'] ?? '').toString());
    if (id is! String || name is! String || at == null) return null;
    return AnalyticsRecord(
      id: id,
      name: name,
      props: (j['props'] as Map?)?.cast<String, Object?>() ?? const {},
      at: at,
      context: AnalyticsContext(
        anonId: (j['anonId'] ?? '').toString(),
        appVersion: (j['appVersion'] ?? '').toString(),
        userId: j['userId']?.toString(),
        platform: (j['platform'] ?? 'android').toString(),
      ),
    );
  }
}

const _kAnonId = 'ea:analytics:anonId:v1';
const _kOncePrefix = 'ea:analytics:once:';

/// Beta Faz 3 — analitiğin TEK giriş kapısı.
///
/// Ekranlar ve depolar bu sınıfa `log(...)` der; kuyruk, toplu gönderim, yeniden deneme ve gizlilik
/// kuralları burada yaşar. Çağıran taraf ağdan, sıradan, oturumdan HABERSİZDİR.
///
/// **Analitik asla ürünü kırmaz.** Her yol `try/catch` içindedir ve hata yutulur: bir ölçüm
/// başarısızlığının kullanıcıya bir hata göstermesi ya da bir akışı durdurması kabul edilemez.
class Analytics {
  Analytics({required AnalyticsSink sink, DateTime Function()? clock, Random? random})
    : _sink = sink,
      _now = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final AnalyticsSink _sink;
  final DateTime Function() _now;
  final Random _random;

  AnalyticsContext? _context;
  String? _userId;

  /// Şu anki bağlam (test ve tanılama için).
  AnalyticsContext? get context => _context;

  /// Beta Faz 4 — son olayların adları ("kullanıcı çökmeden hemen önce ne yaptı").
  ///
  /// Bir yığın izi NEREDE kırıldığını söyler, NASIL gelindiğini söylemez. Hatayı yeniden üretmek
  /// çoğu zaman ikincisini gerektirir ve kullanıcıya "ne yaptınız?" diye sormak güvenilir bir
  /// cevap vermez — kimse adımlarını hatırlamaz.
  ///
  /// YALNIZ olay ADLARI tutulur, boyutları değil: bağlam kısa kalmalı ve içine kişisel veri
  /// sızma ihtimali olan hiçbir alan girmemeli.
  static const int _kBreadcrumbLimit = 12;
  final List<String> _breadcrumbs = [];

  /// Son olay adları, eskiden yeniye.
  List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// Oturum açan/kapayan kullanıcıyı bildir. Sonraki olaylar bu kimlikle gider.
  ///
  /// Çıkışta `null` verilir: aynı cihazdaki ikinci kullanıcının olayları birincinin kimliğine
  /// YAZILMAZ.
  void setUser(String? userId) {
    _userId = userId;
    final ctx = _context;
    if (ctx != null) _context = ctx.withUser(userId);
  }

  /// Bağlamı hazırla (anonim kimlik + sürüm). Açılışta bir kez çağrılır; tekrarı zararsızdır.
  Future<void> ensureContext() async {
    if (_context != null) return;
    final version = await AppVersion.load();
    _context = AnalyticsContext(
      anonId: await _readOrCreateAnonId(),
      appVersion: version.label,
      userId: _userId,
    );
  }

  Future<String> _readOrCreateAnonId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_kAnonId);
      if (existing != null && existing.isNotEmpty) return existing;
      final fresh = _newId();
      await prefs.setString(_kAnonId, fresh);
      return fresh;
    } catch (_) {
      // Tercihler okunamıyorsa (widget testi) oturum ömürlü bir kimlik yeter.
      return _newId();
    }
  }

  String _newId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
  }

  /// Olayı kaydet. **Beklemek zorunlu değildir** — çağıran taraf `unawaited` bırakabilir.
  Future<void> log(AnalyticsEvent event) async {
    try {
      // İz kaydı bağlamı BEKLEMEDEN düşer: bir çökme, bağlam hazırlanmadan önce de olabilir ve
      // tam o çökmenin izi en değerlisidir.
      _breadcrumbs.add(event.name);
      if (_breadcrumbs.length > _kBreadcrumbLimit) _breadcrumbs.removeAt(0);

      await ensureContext();
      final ctx = _context;
      if (ctx == null) return;
      await _sink.add(
        AnalyticsRecord(
          id: _newId(),
          name: event.name,
          props: event.props,
          at: _now(),
          context: ctx,
        ),
      );
    } catch (_) {
      // Ölçüm kaybı kabul edilebilir; kullanıcıya yansıyan bir hata kabul edilemez.
    }
  }

  /// Olayı CİHAZ ÖMRÜNDE bir kez kaydet (`app_installed`, `first_exam` gibi).
  ///
  /// İşaret kalıcıdır: uygulama yeniden açıldığında olay TEKRAR gitmez. Kaldırıp yeniden kurmak
  /// işareti siler — bu doğrudur, çünkü o gerçekten yeni bir kurulumdur.
  ///
  /// Dönüş: olay şimdi mi gönderildi.
  Future<bool> logOnce(AnalyticsEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_kOncePrefix${event.name}';
      if (prefs.getBool(key) ?? false) return false;
      await prefs.setBool(key, true);
      await log(event);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Kuyruğu şimdi boşaltmayı dene (açılışta ve ağ geri geldiğinde).
  Future<void> flush() async {
    try {
      await _sink.flush();
    } catch (_) {}
  }
}

/// JSON kodlaması — kuyruk dosyası ve ağ gövdesi aynı biçimi kullanır.
String encodeRecords(List<AnalyticsRecord> records) =>
    jsonEncode(records.map((r) => r.toJson()).toList());

/// Bozuk kayıtlar SESSİZCE ATILIR: kuyruk dosyası eski bir sürümden kalmış olabilir ve tek bir
/// bozuk satır yüzünden bütün kuyruğu çöpe atmak (ya da çökmek) daha kötüdür.
List<AnalyticsRecord> decodeRecords(String raw) {
  try {
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    final out = <AnalyticsRecord>[];
    for (final item in list) {
      if (item is! Map) continue;
      final record = AnalyticsRecord.fromJson(item.cast<String, Object?>());
      if (record != null) out.add(record);
    }
    return out;
  } catch (_) {
    return const [];
  }
}

/// Uygulamanın analitik örneği.
///
/// Varsayılan sink BELLEK-İÇİDİR: widget testleri hiçbir kurulum yapmadan çalışır ve test sırasında
/// ağa çıkılmaz. `main()` bunu kalıcı kuyruklu gerçek sink ile ezer.
final analyticsProvider = Provider<Analytics>(
  (ref) => Analytics(sink: MemoryAnalyticsSink()),
);
