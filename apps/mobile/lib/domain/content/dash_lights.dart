// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.
// Kaynak: apps/mobile/tool/extract_dash_icons.py (Evolution Faz E3).

import '../../core/dash_assets.dart';

/// İkaz ışığının GEREKTİRDİĞİ EYLEM düzeyi (ikonun rengiyle çoğu zaman örtüşür,
/// ama sınıflandırma öğretim amaçlıdır: ne yapmam gerekiyor?).
enum DashSeverity {
  /// Dur ve kontrol et — sürüşe devam motoru/güvenliği riske atar.
  kirmizi,

  /// Dikkat — en kısa sürede kontrol ettir, ama güvenle devam edebilirsin.
  sari,

  /// Bilgi — bir sistem açık/aktif, arıza değil.
  bilgi;

  String get label => switch (this) {
    DashSeverity.kirmizi => 'Dur ve kontrol et',
    DashSeverity.sari => 'Dikkat — kontrol ettir',
    DashSeverity.bilgi => 'Bilgi — sistem aktif',
  };
}

/// Gösterge panelindeki bir ikaz ışığı.
class DashLight {
  const DashLight(this.id, this.name, this.meaning, this.tip, this.severity);
  final String id;
  final String name;
  final String meaning;
  final String tip;
  final DashSeverity severity;

  /// İkon varlığı (üretilmiş katalogdan).
  String? get asset => dashAsset(id);
}

