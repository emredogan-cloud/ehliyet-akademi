import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kampanya motoru (Faz 3).
///
/// ## Neden bir MOTOR, neden ekrana yazılmış metin değil
///
/// Ödeme ekranındaki "eski fiyat üstü çizili", "%50 indirim", "son 2 gün" gibi ögeler,
/// **arkalarında gerçek bir kampanya yoksa karanlık desendir**:
///
/// - hiç uygulanmamış bir "eski fiyat" göstermek yanıltıcı fiyatlandırmadır (Play politikası
///   ve 6502 sayılı Tüketicinin Korunması Hakkında Kanun kapsamında sorun),
/// - hiçbir şeyi kapatmayan bir geri sayım **sahte aciliyettir**; süre bitince fiyat aynı
///   kalıyorsa kullanıcı kandırılmıştır.
///
/// Bu yüzden kampanya bir **veri** nesnesidir ve kaynağı derleme zamanı yapılandırmasıdır.
/// **Varsayılan: HİÇ KAMPANYA YOK.** Yapılandırma verilmezse ekran yalnız mağazanın bildirdiği
/// gerçek fiyatı gösterir; üstü çizili fiyat, indirim rozeti ve sayaç **hiç çizilmez**.
///
/// ## Kaynak
///
/// ```bash
/// flutter build appbundle --release \
///   --dart-define=CAMPAIGNS_JSON='[{"id":"welcome-2026","kind":"firstExam",
///     "title":"İlk sınav kampanyası","explanation":"...","discountPercent":40,
///     "oldPriceLabel":"₺799,99","newPriceLabel":"₺479,99",
///     "startsAt":"2026-08-01T00:00:00Z","endsAt":"2026-08-15T21:00:00Z","enabled":true}]'
/// ```
///
/// Biçim bozuksa **çökme yok**: liste boş kabul edilir (kampanyasız hâl zaten geçerli bir hâl).
/// Bir pazarlama yapılandırma hatası, uygulamayı açılamaz hâle getirmemelidir.
///
/// İleride kampanyalar sunucudan gelecekse yalnız [CampaignSource] uygulaması eklenir; ekranlar
/// ve karar mantığı değişmez.
enum CampaignKind {
  /// İlk deneme sınavı sonrası sunulan teklif.
  firstExam,

  /// Süresi dolmuş / iptal edilmiş erişimi geri kazanma (Faz 5).
  winBack,

  /// Bağlamı olmayan genel kampanya (ödeme ekranı).
  general;

  static CampaignKind parse(String? raw) => switch (raw) {
    'firstExam' => CampaignKind.firstExam,
    'winBack' => CampaignKind.winBack,
    _ => CampaignKind.general,
  };
}

