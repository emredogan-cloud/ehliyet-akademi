import 'campaign.dart';

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
  ///
  /// ESKİ YOL — Faz 3'te gelen [Campaign] motorundan ÖNCEKİ iki `--dart-define`. Kaldırılmadı
  /// çünkü bu değerlerle derlenmiş bir yapı hâlâ sahada olabilir; kampanya motoru bir şey
  /// söylemezse bu yol yedek olarak durur ([fromCampaign] içindeki geri düşüş).
  static PaywallOffer fromEnvironment() => PaywallOffer(
    listPriceLabel: _listPrice.isEmpty ? null : _listPrice,
    endsAt: _endsAt.isEmpty ? null : DateTime.tryParse(_endsAt),
  );

  /// Faz 3 — teklif artık **kampanya motorundan** türetilir.
  ///
  /// Ödeme ekranının çizim mantığı (`PaywallPriceBlock`) değişmedi: hâlâ "üstü çizili fiyat var
  /// mı" ve "sayaç görünür mü" diye sorar. Değişen, cevabın NEREDEN geldiğidir — artık tek bir
  /// veri kaynağı (`Campaign`) var ve o kaynak varsayılan olarak boştur.
  ///
  /// [campaign] yoksa eski `--dart-define` yoluna düşülür; o da boşsa **kampanyasız** hâl kalır
  /// ve ekran yalnız mağazanın gerçek fiyatını gösterir.
  static PaywallOffer fromCampaign(Campaign? campaign, DateTime now) {
    if (campaign == null || !campaign.isActiveAt(now)) return fromEnvironment();
    return PaywallOffer(
      listPriceLabel: campaign.hasListPriceAt(now) ? campaign.oldPriceLabel : null,
      // Sayaç YALNIZ bitişi olan kampanyada; bitişi yoksa `endsAt` null kalır ve çizilmez.
      endsAt: campaign.hasCountdownAt(now) ? campaign.endsAt : null,
    );
  }

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