/// 60 ikaz ışığı — gösterge paneli sırasıyla.
const List<DashLight> kDashLights = [
  DashLight('fren-uyari', 'Fren Sistemi Uyarısı', 'El freni çekili veya fren hidroliği düşük ya da fren sisteminde arıza var.', 'Ünlem + daire = frenle ilgili; kırmızıysa güvenli yerde DUR.', DashSeverity.kirmizi),
  DashLight('aku-sarj', 'Akü / Şarj Uyarısı', 'Şarj sistemi aküyü beslemiyor; alternatör veya kayış arızası olabilir.', 'Akü resmi: motor çalışırken yanıyorsa şarj yok demektir.', DashSeverity.kirmizi),
  DashLight('yag-basinci', 'Yağ Basıncı Uyarısı', 'Motor yağ basıncı düştü; motor zarar görebilir.', 'Yağdanlık damlıyor = basınç yok; motoru HEMEN durdur.', DashSeverity.kirmizi),
  DashLight('motor-arizasi', 'Motor Arıza Lambası', 'Motor kontrol sisteminde arıza var; egzoz/yakıt sistemi etkilenmiş olabilir.', 'Motor silueti = "check engine"; yanıp sönüyorsa hız kesip servise git.', DashSeverity.sari),
  DashLight('kizdirma-bujisi', 'Kızdırma Bujisi (dizel)', 'Dizel motorda kızdırma bujileri ısınıyor; sönmeden marş yapılmaz.', 'Kıvrık teller = kızdırma; sönünce çalıştır.', DashSeverity.sari),
  DashLight('hararet', 'Motor Sıcaklığı Yüksek', 'Motor aşırı ısındı; soğutma sistemi yetersiz kalıyor.', 'Termometre dalgada = hararet; kenara çek, soğumadan kapağı AÇMA.', DashSeverity.kirmizi),
  DashLight('sogutma-suyu', 'Soğutma Suyu Düşük', 'Radyatör/genleşme kabındaki soğutma suyu seviyesi azaldı.', 'Kap + dalga = sıvı seviyesi; soğukken tamamla.', DashSeverity.kirmizi),
  DashLight('hava-yastigi', 'Hava Yastığı Uyarısı', 'SRS hava yastığı sisteminde arıza var; kazada açılmayabilir.', 'Oturan kişi + top = hava yastığı.', DashSeverity.kirmizi),
  DashLight('emniyet-kemeri', 'Emniyet Kemeri Uyarısı', 'Sürücü veya yolcunun kemeri takılı değil.', 'Kemer takılı figür = kemeri bağla.', DashSeverity.kirmizi),
  DashLight('kapi-acik', 'Kapı Açık Uyarısı', 'Bir kapı veya bagaj tam kapanmamış.', 'Kapıları açık araç kuşbakışı = kapı açık.', DashSeverity.kirmizi),
  DashLight('abs', 'ABS Uyarısı', 'Kilitlenmeyi önleyici fren sistemi devre dışı; frenler çalışır ama tekerlek kilitlenebilir.', 'Daire içinde ABS yazısı; fren gücü durur, ABS durur.', DashSeverity.sari),
  DashLight('cekis-kontrol', 'Çekiş Kontrolü (TCS)', 'Çekiş kontrol sistemi çalışıyor veya arızalı; zeminde patinaj var.', 'Kayan araç + izler = tutunma kaybı.', DashSeverity.sari),
  DashLight('esp', 'Elektronik Denge Kontrolü (ESP)', 'Denge kontrol sistemi devrede ya da arızalı.', 'Kayan araç = savrulma kontrolü; kapalıysa dikkatli sür.', DashSeverity.sari),
  DashLight('lastik-basinci', 'Lastik Basıncı (TPMS)', 'Bir veya birden fazla lastikte basınç düşük.', 'Ünlemli lastik kesiti = havası eksik.', DashSeverity.sari),
  DashLight('yakit-az', 'Yakıt Az', 'Depodaki yakıt rezerve düştü; kalan menzil sınırlıdır, ilk istasyonda doldur.', 'Pompa simgesi; ibrenin yanındaki ok depo kapağının yönünü gösterir.', DashSeverity.sari),
  DashLight('cam-suyu', 'Cam Suyu Az', 'Cam yıkama suyu deposu boşalmak üzere.', 'Cam + fışkıran su = yıkama suyu.', DashSeverity.sari),
  DashLight('fren-sistemi', 'Fren Sistemi (genel)', 'Fren sisteminde genel bir uyarı var; balata veya hidrolik kontrol edilir.', 'Sarı daire + ünlem = fren sistemi kontrolü.', DashSeverity.sari),
  DashLight('el-freni', 'El Freni Çekili', 'Park freni devrede; kalkmadan önce indir.', 'Daire içinde P = park freni.', DashSeverity.sari),
  DashLight('auto-hold', 'Otomatik Fren Tutma', 'Auto Hold devrede; durunca araç frende tutulur.', 'AUTO HOLD yazısı; gaz verince kendiliğinden bırakır.', DashSeverity.sari),
  DashLight('yokus-inis', 'Yokuş İniş Kontrolü', 'Dik inişte hızı sabit tutan sistem devrede.', 'Eğimde araç = iniş kontrolü.', DashSeverity.sari),
  DashLight('sol-sinyal', 'Sol Sinyal', 'Sol dönüş/şerit değişikliği sinyali yanıyor.', 'Yeşil ok yönü = sinyal yönü.', DashSeverity.bilgi),
  DashLight('sag-sinyal', 'Sağ Sinyal', 'Sağ dönüş/şerit değişikliği sinyali yanıyor.', 'Yeşil ok yönü = sinyal yönü.', DashSeverity.bilgi),
  DashLight('dortlu-flasor', 'Dörtlü Flaşör', 'Her iki sinyal birlikte yanıyor; arıza veya tehlike bildirimi.', 'Çift ok = dörtlü flaşör.', DashSeverity.bilgi),
  DashLight('on-sis-farlari', 'Ön Sis Farları', 'Ön sis farları açık; yalnız görüş 50 metrenin altındayken kullanılır.', 'Düz çizgili far + eğik çizgi = ön sis.', DashSeverity.bilgi),
  DashLight('arka-sis-farlari', 'Arka Sis Farları', 'Arka sis lambası açık; açık havada arkadakini kör eder.', 'Dalgalı çizgiyi kesen far = arka sis.', DashSeverity.bilgi),
  DashLight('uzun-far', 'Uzun Hüzmeli Far', 'Uzun far açık; karşıdan araç gelince kısa fara geç.', 'Düz ışınlar = uzun far (mavi).', DashSeverity.bilgi),
  DashLight('kisa-far', 'Kısa Hüzmeli Far', 'Kısa hüzmeli (yakın) far açık; yerleşim yeri içinde ve karşıdan araç gelirken kullanılır.', 'Aşağı eğik ışınlar = kısa far.', DashSeverity.bilgi),
  DashLight('gunduz-farlari', 'Gündüz Sürüş Farları', 'Gündüz sürüş lambaları yanıyor.', 'DRL: gündüz görünürlük ışığı.', DashSeverity.bilgi),
  DashLight('park-lambasi', 'Park Lambası', 'Park (konum) lambaları açık; aracın duruşta görünür olmasını sağlar, yol aydınlatmaz.', 'İki yana ışık = park lambası.', DashSeverity.bilgi),
  DashLight('hiz-sabitleyici', 'Hız Sabitleyici Aktif', 'Cruise control devrede; ayarlanan hız korunuyor.', 'Kadran + ok = sabit hız.', DashSeverity.bilgi),
  DashLight('adaptif-hiz', 'Adaptif Hız Sabitleyici', 'Öndeki araca göre mesafe koruyan hız sabitleyici devrede.', 'Araç + kadran = mesafeli sabit hız.', DashSeverity.bilgi),
  DashLight('serit-takip', 'Şerit Takip Uyarısı', 'Sinyal vermeden şeritten çıkıldı.', 'Şerit çizgileri arasında araç = şeritten sapma.', DashSeverity.sari),
  DashLight('kor-nokta', 'Kör Nokta Uyarısı', 'Yan veya arka kör noktada araç var; şerit değiştirme bu anda tehlikelidir.', 'Yandaki araç işareti = kör nokta.', DashSeverity.sari),
  DashLight('carpisma-uyarisi', 'Çarpışma Uyarısı', 'Öndeki araca çarpışma riski algılandı; hemen hızını kes ve mesafeyi aç.', 'Araç + patlama = çarpışma riski.', DashSeverity.kirmizi),
  DashLight('ileri-mesafe', 'Öne Mesafe Uyarısı', 'Öndeki araca takip mesafesi çok kısaldı.', 'Dalgalar + araç = mesafe algısı.', DashSeverity.sari),
  DashLight('arka-capraz', 'Arka Çapraz Trafik Uyarısı', 'Geri çıkarken yandan gelen araç var.', 'Arkadan çapraz dalga = geri manevra uyarısı.', DashSeverity.sari),
  DashLight('park-sensoru', 'Park Sensörü Uyarısı', 'Park sensörü yakında engel algıladı; sesli uyarı sıklaştıkça mesafe azalıyordur.', 'P + dalga = mesafe uyarısı.', DashSeverity.sari),
  DashLight('start-stop', 'Start/Stop Sistemi', 'Motor durakta otomatik susuyor; fren bırakılınca çalışır.', 'Daire içinde A = otomatik.', DashSeverity.bilgi),
  DashLight('start-stop-kapali', 'Start/Stop Kapalı', 'Otomatik durdurma devre dışı bırakıldı.', 'A + OFF = sistem kapalı.', DashSeverity.sari),
  DashLight('diferansiyel-kilidi', 'Diferansiyel Kilidi', 'Diferansiyel kilidi devrede; düşük tutuşta çekiş sağlar.', 'Aks + kilit = diferansiyel.', DashSeverity.sari),
  DashLight('guvenlik-alarmi', 'Güvenlik Alarmı', 'Alarm sistemi devrede veya tetiklendi.', 'Kilit + araç = güvenlik.', DashSeverity.kirmizi),
  DashLight('immobilizer', 'İmmobilizer Uyarısı', 'Anahtar tanınmadı; motor çalışmayabilir.', 'Anahtar simgesi = immobilizer.', DashSeverity.kirmizi),
  DashLight('hidrolik-direksiyon', 'Direksiyon Sistemi Uyarısı', 'Hidrolik/elektrikli direksiyon desteğinde arıza var; direksiyon ağırlaşır.', 'Direksiyon + ünlem = destek yok.', DashSeverity.kirmizi),
  DashLight('sanziman-sicakligi', 'Şanzıman Sıcaklığı', 'Şanzıman yağı aşırı ısındı; yük altında sürüşe devam edilirse şanzıman zarar görür.', 'Dişli + termometre = şanzıman sıcak.', DashSeverity.kirmizi),
  DashLight('sanziman-arizasi', 'Şanzıman Arızası', 'Otomatik şanzımanda arıza algılandı.', 'Dişli + ünlem = şanzıman arızası.', DashSeverity.kirmizi),
  DashLight('yag-seviyesi', 'Motor Yağ Seviyesi Düşük', 'Motor yağ seviyesi azaldı; basınç uyarısından farklıdır.', 'Yağdanlık + dalga = seviye düşük.', DashSeverity.kirmizi),
  DashLight('alternator', 'Alternatör Uyarısı', 'Alternatör üretim yapmıyor; akü boşalır.', 'Motor + artı/eksi = şarj üretimi.', DashSeverity.kirmizi),
  DashLight('aku-sicakligi', 'Akü Sıcaklığı', 'Akü sıcaklığı normalin dışında.', 'Akü + termometre.', DashSeverity.kirmizi),
  DashLight('dpf', 'Partikül Filtresi (DPF)', 'Dizel partikül filtresi doldu; rejenerasyon gerekir.', 'Kutu + noktalar = kurum filtresi.', DashSeverity.sari),
  DashLight('katalitik', 'Katalitik Konvertör Uyarısı', 'Katalitik konvertör aşırı ısındı veya arızalı.', 'Egzoz gövdesi + ısı.', DashSeverity.kirmizi),
  DashLight('kar-modu', 'Kar Modu', 'Kaygan zemin sürüş modu devrede.', 'Kar tanesi = kışlık mod.', DashSeverity.bilgi),
  DashLight('bilgi-mesaji', 'Bilgi Mesajı', 'Gösterge ekranında okunması gereken bir bilgi var.', 'Daire içinde i = bilgi.', DashSeverity.bilgi),
  DashLight('eko-mod', 'ECO Modu', 'Yakıt tasarrufu (ECO) modu devrede; gaz tepkisi ve klima gücü yumuşatılır.', 'Yaprak = ekonomik sürüş.', DashSeverity.bilgi),
  DashLight('spor-mod', 'SPOR Modu', 'Spor sürüş modu devrede; tepkiler sertleşir.', 'Gösterge panelinde SPORT yazısı belirir.', DashSeverity.bilgi),
  DashLight('serit-koruma', 'Şeritte Tutma Aktif', 'Şeritte tutma desteği direksiyona müdahale ediyor.', 'Direksiyon + ünlem yeşil = destek aktif.', DashSeverity.bilgi),
  DashLight('adaptif-far', 'Adaptif Far Sistemi', 'Farlar viraja/karşı araca göre hüzmeyi ayarlıyor.', 'Eğik ışın çizgileri = adaptif hüzme.', DashSeverity.bilgi),
  DashLight('far-seviye', 'Far Seviye Ayarı', 'Far yükseklik ayarı değiştirildi.', 'Far + yukarı/aşağı ok.', DashSeverity.bilgi),
  DashLight('romork-cekme', 'Römork Çekme Modu', 'Römork/karavan çekme modu devrede.', 'Römork silueti.', DashSeverity.bilgi),
  DashLight('servis-zamani', 'Periyodik Bakım Zamanı', 'Bakım aralığı doldu; servise gitme zamanı.', 'İngiliz anahtarı = bakım.', DashSeverity.sari),
  DashLight('hava-filtresi', 'Hava Filtresi Uyarısı', 'Hava filtresi tıkandı; performans ve yakıt tüketimi etkilenir.', 'Petek desen = filtre.', DashSeverity.sari),
];
