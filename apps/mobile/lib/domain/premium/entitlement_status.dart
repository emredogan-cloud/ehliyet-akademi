/// Beta Faz 3 — abonelik/satın alma yaşam döngüsünün SAF kural katmanı.
///
/// MİMARİ: bu dosya hiçbir ödeme eklentisine bağlı DEĞİLDİR. `purchases_flutter`'ın
/// `EntitlementInfo` alanları burada sade `bool`/`String?` girdilere indirgenir; kural
/// doğrudan test edilir (proje disiplini: "saf kural katmanı ekrandan/uçtan ayrı").
///
/// Kaynak: `REVENUECAT_SETUP.md` §5 — "Yaşam döngüsü davranışları".
library;

/// Kullanıcının premium erişiminin YAŞAM DÖNGÜSÜ durumu.
///
/// Erişimin **açık** olup olmadığı [PremiumLifecycle.grantsAccess] ile sorulur; durum yalnız
/// kullanıcıya ne söyleneceğini belirler.
enum PremiumLifecycle {
  /// Yetki yok — hiç satın alınmamış ya da tamamen sona ermiş.
  none,

  /// Ömür boyu (tek seferlik) ürün. İptal/ödemesiz dönem/hesap beklemesi YOKTUR.
  lifetime,

  /// Abonelik etkin ve yenilenecek.
  active,

  /// Kullanıcı iptal etti; dönem sonuna kadar erişim **sürer**.
  cancelled,

  /// Ödeme başarısız; Play 3–30 gün tanıyor, erişim **sürer**. Kullanıcı ödeme yöntemini
  /// güncellemeli.
  gracePeriod,

  /// Ödemesiz dönem bitti, hâlâ ödenmedi → erişim **durdu**.
  accountHold;

  /// Bu durumda premium yüzeyleri açılır mı?
  bool get grantsAccess => switch (this) {
    PremiumLifecycle.none || PremiumLifecycle.accountHold => false,
    PremiumLifecycle.lifetime ||
    PremiumLifecycle.active ||
    PremiumLifecycle.cancelled ||
    PremiumLifecycle.gracePeriod => true,
  };

  /// Kullanıcının bir şey yapması gerekiyor mu? (Ödeme yöntemi / yenileme)
  bool get needsUserAction =>
      this == PremiumLifecycle.gracePeriod || this == PremiumLifecycle.accountHold;
}

/// Bir yetkinin (entitlement) ham gerçekleri — ödeme sağlayıcısından bağımsız biçim.
class EntitlementFacts {
  const EntitlementFacts({
    required this.identifier,
    required this.isActive,
    this.willRenew = false,
    this.expiresAt,
    this.billingIssueDetectedAt,
    this.unsubscribeDetectedAt,
  });

  /// Yetki kimliği (ör. `premium`).
  final String identifier;

  /// Sağlayıcı bu yetkiyi şu an etkin sayıyor mu.
  final bool isActive;

  /// Dönem sonunda otomatik yenilenecek mi.
  final bool willRenew;

  /// Bitiş tarihi. **null → süresiz** (ömür boyu / tek seferlik ürün).
  final String? expiresAt;

  /// Ödeme sorunu ilk ne zaman görüldü (ödemesiz dönem göstergesi).
  final String? billingIssueDetectedAt;

  /// İptal ne zaman algılandı.
  final String? unsubscribeDetectedAt;
}

/// Ham gerçeklerden yaşam döngüsü durumunu türet.
///
/// SIRA ÖNEMLİDİR: ödeme sorunu, iptalden önce değerlendirilir — ikisi aynı anda doğru olabilir
/// ve kullanıcıya gösterilecek en acil mesaj ödeme sorunudur.
PremiumLifecycle premiumLifecycleOf(EntitlementFacts? facts) {
  if (facts == null) return PremiumLifecycle.none;

  // Süresiz yetki = ömür boyu ürün. Play'de iptal/grace/hold kavramları uygulanmaz.
  final lifetime = facts.expiresAt == null;

  if (!facts.isActive) {
    // Süresiz bir yetki "etkin değil" olamaz; olursa yetki yoktur.
    if (lifetime) return PremiumLifecycle.none;
    // Ödeme sorunu görülmüş ve erişim durmuşsa bu hesap beklemesidir.
    return facts.billingIssueDetectedAt != null
        ? PremiumLifecycle.accountHold
        : PremiumLifecycle.none;
  }

  if (lifetime) return PremiumLifecycle.lifetime;
  if (facts.billingIssueDetectedAt != null) return PremiumLifecycle.gracePeriod;
  if (facts.unsubscribeDetectedAt != null || !facts.willRenew) {
    return PremiumLifecycle.cancelled;
  }
  return PremiumLifecycle.active;
}

/// Birden çok yetki arasından uygulamanın umursadığını seç ve durumunu türet.
PremiumLifecycle premiumLifecycleFor(
  Iterable<EntitlementFacts> all,
  String wantedIdentifier,
) {
  for (final f in all) {
    if (f.identifier == wantedIdentifier) return premiumLifecycleOf(f);
  }
  return PremiumLifecycle.none;
}

/// Kullanıcıya gösterilecek dürüst mesaj. Erişim sürüyorsa **korkutmaz**; durduysa **net söyler**.
///
/// `null` → gösterilecek bir şey yok (olağan durum).
String? premiumLifecycleMessage(PremiumLifecycle s) => switch (s) {
  PremiumLifecycle.none || PremiumLifecycle.lifetime || PremiumLifecycle.active => null,
  PremiumLifecycle.cancelled =>
    'Aboneliğin iptal edildi. Erişimin, ödediğin dönemin sonuna kadar sürüyor.',
  PremiumLifecycle.gracePeriod =>
    'Son ödeme alınamadı. Erişimin şimdilik açık — Google Play\'den ödeme yöntemini güncelle.',
  PremiumLifecycle.accountHold =>
    'Ödeme alınamadığı için premium erişimin durdu. Google Play\'den aboneliğini yenileyebilirsin.',
};
