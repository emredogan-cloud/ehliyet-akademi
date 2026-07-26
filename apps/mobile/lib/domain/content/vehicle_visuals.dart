import '../../core/mech_assets.dart';

/// Evolution Faz E2 — mekanik görsel kütüphanesinin öğrenme içeriğine bağlanması.
///
/// `core/mech_assets.dart` ÜRETİLMİŞ bir varlık kataloğudur (id → dosya). Bu dosya ise
/// varlıkları içerikle eşler: hangi araç bileşeni hangi fotoğrafla gösterilir ve kabin
/// kumandaları galerisinde ne anlatılır. İçerik kararı olduğu için elle yazılır.

/// Araç bileşeni (content/vehicle.ts `id`) → mekanik varlık kimliği.
/// Yalnız gerçekten AYNI parçayı gösteren eşleşmeler; zorlama benzetme yapılmaz.
const Map<String, String> kVehiclePartAsset = {
  // Motor bölmesi
  'engine-bay': 'engine-block',
  'battery': 'battery-12v',
  'dipstick': 'dipstick-oil',
  'coolant': 'coolant-tank',
  'brake-fluid': 'brake-fluid-reservoir',
  'washer': 'washer-cap',
  'fuse-box': 'fuse-box',
  'air-filter': 'air-filter-box',
  'oil-cap': 'oil-filler-cap',
  // Kabin & kumandalar
  'climate-controls': 'climate-temp-knob',
  'lights': 'headlight-knob-auto',
  'wiper-controls': 'wiper-stalk-speed',
  'mirror-adjust': 'mirror-adjust-knob',
  'mirrors': 'mirror-fold-switch',
  'seat-controls': 'seat-adjust-switch',
  'dashboard-buttons': 'park-sensor-button',
  'car-key': 'engine-start-stop',
  // Dış & lastikler
  'spare-wheel': 'spare-wheel',
  'tyre': 'spare-wheel',
  'park-sensor': 'park-sensor-button',
  'fog-lights': 'headlight-knob-fog',
  'fuel-cap': 'fuel-flap-button',
  // Muayene & acil durum
  'jack': 'scissor-jack',
  'wrench': 'wheel-wrench',
  'wheel-chock': 'wheel-chock',
  'fire-extinguisher': 'fire-extinguisher',
  'warning-triangle-road': 'warning-triangle',
  'emergency-kit': 'first-aid-kit',
  'tow-rope': 'tow-eye',
};

/// Bir araç bileşeninin fotoğrafı (varsa).
///
/// Faz E4'te eklenen A/D parçalarının `id`'si mekanik varlık kimliğiyle AYNIDIR
/// (`moto-chain`, `bus-tachograph`…), bu yüzden ayrı bir tablo gerekmez: önce elle kurulan
/// eşleme, sonra doğrudan kimlik denenir.
String? vehiclePartAsset(String partId) => mechAsset(kVehiclePartAsset[partId] ?? partId);

/// Kabin kumandası kartı — gerçek düğme fotoğrafı + ne işe yaradığı.
class CabinControl {
  const CabinControl(
    this.asset,
    this.title,
    this.desc,
    this.group, {
    required this.tip,
    required this.steps,
    this.mistake,
  });
  final String asset;
  final String title;
  final String desc;
  final String group;

  /// Beta Faz 10 — detay sayfasinin ipucu karti. Listede DEGIL, detayda gosterilir.
  final String tip;

  /// "Nasil kullanilir" ogrenme karti — sirali, kisa adimlar.
  ///
  /// Bos birakilamaz: icerik testi her kumandada en az iki adim arar. Detay sayfasi, mekanik
  /// kutuphanesiyle **ayni kalitede** olacaksa gorsel tek basina yetmez.
  final List<String> steps;

  /// Sik yapilan hata — yalniz GERCEKTEN bir hata varsa doldurulur.
  ///
  /// Her kumandaya zorla bir "hata" uydurmak uyariyi degersizlestirir; bu yuzden istege baglidir.
  final String? mistake;
}

