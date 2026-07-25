import '../onboarding/study_profile.dart';
import 'lesson.dart';
import 'vehicle_part.dart';

/// Evolution Faz E4/E5 — seçilen ehliyet sınıfına göre içerik kapsamlama (saf, test edilebilir).
///
/// KURAL: içerik `licences` alanı BOŞSA her sınıf için geçerlidir (motor, sıvılar, lastik, acil
/// ekipman gibi ortak konular). Doluysa yalnız listelenen sınıflarda gösterilir.
///
/// NOT (bilinçli tasarım): e-Sınav teori soru bankası Türkiye'de sınıftan bağımsız ORTAKTIR.
/// Bu yüzden ilerleme/SRS verisi sınıfa göre BÖLÜNMEZ — sınıf değiştiren kullanıcı teori
/// ilerlemesini kaybetmez. Sınıfa özgü olan şey İÇERİK KAPSAMI ve önceliklendirmedir.
bool matchesLicence(List<String> licences, LicenceCategory category) =>
    licences.isEmpty || licences.contains(category.wire);

/// Bu sınıfa özgü mü (ortak içerik değil)?
bool isLicenceSpecific(List<String> licences) => licences.isNotEmpty;

extension LicenceScopedParts on List<VehiclePart> {
  /// Yalnız bu sınıfta geçerli parçalar.
  List<VehiclePart> forLicence(LicenceCategory category) =>
      where((p) => matchesLicence(p.licences, category)).toList();

  /// Sınıfa ÖZGÜ parçalar önce, ortak parçalar sonra — kaynak sırası korunur.
  /// (Kullanıcı önce kendi aracına ait olanı görür; ortak konular hemen ardından gelir.)
  List<VehiclePart> prioritizedFor(LicenceCategory category) {
    final scoped = forLicence(category);
    final specific = scoped.where((p) => isLicenceSpecific(p.licences)).toList();
    final shared = scoped.where((p) => !isLicenceSpecific(p.licences)).toList();
    return [...specific, ...shared];
  }
}

/// Faz E5 — dersler için aynı kapsamlama. Ortak teori dersleri etiketsizdir ve her sınıfta kalır.
extension LicenceScopedLessons on List<Lesson> {
  /// Yalnız bu sınıfta geçerli dersler (ortak + sınıfa özgü).
  List<Lesson> forLicence(LicenceCategory category) =>
      where((l) => matchesLicence(l.licences, category)).toList();

  /// Yalnız bu sınıfa ÖZGÜ dersler (ortak teori hariç) — "Sınıfına özel" bölümünü besler.
  List<Lesson> specificFor(LicenceCategory category) =>
      where((l) => isLicenceSpecific(l.licences) && matchesLicence(l.licences, category)).toList();

  /// Yalnız ortak (etiketsiz) dersler — her sınıfta aynı.
  List<Lesson> get shared => where((l) => !isLicenceSpecific(l.licences)).toList();
}

/// Sınıfa göre ÖNE ÇIKAN trafik işareti — `why` neden öne çıktığını anlatır.
///
/// ÖNEMLİ AYRIM: bu bir **ağırlıklandırmadır, filtre değildir.** e-Sınavda her sınıfa aynı işaret
/// sorulabilir, bu yüzden 121 işaretlik galeri hiçbir sınıfta kısılmaz. Yapılan şey, o sınıfın
/// sürüş gerçekliğinde daha çok işine yarayan işaretleri gerekçesiyle öne çıkarmaktır.
class SignFocus {
  const SignFocus(this.signId, this.why);

  /// İçerik anlık görüntüsündeki `TrafficSign.id`.
  final String signId;

  /// Bu işaretin bu sınıf için neden kritik olduğu (tek cümle).
  final String why;
}