@immutable
class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.explanation,
    required this.kind,
    this.discountPercent = 0,
    this.oldPriceLabel,
    this.newPriceLabel,
    this.startsAt,
    this.endsAt,
    this.enabled = false,
  });

  /// Kararlı kimlik — analitikte kampanya başına dönüşüm ölçmek için.
  final String id;

  /// Kullanıcıya gösterilen başlık.
  final String title;

  /// **Kampanyanın açıklaması** — "neden bu fiyat, neden şimdi". Boş bırakılabilir; boşsa
  /// açıklama satırı çizilmez (uydurma gerekçe yazmaktansa hiç yazmamak doğrudur).
  final String explanation;

  final CampaignKind kind;

  /// 0–100. Sıfırsa indirim rozeti gösterilmez.
  final int discountPercent;

  /// Kampanya öncesi liste fiyatı — **mağazanın yerelleştirdiği biçimde** metin olarak.
  /// Uygulama fiyat aritmetiği YAPMAZ: para birimi, vergi ve yerelleştirme mağazanın işidir.
  final String? oldPriceLabel;

  /// Kampanyalı fiyat metni. Mağaza gerçek fiyatı bildirdiğinde ekran onu tercih eder;
  /// bu alan yalnız kampanya kartındaki karşılaştırma için durur.
  final String? newPriceLabel;

  final DateTime? startsAt;

  /// Bitiş anı. **Sayaç yalnız bu alan doluyken çizilir.**
  final DateTime? endsAt;

  /// Kapalıysa kampanya hiç yokmuş gibi davranılır.
  final bool enabled;

  /// Kampanya [now] anında yürürlükte mi?
  bool isActiveAt(DateTime now) {
    if (!enabled) return false;
    final s = startsAt;
    if (s != null && now.isBefore(s)) return false;
    final e = endsAt;
    if (e != null && !now.isBefore(e)) return false;
    return true;
  }

  /// Geri sayım çizilsin mi? Yürürlükte OLMAYAN ya da bitişi olmayan kampanyada **hayır**.
  bool hasCountdownAt(DateTime now) => isActiveAt(now) && endsAt != null;

  /// Kalan süre (yoksa sıfır).
  Duration remainingAt(DateTime now) {
    final e = endsAt;
    if (e == null || !e.isAfter(now)) return Duration.zero;
    return e.difference(now);
  }

  /// Üstü çizili fiyat çizilsin mi?
  bool hasListPriceAt(DateTime now) => isActiveAt(now) && (oldPriceLabel ?? '').trim().isNotEmpty;

  /// İndirim rozeti çizilsin mi?
  bool hasDiscountAt(DateTime now) => isActiveAt(now) && discountPercent > 0;

  /// Tek bir kampanyayı JSON'dan oku. Eksik/bozuk alanlar **güvenli** tarafa düşer.
  static Campaign? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = (raw['id'] as Object?)?.toString().trim() ?? '';
    final title = (raw['title'] as Object?)?.toString().trim() ?? '';
    // Kimliksiz ya da başlıksız bir kampanya kullanıcıya gösterilemez.
    if (id.isEmpty || title.isEmpty) return null;

    DateTime? date(Object? v) {
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s)?.toLocal();
    }

    final discount = (raw['discountPercent'] as num?)?.toInt() ?? 0;
    return Campaign(
      id: id,
      title: title,
      explanation: (raw['explanation'] as Object?)?.toString().trim() ?? '',
      kind: CampaignKind.parse((raw['kind'] as Object?)?.toString()),
      // Anlamsız yüzdeler sessizce kırpılır; %120 indirim diye bir şey yok.
      discountPercent: discount.clamp(0, 100),
      oldPriceLabel: (raw['oldPriceLabel'] as Object?)?.toString().trim(),
      newPriceLabel: (raw['newPriceLabel'] as Object?)?.toString().trim(),
      startsAt: date(raw['startsAt']),
      endsAt: date(raw['endsAt']),
      // AÇIKÇA true yazılmadıkça kampanya KAPALIDIR.
      enabled: raw['enabled'] == true,
    );
  }

  /// Bütün kataloğu oku. Bozuk giriş = boş katalog (çökme yok).
  static List<Campaign> parseCatalog(String json) {
    if (json.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded) ?tryParse(item),
      ];
    } catch (_) {
      return const [];
    }
  }
}

/// Kampanya kaynağı. Bugün tek uygulaması derleme zamanı yapılandırmasıdır; sunucu kaynağı
/// eklendiğinde ekranlar değişmeyecek.
abstract class CampaignSource {
  List<Campaign> catalog();
}

/// `--dart-define=CAMPAIGNS_JSON=[...]` kaynağı.
class EnvironmentCampaignSource implements CampaignSource {
  const EnvironmentCampaignSource();

  static const String _raw = String.fromEnvironment('CAMPAIGNS_JSON');

  @override
  List<Campaign> catalog() => Campaign.parseCatalog(_raw);
}

/// Belirli bir tür için [now] anında yürürlükte olan kampanyayı seç.
///
/// SIRA: önce türü tam eşleşen, sonra [CampaignKind.general]. Böylece "ilk sınav" teklifi için
/// özel bir kampanya tanımlanmadıysa genel kampanya devreye girer; hiçbiri yoksa `null` döner ve
/// arayüz kampanyasız (dürüst) hâline düşer.
Campaign? activeCampaign(List<Campaign> catalog, DateTime now, {CampaignKind? kind}) {
  final live = catalog.where((c) => c.isActiveAt(now)).toList();
  if (live.isEmpty) return null;
  if (kind != null) {
    for (final c in live) {
      if (c.kind == kind) return c;
    }
  }
  for (final c in live) {
    if (c.kind == CampaignKind.general) return c;
  }
  return kind == null ? live.first : null;
}

final campaignSourceProvider = Provider<CampaignSource>((ref) => const EnvironmentCampaignSource());

/// Katalog — kaynaktan bir kez okunur.
final campaignCatalogProvider = Provider<List<Campaign>>(
  (ref) => ref.watch(campaignSourceProvider).catalog(),
);