/// Kabin Kumandaları galerisi — B sınıfı araç içi düğme/kol/soket kütüphanesi.
/// Sıra, kaynak sayfadaki mantıksal gruplama ile aynı.
const List<CabinControl> kCabinControls = [
  // — Kollar ve far kumandaları —
  CabinControl('wiper-stalk-int', 'Silecek Kolu (fasılalı)', 'INT konumu fasılalı silme; aşağı iterek tek sefer silinir.', 'Kollar & Farlar',
    tip:
        'Çiseleyen yağmurda fasılalı kademe camı çizmeden temiz tutar; kuru camda silecek çalıştırmak lastiği zımpara gibi aşındırır.',
    steps: [
      'Kolu bir kademe iterek INT (fasılalı) konumuna getir.',
      'Tek sefer silmek için kolu aşağı bastırıp bırak.',
      'Yağış artınca LO, şiddetlenince HI kademesine geç.',
    ],
    mistake:
        'Kuru cama silecek çalıştırmak: lastik camı çizer ve görüşü kalıcı olarak bozar.',
  ),
  CabinControl('wiper-stalk-speed', 'Silecek Kolu (hız kademeli)', 'MIST–OFF–INT–LO–HI kademeleri; yağış şiddetine göre seçilir.', 'Kollar & Farlar',
    tip:
        'MIST konumu yaylıdır: bırakınca kendi kapanır ve tek süpürme yapar; serpintide en pratik kademedir.',
    steps: [
      'Yağış şiddetine göre INT, LO veya HI kademesini seç.',
      'Kısa serpinti için kolu MIST yönüne itip bırak.',
      'Araç dururken sileceği OFF konumuna al.',
    ],
    mistake:
        'Sileceği açık unutup kontağı kapatmak: donmuş lastikle çalışan silecek motoru zorlanır.',
  ),
  CabinControl('wiper-stalk-rear', 'Arka Silecek Kolu', 'Arka cam sileceği ve yıkama suyunu çalıştırır.', 'Kollar & Farlar',
    tip:
        'Arka silecek geri manevrada görüşü açar; park sensörü görüşün yerini tutmaz.',
    steps: [
      'Kolun ucundaki halkayı arka silecek konumuna çevir.',
      'Yıkama suyu için halkayı ileri doğru it.',
      'Çoğu araçta geri vitese takınca kendiliğinden çalışır.',
    ],
  ),
  CabinControl('headlight-knob-auto', 'Far Düğmesi (AUTO)', '0–AUTO konumları; AUTO\'da farlar ışık sensörüyle otomatik yanar.', 'Kollar & Farlar',
    tip:
        'AUTO konumunda tünel girişinde farlar kendiliğinden yanar; ama sis ve yoğun yağışta elle kısa hüzmeye almak gerekir.',
    steps: [
      'Düğmeyi AUTO konumuna çevir.',
      'Sensör karanlığı algılayınca farlar otomatik yanar.',
      'Sis veya yoğun yağışta elle kısa hüzme konumuna al.',
    ],
    mistake:
        'AUTO\'ya güvenip gündüz sisinde farsız kalmak: ışık sensörü sisi karanlık saymaz.',
  ),
  CabinControl('headlight-knob-manual', 'Far Düğmesi (manuel)', 'Park lambası ve kısa hüzme konumları elle seçilir.', 'Kollar & Farlar',
    tip:
        'Şehir içinde kısa hüzme (yakın far) esastır; uzun hüzme karşıdan gelen sürücüyü kör eder.',
    steps: [
      'Park lambası için düğmeyi birinci kademeye çevir.',
      'Kısa hüzme için ikinci kademeye getir.',
      'Karşıdan araç gelmiyorsa kolu iterek uzun hüzmeye geç.',
    ],
    mistake:
        'Gece yalnız park lambasıyla sürmek: araç görünür ama yol aydınlanmaz.',
  ),
  CabinControl('headlight-knob-fog', 'Sis Farı Düğmesi', 'Ön/arka sis farları; yalnız görüş 50 m altındayken kullanılır.', 'Kollar & Farlar',
    tip:
        'Sis farı yalnız görüş 50 metrenin altındayken kullanılır; açık havada arkadakini kör eder.',
    steps: [
      'Önce far düğmesini kısa hüzme konumuna al.',
      'Sis halkasını ön (veya arka) sis konumuna çevir.',
      'Görüş açılır açılmaz sis farını kapat.',
    ],
    mistake:
        'Açık havada arka sis lambasını açık bırakmak: arkadaki sürücüyü kör eder.',
  ),
  CabinControl('hazard-button-round', 'Dörtlü Flaşör (yuvarlak)', 'Arıza, kaza veya zorunlu duruşta tüm sinyalleri birlikte yakar.', 'Kollar & Farlar',
    tip:
        'Dörtlü flaşör “park ediyorum” demek değildir; arıza, kaza ve zorunlu duruşu bildirir.',
    steps: [
      'Kırmızı üçgenli düğmeye bas.',
      'Tüm sinyaller birlikte yanıp sönmeye başlar.',
      'Tehlike geçince aynı düğmeyle kapat.',
    ],
    mistake:
        'Yasak yere park edip flaşör yakmak: duruşu yasal hâle getirmez.',
  ),
  CabinControl('hazard-button-rocker', 'Dörtlü Flaşör (basmalı)', 'Aynı işlev; konsol tipi basmalı düğme.', 'Kollar & Farlar',
    tip:
        'Düğmenin konumu işlevi değiştirmez; her araçta üçgen sembolü aynı anlama gelir.',
    steps: [
      'Konsoldaki üçgenli basmalı düğmeye bas.',
      'Gösterge panelinde iki sinyal oku birlikte yanar.',
      'Tehlike geçince aynı düğmeye basarak kapat.',
    ],
  ),
  // — Klima —
  CabinControl('climate-temp-knob', 'Sıcaklık Ayarı', 'Mavi–kırmızı skala kabin sıcaklığını belirler.', 'Klima',
    tip:
        'Camda buğu varken sıcaklığı yükseltmek buğuyu çözer; soğuk hava nemi cam yüzeyinde yoğunlaştırır.',
    steps: [
      'Düğmeyi maviye çevirerek soğut, kırmızıya çevirerek ısıt.',
      'Buğu çözmek için sıcaklığı yükselt ve A/C\'yi aç.',
      'Kabin dengelenince orta konuma al.',
    ],
  ),
  CabinControl('climate-fan-knob', 'Fan Kademesi', '0–4 arası üfleme gücü; buğu çözmede yüksek kademe kullanılır.', 'Klima',
    tip:
        'Buğu çözerken fanı yüksek kademeye almak, yalnız sıcaklığı artırmaktan çok daha hızlı sonuç verir.',
    steps: [
      'Fanı 0 konumundan istediğin kademeye çevir.',
      'Buğu çözmede en yüksek kademeyi seç.',
      'Kabin dengelenince kademeyi düşür.',
    ],
  ),
  CabinControl('climate-flow-knob', 'Hava Yönü', 'Havanın yüze, ayağa veya cama yönlendirilmesini seçer.', 'Klima',
    tip:
        'Havayı doğrudan yüze vermek uzun yolda yorar; cam ve ayak karışımı daha dengeli bir kabin sağlar.',
    steps: [
      'Sembollerden yüz, ayak veya cam yönünü seç.',
      'Buğuda cam sembolünü seç.',
      'Karışık konumda hava iki yöne birden gider.',
    ],
  ),
  CabinControl('climate-recirc-knob', 'İç Hava Sirkülasyonu', 'Dış havayı keser; tünelde/kokuda kullanılır, uzun süre açık bırakılmaz.', 'Klima',
    tip:
        'Tünelde ve egzoz kokusunda sirkülasyonu aç; uzun süre açık kalırsa kabinde nem birikir ve cam içten buğulanır.',
    steps: [
      'Kapalı döngü sembollü düğmeye bas.',
      'Koku veya tünel geçince dış hava konumuna dön.',
      'Cam buğulanmaya başlarsa hemen dış havaya al.',
    ],
    mistake:
        'Sirkülasyonu sürekli açık bırakmak: nem birikir, cam içten buğulanır.',
  ),
  CabinControl('climate-maxac-knob', 'MAX A/C', 'Klimayı en yüksek soğutmada çalıştırır.', 'Klima',
    tip:
        'MAX A/C sirkülasyonu da açar; kabin soğuduktan sonra normal konuma dönmek yakıt tüketimini düşürür.',
    steps: [
      'Düğmeyi MAX A/C konumuna çevir.',
      'Kabin soğuyana kadar bekle.',
      'Sonra normal soğutma konumuna dön.',
    ],
  ),
  CabinControl('rear-defrost-knob', 'Arka Cam Rezistansı', 'Arka camdaki teller buğu ve buzu çözer.', 'Klima',
    tip:
        'Rezistans telleri camın yüzeyindedir; arka camı içeriden sert bezle ovmak telleri koparır.',
    steps: [
      'Arka cam rezistans düğmesini aç.',
      'Teller ısınınca buz ve buğu çözülür.',
      'Sistem belli süre sonra kendini kapatır.',
    ],
    mistake:
        'Arka camı içeriden kazımak veya sert fırçalamak: rezistans telleri kopar ve bir daha ısıtmaz.',
  ),
  CabinControl('ac-button', 'Klima (A/C)', 'Kompresörü devreye alır; nemi alarak buğuyu da hızlı çözer.', 'Klima',
    tip:
        'A/C yalnız soğutmaz, havanın nemini de alır; bu yüzden kışın ısıtmayla birlikte buğu çözmede kullanılır.',
    steps: [
      'A/C düğmesine bas; gösterge ışığı yanar.',
      'Sıcaklık ve fanı ihtiyaca göre ayarla.',
      'Gerek kalmayınca A/C düğmesiyle kapat.',
    ],
  ),
  CabinControl('maxac-button', 'MAX A/C Düğmesi', 'Sirkülasyon + tam soğutmayı tek dokunuşla açar.', 'Klima',
    tip:
        'Tek dokunuşla sirkülasyon ve tam soğutma birlikte açılır; bu yüzden uzun süre açık kalırsa cam buğulanabilir.',
    steps: [
      'Konsoldaki MAX A/C düğmesine bas.',
      'Kabin soğuyunca normal A/C\'ye dön.',
      'Buğu görürsen dış hava konumuna geç.',
    ],
  ),
  CabinControl('front-defrost-button', 'Ön Cam Buğu Çözücü', 'Havayı ön cama yönlendirir; buğuyu en hızlı bu ayar çözer.', 'Klima',
    tip:
        'Ön cam buğu çözücü A/C ile birlikte çalıştığında buğuyu en hızlı bu şekilde kaldırır.',
    steps: [
      'Ön cam sembollü düğmeye bas.',
      'Hava otomatik olarak ön cama yönlenir.',
      'Cam açılınca normal hava yönüne dön.',
    ],
    mistake:
        'Buğulu camla harekete geçmek: görüş kapalıyken sürmek hem tehlikeli hem kusurdur.',
  ),
  CabinControl('rear-defrost-button', 'Arka Cam Buğu Çözücü', 'Arka cam rezistansını açar; belli süre sonra kendi kapanır.', 'Klima',
    tip:
        'Sistem belli bir süre sonra kendi kapanır; gerekiyorsa yeniden basmak gerekir.',
    steps: [
      'Arka cam sembollü düğmeye bas.',
      'Gösterge ışığı yanınca rezistans çalışıyordur.',
      'İş bitince elle kapat ya da otomatik kapanmasını bekle.',
    ],
  ),
  // — Sürüş yardımcıları —
  CabinControl('park-sensor-button', 'Park Sensörü', 'Manevrada mesafe uyarısını açar/kapatır.', 'Sürüş Yardımcıları',
    tip:
        'Sensör alçak bordürü ve ince direği her zaman görmez; aynalar ve dönüp bakmak esastır.',
    steps: [
      'Manevradan önce düğmeye basarak sistemi aç.',
      'Uyarı sesi sıklaştıkça mesafe azalıyordur.',
      'Manevra bitince sistemi kapatabilirsin.',
    ],
    mistake:
        'Yalnız sensöre güvenmek: alçak engel ve yaya sensörün kör noktasında kalabilir.',
  ),
  CabinControl('start-stop-off-button', 'Start/Stop Kapatma', 'Motorun durakta otomatik susmasını devre dışı bırakır.', 'Sürüş Yardımcıları',
    tip:
        'Start/Stop yakıt tasarrufu içindir; trafiğin sık durup kalktığı yerde kapatmak sürüşü rahatlatır.',
    steps: [
      'A sembollü düğmeye basarak sistemi kapat.',
      'Gösterge ışığı sistemin kapalı olduğunu bildirir.',
      'Kontak kapanıp açılınca sistem yeniden devreye girer.',
    ],
  ),
  CabinControl('esp-off-button', 'ESP / Çekiş Kapatma', 'Kayma önleyiciyi kapatır; normal sürüşte AÇIK kalmalıdır.', 'Sürüş Yardımcıları',
    tip:
        'ESP savrulmayı önler ve normal sürüşte KAPATILMAZ; yalnız çamur veya karda tekerleğin dönmesi gerektiğinde geçici kapatılır.',
    steps: [
      'Yalnız gerektiğinde düğmeye basarak kapat.',
      'Gösterge panelinde uyarı ışığı yanar.',
      'Zemin normale döner dönmez tekrar aç.',
    ],
    mistake:
        'ESP kapalıyken normal yolda sürmek: kaygan zeminde savrulma riski belirgin biçimde artar.',
  ),
  CabinControl('rear-fog-slider', 'Arka Sis Lambası', 'Yalnız yoğun sis/kar/yağmurda; açık havada arkadakini kör eder.', 'Sürüş Yardımcıları',
    tip:
        'Arka sis lambası çok parlaktır; yalnız görüş 50 metrenin altındayken kullanılır.',
    steps: [
      'Farlar açıkken sürgüyü arka sis konumuna getir.',
      'Gösterge panelinde turuncu sis sembolü yanar.',
      'Görüş açılınca hemen kapat.',
    ],
    mistake:
        'Açık havada açık bırakmak: arkadaki sürücüyü kör eder.',
  ),
  CabinControl('engine-start-stop', 'Marş Düğmesi', 'Anahtarsız çalıştırma; fren basılıyken motoru çalıştırır.', 'Sürüş Yardımcıları',
    tip:
        'Anahtar cepte olsa bile fren pedalına basılmadan motor çalışmaz; bu bir arıza değil, güvenlik şartıdır.',
    steps: [
      'Fren pedalına sonuna kadar bas ve basılı tut.',
      'START/STOP düğmesine bas.',
      'Durdurmak için araç dururken düğmeye tekrar bas.',
    ],
  ),
  // — Kilitler ve kapaklar —
  CabinControl('central-lock-button', 'Merkezi Kilit', 'Tüm kapıları birlikte kilitler.', 'Kilitler & Kapaklar',
    tip:
        'Hareket hâlinde kapıların kilitli olması, kapının kazada açılmasını ve dışarıdan açılmasını önler.',
    steps: [
      'Kapalı asma kilit sembollü düğmeye bas.',
      'Tüm kapılar birlikte kilitlenir.',
      'İçeriden açmak için kolu iki kez çekmek gerekebilir.',
    ],
  ),
  CabinControl('central-unlock-button', 'Kilit Açma', 'Tüm kapıların kilidini açar.', 'Kilitler & Kapaklar',
    tip:
        'Kaza sonrası kapıların dışarıdan açılabilmesi için kilidi açmak ilk yapılacaklardandır.',
    steps: [
      'Açık asma kilit sembollü düğmeye bas.',
      'Tüm kapıların kilidi açılır.',
      'Çocuk kilidi ayrıdır; arka kapıda ayrıca kontrol edilir.',
    ],
  ),
  CabinControl('boot-release-button', 'Bagaj Açma', 'Bagaj kapağının kilidini içeriden açar.', 'Kilitler & Kapaklar',
    tip:
        'Bagaj kapağı açıkken araç kullanılmaz; egzoz gazı kabine dolabilir.',
    steps: [
      'Düğmeye basarak bagaj kilidini aç.',
      'Kilit açılınca kapağı elle yukarı kaldır.',
      'Kapatırken kilidin tam oturduğunu kontrol et.',
    ],
  ),
  CabinControl('fuel-flap-button', 'Yakıt Kapağı', 'Depo kapağını içeriden açar.', 'Kilitler & Kapaklar',
    tip:
        'Yakıt almadan önce motor durdurulur; yanlış yakıt türü seçmek motora ciddi zarar verir.',
    steps: [
      'Motoru durdur ve kapak düğmesine bas.',
      'Kapak açılınca yakıt kapağını çevirerek çıkar.',
      'Dolum bitince kapağı sıkıca kapat.',
    ],
    mistake:
        'Motor çalışırken yakıt almak: yangın riski oluşturur.',
  ),
  // — Konfor —
  CabinControl('seat-heater-button', 'Koltuk Isıtma', 'Oturma yüzeyini ısıtır; kademeli gösterge ışığı vardır.', 'Konfor',
    tip:
        'Kademe ışıkları kaç kademenin açık olduğunu gösterir; uzun süre en yüksek kademede kalmak rahatsız edebilir.',
    steps: [
      'Düğmeye her basışta kademe bir artar.',
      'Işıklar açık kademeyi gösterir.',
      'Son basışta sistem kapanır.',
    ],
  ),
  CabinControl('seat-back-heater-button', 'Koltuk + Sırt Isıtma', 'Sırtlık dahil ısıtma kademesi.', 'Konfor',
    tip:
        'Sırtlık ısıtması soğukta kas gerginliğini azaltır; uzun yolda dikkatin dağılmasını geciktirir.',
    steps: [
      'Düğmeye basarak sırtlık dahil ısıtmayı aç.',
      'Kademeyi ihtiyaca göre ayarla.',
      'Isındığında düğmeye tekrar basarak kapat.',
    ],
  ),
  CabinControl('steering-heater-button', 'Direksiyon Isıtma', 'Direksiyon simidini ısıtır.', 'Konfor',
    tip:
        'Isınan direksiyon, kalın eldivenle sürmeye göre çok daha iyi tutuş ve his sağlar.',
    steps: [
      'Direksiyon sembollü düğmeye bas.',
      'Gösterge ışığı yanınca sistem çalışıyordur.',
      'Belli süre sonra kendiliğinden kapanabilir.',
    ],
    mistake:
        'Kalın eldivenle direksiyon tutmak: kavrama ve direksiyon hissi azalır.',
  ),
  CabinControl('mirror-adjust-knob', 'Ayna Ayar Düğmesi', 'L–0–R ile hangi aynanın ayarlanacağı seçilir.', 'Konfor',
    tip:
        'Ayna ayarı araç hareket etmeden önce yapılır; doğru ayarda kendi aracının yalnız çok küçük bir kısmı görünür.',
    steps: [
      'Düğmeyi L (sol) veya R (sağ) konumuna çevir.',
      'Yönlü düğmeyle aynayı ayarla.',
      'Bitince 0 konumuna alarak yanlışlıkla bozulmasını önle.',
    ],
    mistake:
        'Sürüş sırasında ayna ayarlamak: göz yoldan ayrılır.',
  ),
  CabinControl('mirror-fold-switch', 'Ayna Katlama', 'Dış aynaları elektrikli olarak katlar.', 'Konfor',
    tip:
        'Dar sokakta park ederken aynaları katlamak, geçen araçların aynaya çarpmasını önler.',
    steps: [
      'Düğmeye basarak aynaları katla.',
      'Harekete geçmeden önce mutlaka aç.',
      'Aynaların açık ve ayarlı olduğunu kontrol et.',
    ],
    mistake:
        'Aynalar katlıyken yola çıkmak: yan ve arka görüş tamamen kaybolur.',
  ),
  CabinControl('seat-adjust-switch', 'Elektrikli Koltuk Ayarı', 'Koltuk şeklindeki anahtar ileri-geri ve yükseklik ayarını yapar.', 'Konfor',
    tip:
        'Doğru oturuş: debriyaj sonuna kadar basıldığında diz hafif bükülü kalmalı, bilek direksiyonun üst kenarına rahat uzanmalıdır.',
    steps: [
      'Koltuk şeklindeki anahtarla ileri-geri ayarla.',
      'Yükseklik için anahtarın ön veya arka ucunu kaldır-indir.',
      'Sırtlık açısını ayrı düğmeyle ayarla.',
    ],
    mistake:
        'Direksiyona çok yakın oturmak: hava yastığı açıldığında yaralanma riski artar.',
  ),
  // — Soketler —
  CabinControl('socket-12v', '12V Çakmak Soketi', 'Aksesuar beslemesi; sigortası ayrıdır.', 'Soketler',
    tip:
        'Soketin ayrı bir sigortası vardır; çalışmıyorsa önce sigorta kontrol edilir.',
    steps: [
      'Kapağı açıp fişi sonuna kadar otur.',
      'Çoğu araçta kontak açıkken güç verir.',
      'Kullanmadığında kapağı kapat.',
    ],
    mistake:
        'Yüksek güçlü cihazı çakmak soketine bağlamak: sigorta atar veya soket aşırı ısınır.',
  ),
  CabinControl('usb-a-socket', 'USB-A Soketi', 'Veri ve şarj için standart USB girişi.', 'Soketler',
    tip:
        'Veri destekli girişte telefon multimedya sistemine bağlanabilir; yalnız şarj girişi bunu yapmaz.',
    steps: [
      'Kabloyu USB-A girişine tak.',
      'Ekranda cihaz tanınıyorsa veri desteği vardır.',
      'Sürüş sırasında telefonla ilgilenme.',
    ],
  ),
  CabinControl('usb-c-socket', 'USB-C Soketi', 'Hızlı şarj destekli yeni nesil giriş.', 'Soketler',
    tip:
        'USB-C tersi düz takılabilir ve daha yüksek şarj gücü verir.',
    steps: [
      'Kabloyu USB-C girişine tak.',
      'Hızlı şarj için uygun kablo kullan.',
      'Kullanım bitince kabloyu çıkar.',
    ],
  ),
  CabinControl('usb-charge-socket', 'USB Şarj Soketi', 'Yalnız şarj amaçlı (veri aktarmaz) giriş.', 'Soketler',
    tip:
        'Pil sembollü giriş yalnız şarj eder; telefonu multimedya sistemine bağlamaz.',
    steps: [
      'Kabloyu şarj girişine tak.',
      'Cihaz şarj olur ama ekranda görünmez.',
      'Veri gerekiyorsa veri destekli girişi kullan.',
    ],
  ),
  CabinControl('usb-dual-socket', 'İkili USB Soketi', 'İki cihazı aynı anda besleyen çiftli giriş.', 'Soketler',
    tip:
        'İki cihaz aynı anda takılınca toplam güç paylaşılır; şarj yavaşlayabilir.',
    steps: [
      'Kabloları iki girişe de takabilirsin.',
      'Şarj yavaşsa tek cihazla dene.',
      'Kabloları pedal bölgesinden uzak tut.',
    ],
    mistake:
        'Kabloları pedal bölgesine sarkıtmak: pedal hareketini engelleyebilir.',
  ),
  CabinControl('blank-panel', 'Boş Kapak', 'Opsiyonel donanım takılmadığında yuvayı kapatan kör kapak.', 'Soketler',
    tip:
        'Kör kapak bir arıza değildir; o donanım araçta yok demektir. Sökülüp açık bırakılırsa yuvaya toz ve nem girer.',
    steps: [
      'Kör kapağı yerinden sökmeden bırak.',
      'Sonradan donanım eklenirse kapak yerine düğme takılır.',
      'Sökülmüşse mutlaka geri tak.',
    ],
  ),
];

/// Beta Faz 10 — görsel kimliğinden kumandayı bulur (detay yönlendirmesi bunu kullanır).
///
/// Bilinmeyen kimlikte `null` döner; detay ekranı bunu "bulunamadı" olarak gösterir. Böylece
/// eski/yanlış bir bağlantı çökme değil, dürüst bir boş durum üretir.
CabinControl? cabinControlByAsset(String asset) {
  for (final c in kCabinControls) {
    if (c.asset == asset) return c;
  }
  return null;
}
