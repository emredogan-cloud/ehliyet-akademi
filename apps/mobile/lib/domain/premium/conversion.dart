import 'campaign.dart';

/// Faz 3 — ilk sınav sonrası dönüşüm akışının SAF karar katmanı.
///
/// Ekranlar burada karar vermez; yalnız uygular. Böylece "ne zaman gösterilir, koç ne der"
/// soruları platform kanalı açmadan test edilebilir.

/// Dönüşüm akışı bu sınavdan sonra çalışmalı mı?
///
/// KURAL: **yalnız hayattaki İLK tamamlanmış deneme sınavı.** İkinci sınavdan sonra bu akış bir
/// daha çalışmaz — "ilk sınav tebriği" ikinci kez gösterilirse tebrik olmaktan çıkıp reklama
/// dönüşür. Sonraki sınavlar mevcut (sık-gösterim sınırlı) bağlamsal teşvike bırakılır.
bool shouldRunFirstExamConversion({
  required int examsFinished,
  required bool premium,
  required bool alreadyShown,
}) {
  if (premium) return false; // sahip olana satış yapılmaz
  if (alreadyShown) return false; // bir kez
  return examsFinished == 1;
}

/// Koçun sınav sonucuna dair okuması — **gerçek sonuçtan türetilir**.
///
/// Burada "harikasın!" gibi sonuçtan bağımsız bir cümle YOKTUR. 50 soruda 12 doğru yapmış birine
/// "harikasın" demek, ürünün ölçtüğü şeye kendisinin inanmadığını gösterir. Üç bant var ve üçü de
/// aynı şeyi dürüstçe söyler: nerede olduğun + bir sonraki adım.
({String title, String body}) coachExamRead({
  required int correct,
  required int total,
  required int passMark,
}) {
  final safeTotal = total <= 0 ? 1 : total;
  final ratio = correct / safeTotal;
  final passed = correct >= passMark;

  if (passed) {
    return (
      title: 'Geçtin — ilk denemede!',
      body:
          '$safeTotal soruda $correct doğru. Geçme sınırı $passMark; onu ilk denemende aştın. '
          'Şimdiki iş bunu tesadüf olmaktan çıkarmak: zayıf kalan konuları kapatıp tekrarla.',
    );
  }
  if (ratio >= 0.5) {
    return (
      title: 'İyi bir başlangıç',
      body:
          '$safeTotal soruda $correct doğru. Geçmek için $passMark gerekiyor — aradaki fark '
          '${passMark - correct} soru. Bu, konu eksiği değil tekrar eksiğidir; kapanabilir.',
    );
  }
  return (
    title: 'Başlangıç noktan belli',
    body:
        '$safeTotal soruda $correct doğru. Geçme sınırı $passMark. Bu sonuç bir başarısızlık '
        'değil, ölçüm: nereden başlayacağını artık biliyorsun.',
  );
}

/// Koçun teklifi açarken kullandığı giriş cümlesi.
///
/// Ton talebi: "İlerlemeni inceledim. Premium'un sana gerçekten yardımcı olacağını düşünüyorum."
/// Cümlenin arkasında GERÇEK bir veri olmalı — bu yüzden doğru sayısı cümlenin içinde geçer.
String coachOfferIntro({required int correct, required int total, required int passMark}) {
  final safeTotal = total <= 0 ? 1 : total;
  final gap = passMark - correct;
  if (gap > 0) {
    return 'İlerlemeni inceledim: $safeTotal soruda $correct doğru, geçmek için $gap soru daha '
        'gerekiyor. Bu farkı en hızlı kapatan şey sınırsız deneme ve konu tekrarı — Premium\'un '
        'sana gerçekten yardımcı olacağını düşünüyorum.';
  }
  return 'İlerlemeni inceledim: $safeTotal soruda $correct doğru ile geçme sınırını aştın. '
      'Bunu kalıcı hâle getirmek için sınırsız deneme ve kişisel plan işe yarar — Premium\'un '
      'sana gerçekten yardımcı olacağını düşünüyorum.';
}

/// Ücretsiz ↔ Premium karşılaştırma satırı.
///
/// `free` alanı **dürüst** olmak zorunda: ücretsiz katmanda gerçekten ne var, o yazılır.
/// "Ücretsizde hiçbir şey yok" demek satışa yarayabilir ama yanlıştır ve ilk kullanımda çürür.
typedef ComparisonRow = ({String feature, String free, String premium, bool premiumOnly});

/// Karşılaştırma tablosu — tek kaynak. Hem teklif penceresi hem ödeme ekranı buradan okur.
const List<ComparisonRow> premiumComparison = [
  (feature: 'Deneme sınavı', free: 'Günde 1', premium: 'Sınırsız', premiumOnly: false),
  (feature: 'AI Koç soruları', free: 'Günde sınırlı', premium: 'Sınırsız', premiumOnly: false),
  (feature: 'Konu anlatımları', free: 'Temel dersler', premium: 'Tümü', premiumOnly: false),
  (feature: 'Video dersler', free: '—', premium: 'Tümü', premiumOnly: true),
  (feature: 'Kişisel çalışma planı', free: '—', premium: 'Var', premiumOnly: true),
];

/// Kampanya kartının gösterilip gösterilmeyeceği + kalan süre, tek yerden.
///
/// Kampanya YOKSA kart da sayaç da çizilmez. Bu, motorun varsayılanının "kampanya yok" olmasıyla
/// birlikte sahte aciliyeti yapısal olarak imkânsız kılar.
({bool showCard, bool showCountdown, Duration remaining}) campaignPresentation(
  Campaign? campaign,
  DateTime now,
) {
  if (campaign == null || !campaign.isActiveAt(now)) {
    return (showCard: false, showCountdown: false, remaining: Duration.zero);
  }
  return (
    showCard: true,
    showCountdown: campaign.hasCountdownAt(now),
    remaining: campaign.remainingAt(now),
  );
}
