/// Faz 9 — ödeme ekranındaki KAMPANYA bilgisi.
///
/// ## Neden ayrı ve neden yapılandırmaya bağlı
///
/// Referans tasarım (`apps/assets/paywall.png`) iki güçlü satış ögesi taşıyor:
/// · üstü çizili bir eski fiyat (`₺799,99` → `₺479,99`),
/// · geri sayan bir "SINIRLI SÜRE" sayacı.
///
/// İkisi de, ARKASINDA GERÇEK BİR ŞEY YOKSA, karanlık desendir:
/// · hiç uygulanmamış bir "eski fiyat" göstermek yanıltıcı fiyatlandırmadır (Play politikası ve
///   6502 sayılı Tüketicinin Korunması Hakkında Kanun kapsamında sorun),
/// · hiçbir şeyi kapatmayan bir geri sayım sahte aciliyettir; süre bitince fiyat aynı kalıyorsa
///   kullanıcı kandırılmıştır.
///
/// Bu yüzden ikisi de **derleme zamanı yapılandırmasına** bağlandı ve VARSAYILAN OLARAK KAPALI:
///
///   --dart-define=PAYWALL_LIST_PRICE='₺799,99'
///   --dart-define=PAYWALL_OFFER_ENDS_AT=2026-08-15T21:00:00Z
///
/// Değer verilmezse ekran yalnız mağazanın bildirdiği gerçek fiyatı gösterir; üstü çizili fiyat ve
/// sayaç HİÇ ÇİZİLMEZ. Ürün sahibi gerçek bir kampanya başlattığında değerleri verir ve tasarım
/// referanstaki hâline kavuşur. Süre dolduğunda sayaç kendiliğinden kaybolur.
class PaywallOffer {
  const PaywallOffer({this.listPriceLabel, this.endsAt});

  /// Kampanya öncesi liste fiyatı (mağazanın yerelleştirdiği biçimde, ör. `₺799,99`).
  /// Boşsa üstü çizili fiyat gösterilmez.
  final String? listPriceLabel;

  /// Kampanyanın bitiş anı. Boşsa ya da geçmişteyse sayaç gösterilmez.
  final DateTime? endsAt;

  static const _listPrice = String.fromEnvironment('PAYWALL_LIST_PRICE');
  static const _endsAt = String.fromEnvironment('PAYWALL_OFFER_ENDS_AT');

  /// Derleme zamanı yapılandırmasından oku. Geçersiz tarih ÇÖKME üretmez; sayaç kapalı kalır.
  static PaywallOffer fromEnvironment() => PaywallOffer(
    listPriceLabel: _listPrice.isEmpty ? null : _listPrice,
    endsAt: _endsAt.isEmpty ? null : DateTime.tryParse(_endsAt),
  );

  /// Üstü çizili fiyat gösterilsin mi?
  bool get hasListPrice => (listPriceLabel ?? '').trim().isNotEmpty;

  /// [now] anında sayaç gösterilsin mi?
  bool isCountdownVisible(DateTime now) => endsAt != null && endsAt!.isAfter(now);

  /// Kalan süre (bitmişse sıfır).
  Duration remaining(DateTime now) {
    final end = endsAt;
    if (end == null || !end.isAfter(now)) return Duration.zero;
    return end.difference(now);
  }
}

/// Geri sayımın saat/dakika/saniye parçaları — iki haneli, taşmasız.
///
/// Bir günden uzun kampanyalarda saat 24'ü aşar (ör. `72:00:00`); tasarımdaki üç kutu bozulmasın
/// diye gün ayrı bir birime ÇEVRİLMEZ, saate eklenir.
({String hours, String minutes, String seconds}) countdownParts(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final total = d.isNegative ? Duration.zero : d;
  return (
    hours: two(total.inHours),
    minutes: two(total.inMinutes.remainder(60)),
    seconds: two(total.inSeconds.remainder(60)),
  );
}