const List<SignFocus> _motoFocus = [
  SignFocus('motosiklet-giremez', 'Doğrudan seni kısıtlayan levha: bu yola motosikletle girilemez.'),
  SignFocus('kaygan-yol', 'İki tekerlekte tutunma kaybı doğrudan düşme demektir; hızı önceden azalt.'),
  SignFocus('gizli-buzlanma', 'Gölgeli ve nemli kesimlerde buz görünmez; motosiklette telafi şansı yoktur.'),
  SignFocus('gevsek-malzeme', 'Mıcır, lastikle zemin arasında bilye gibi davranır; ani gaz ve fren verme.'),
  SignFocus('tramvay-hatti', 'Ray, ön tekerleği yakalayıp yönü çalabilir; raya olabildiğince dik açıyla yaklaş.'),
  SignFocus('hemzemin-gecit', 'Ray ve metal yüzeyler ıslakken çok kaygandır; dik ve sabit hızla geç.'),
  SignFocus('yandan-ruzgar', 'Yan rüzgâr motosikleti şeritten çıkarır; gidonu sıkma, hızı düşür.'),
  SignFocus('tehlikeli-viraj-sol', 'Virajın hızı içeride değil, girmeden önce ayarlanır.'),
  SignFocus('tehlikeli-viraj-sag', 'Yatış başladıktan sonra fren yapmak ön tekerleği kaydırır.'),
  SignFocus('devamli-viraj', 'Ard arda virajlarda yatış yönü sürekli değişir; hız payını baştan bırak.'),
  SignFocus('egimli-inis', 'Uzun inişte motor freni kullan; sürekli fren balatayı ısıtır.'),
  SignFocus('tumsek', 'Tümsek süspansiyonu boşaltır; üzerinden frenleyerek geçme.'),
  SignFocus('kasisli-yol', 'Kasis iki tekerlekte dengeyi bozar; hızı kasise girmeden azalt.'),
  SignFocus('dusen-kaya', 'Yola düşmüş tek bir taş bile motosiklet için devrilme sebebidir.'),
];

const List<SignFocus> _busFocus = [
  SignFocus('otobus-giremez', 'Doğrudan seni kısıtlayan levha: bu yola otobüsle girilemez.'),
  SignFocus('yukseklik-siniri', 'Otobüs yüksektir; bu değeri aracının gerçek yüksekliğiyle karşılaştır.'),
  SignFocus('agirlik-siniri', 'Dolu otobüsün ağırlığı sınırı aşabilir; yolcu ve bagajla birlikte değerlendir.'),
  SignFocus('aks-yuku-siniri', 'Toplam ağırlık uygun olsa bile aks başına düşen yük sınırı aşılabilir.'),
  SignFocus('genislik-siniri', 'Genişlik hesabına aynalar da dahildir.'),
  SignFocus('uzunluk-siniri', 'Otobüs ve mafsallı otobüsler bu sınırın doğrudan hedefidir.'),
  SignFocus('egimli-inis', 'Ağır araçta uzun iniş, fren ısınmasının bir numaralı sebebidir; retarder kullan.'),
  SignFocus('dik-cikis', 'Tırmanma vitesi yokuşa girmeden seçilir; yokuşta vites değiştirmek güç kaybettirir.'),
  SignFocus('yol-daralmasi', 'Uzun ve geniş araçta daralma manevra payını bitirir.'),
  SignFocus('sagdan-daralma', 'Sağdan daralmada arka tekerleğin izi kaldırıma yaklaşır.'),
  SignFocus('soldan-daralma', 'Soldan daralmada kuyruk taşması komşu şeride girebilir.'),
  SignFocus('dar-gecit-oncelik', 'Dar geçitte büyük araçla karşılaşmak geri manevra gerektirebilir.'),
  SignFocus('dar-gecit-onceligi-sende', 'Önceliğin olsa bile karşı araç uzunsa geçişi bekletmek daha güvenlidir.'),
  SignFocus('tunel', 'Tünelde yükseklik ve şerit değiştirme kısıtları büyük araç için kritiktir.'),
  SignFocus('takip-mesafesi', 'Ağır aracın duruş mesafesi çok daha uzundur; verilen mesafeyi artırarak uygula.'),
  SignFocus('zincir-mecburi', 'Ağır araçta zincir takmak uzun sürer; duracağın yeri levhayı görünce planla.'),
  SignFocus('otobus-duragi', 'Durakta duraklama ve kalkış kuralları senin günlük işindir.'),
];

/// Bu sınıf için öne çıkan işaretler. B sınıfı için liste BOŞTUR: mevcut işaret kütüphanesi zaten
/// B odaklı hazırlanmıştır, bu yüzden yapay bir "öne çıkan" kümesi üretmek yerine galeri olduğu
/// gibi bırakılır (dürüst kapsam — faz raporunda yazılıdır).
List<SignFocus> signFocusFor(LicenceCategory category) => switch (category) {
  LicenceCategory.a => _motoFocus,
  LicenceCategory.d => _busFocus,
  LicenceCategory.b => const [],
};
