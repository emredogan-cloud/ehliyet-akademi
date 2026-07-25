/// Evolution Faz E6 — onboarding içgörü kartları (saf, test edilebilir).
///
/// Her adımda AI Koç, o adıma BAĞLI kısa bir içgörü söyler. Kartlar dönerek değişir; hangi kartın
/// gösterileceği [insightAt] ile DETERMİNİSTİK olarak belirlenir (rastgelelik yok → test edilebilir
/// ve aynı adımda ardışık tekrar oluşmaz).
///
/// İÇERİK DİSİPLİNİ: buradaki her sayı uygulamanın kendi doğrulanmış verisinden gelir
/// (`EXAM_BLUEPRINT`: 50 soru · 45 dakika · 35 doğru barajı · 23/12/9/6 dağılımı). Kaynağı olmayan
/// istatistik ("kullanıcıların %X'i") YAZILMAZ.
library;

/// İçgörü türü — kartta rozet olarak görünür.
enum InsightKind {
  ipucu('İpucu'),
  bilgi('Bilgi'),
  motivasyon('Motivasyon'),
  surus('Sürüş'),
  sinav('Sınav'),
  strateji('Strateji');

  const InsightKind(this.label);
  final String label;
}

/// Tek bir içgörü kartı.
class OnboardingInsight {
  const OnboardingInsight(this.kind, this.text);
  final InsightKind kind;
  final String text;
}

/// Onboarding adım sayısı (0 karşılama … 5 AI Koç).
const int kOnboardingStepCount = 6;

const List<List<OnboardingInsight>> _byStep = [
  // 0 — Karşılama
  [
    OnboardingInsight(
      InsightKind.motivasyon,
      'Ehliyet sınavı ezber değil düzen işidir; her gün kısa çalışmak tek gecelik maratonu yener.',
    ),
    OnboardingInsight(
      InsightKind.bilgi,
      'e-Sınav 50 soru ve 45 dakikadır; geçmek için 35 doğru gerekir.',
    ),
    OnboardingInsight(
      InsightKind.ipucu,
      'Dersler ve sorular bir kez indirilir; sonrasında internetsiz de çalışabilirsin.',
    ),
    OnboardingInsight(
      InsightKind.strateji,
      'Kalıcı öğrenmenin yolu tekrar okumaktan değil, kendini test etmekten geçer.',
    ),
  ],
  // 1 — Ehliyet sınıfı
  [
    OnboardingInsight(
      InsightKind.bilgi,
      'Teori sınavı tüm sınıflarda ortaktır; değişen şey araç tekniği ve mevzuat farkıdır.',
    ),
    OnboardingInsight(
      InsightKind.ipucu,
      'Sınıfını sonradan Profil\'den değiştirebilirsin; teori ilerlemen korunur.',
    ),
    OnboardingInsight(
      InsightKind.strateji,
      'Sınıf seçmek içeriği daraltmaz; ortak teorinin üstüne sınıfına özel dersleri ekler.',
    ),
    OnboardingInsight(
      InsightKind.surus,
      'B otomobil, A motosiklet, D ise yolcu taşımacılığı otobüsleri içindir.',
    ),
  ],
  // 2 — Sınav deneyimi
  [
    OnboardingInsight(
      InsightKind.bilgi,
      'Dağılım sabittir: 23 trafik, 12 ilk yardım, 9 araç tekniği, 6 trafik adabı sorusu.',
    ),
    OnboardingInsight(
      InsightKind.strateji,
      'Daha önce girdiysen en değerli veri hatalarındır; onları konu konu ayır.',
    ),
    OnboardingInsight(
      InsightKind.motivasyon,
      'Bir kez kalmak başarısızlık değil ölçümdür; ölçtüğün şeyi düzeltebilirsin.',
    ),
    OnboardingInsight(
      InsightKind.ipucu,
      'İlk kez hazırlananlar işaretler ve geçiş önceliği konusuyla başlamalı.',
    ),
  ],
  // 3 — Sınav türü
  [
    OnboardingInsight(
      InsightKind.sinav,
      'e-Sınav bilgisayarda çoktan seçmeli; direksiyon ise gerçek trafikte uygulamalıdır.',
    ),
    OnboardingInsight(
      InsightKind.surus,
      'Direksiyonda ölçülen hız değil kontroldür: ayna, sinyal, mesafe ve şerit.',
    ),
    OnboardingInsight(
      InsightKind.strateji,
      'Teoriyi bilen sürücü direksiyonda rahattır; kural bilgisi kararı hızlandırır.',
    ),
    OnboardingInsight(
      InsightKind.ipucu,
      'İkisini birden seçersen konu anlatımı ve manevra videoları bir arada gelir.',
    ),
  ],
  // 4 — Kalan süre
  [
    OnboardingInsight(
      InsightKind.strateji,
      'Aralıklı tekrar işe yarar: 1., 3. ve 7. günde yeniden görülen konu kalıcı olur.',
    ),
    OnboardingInsight(
      InsightKind.ipucu,
      'Sınavın yakınsa denemeyle başla; hataların neye odaklanacağını söyler.',
    ),
    OnboardingInsight(
      InsightKind.bilgi,
      'Seçtiğin süre günlük soru hedefini ve ana sayfadaki çalışma planını belirler.',
    ),
    OnboardingInsight(
      InsightKind.motivasyon,
      'Az zaman dezavantaj değil odak sebebidir; plan panikten her zaman hızlıdır.',
    ),
  ],
  // 5 — AI Koç
  [
    OnboardingInsight(
      InsightKind.bilgi,
      'AI Koç yanıtlarını uygulamanın kendi ders ve soru içeriğine dayandırır.',
    ),
    OnboardingInsight(
      InsightKind.ipucu,
      'Bir soruyu neden yanlış yaptığını anlamadıysan koça sorabilirsin.',
    ),
    OnboardingInsight(
      InsightKind.strateji,
      'Koç zayıf konularını cevap geçmişinden çıkarır; çözdükçe isabeti artar.',
    ),
    OnboardingInsight(
      InsightKind.motivasyon,
      'Yalnız çalışmıyorsun: koç ilerlemeni izler ve sıradaki adımı söyler.',
    ),
  ],
];

/// Bu adımın içgörüleri. Tanımsız adım için karşılama seti döner (asla boş liste değil).
List<OnboardingInsight> insightsForStep(int step) =>
    (step >= 0 && step < _byStep.length) ? _byStep[step] : _byStep[0];

/// [tick]'inci dönüşte gösterilecek içgörü — deterministik ve döngüsel.
/// Her adımda en az 2 kart olduğu için ardışık iki dönüşte aynı kart GELMEZ (testle sabit).
OnboardingInsight insightAt(int step, int tick) {
  final list = insightsForStep(step);
  return list[tick % list.length];
}
