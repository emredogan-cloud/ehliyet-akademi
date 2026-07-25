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
  const CabinControl(this.asset, this.title, this.desc, this.group);
  final String asset;
  final String title;
  final String desc;
  final String group;
}

/// Kabin Kumandaları galerisi — B sınıfı araç içi düğme/kol/soket kütüphanesi.
/// Sıra, kaynak sayfadaki mantıksal gruplama ile aynı.
const List<CabinControl> kCabinControls = [
  // — Kollar ve far kumandaları —
  CabinControl('wiper-stalk-int', 'Silecek Kolu (fasılalı)', 'INT konumu fasılalı silme; aşağı iterek tek sefer silinir.', 'Kollar & Farlar'),
  CabinControl('wiper-stalk-speed', 'Silecek Kolu (hız kademeli)', 'MIST–OFF–INT–LO–HI kademeleri; yağış şiddetine göre seçilir.', 'Kollar & Farlar'),
  CabinControl('wiper-stalk-rear', 'Arka Silecek Kolu', 'Arka cam sileceği ve yıkama suyunu çalıştırır.', 'Kollar & Farlar'),
  CabinControl('headlight-knob-auto', 'Far Düğmesi (AUTO)', '0–AUTO konumları; AUTO\'da farlar ışık sensörüyle otomatik yanar.', 'Kollar & Farlar'),
  CabinControl('headlight-knob-manual', 'Far Düğmesi (manuel)', 'Park lambası ve kısa hüzme konumları elle seçilir.', 'Kollar & Farlar'),
  CabinControl('headlight-knob-fog', 'Sis Farı Düğmesi', 'Ön/arka sis farları; yalnız görüş 50 m altındayken kullanılır.', 'Kollar & Farlar'),
  CabinControl('hazard-button-round', 'Dörtlü Flaşör (yuvarlak)', 'Arıza, kaza veya zorunlu duruşta tüm sinyalleri birlikte yakar.', 'Kollar & Farlar'),
  CabinControl('hazard-button-rocker', 'Dörtlü Flaşör (basmalı)', 'Aynı işlev; konsol tipi basmalı düğme.', 'Kollar & Farlar'),
  // — Klima —
  CabinControl('climate-temp-knob', 'Sıcaklık Ayarı', 'Mavi–kırmızı skala kabin sıcaklığını belirler.', 'Klima'),
  CabinControl('climate-fan-knob', 'Fan Kademesi', '0–4 arası üfleme gücü; buğu çözmede yüksek kademe kullanılır.', 'Klima'),
  CabinControl('climate-flow-knob', 'Hava Yönü', 'Havanın yüze, ayağa veya cama yönlendirilmesini seçer.', 'Klima'),
  CabinControl('climate-recirc-knob', 'İç Hava Sirkülasyonu', 'Dış havayı keser; tünelde/kokuda kullanılır, uzun süre açık bırakılmaz.', 'Klima'),
  CabinControl('climate-maxac-knob', 'MAX A/C', 'Klimayı en yüksek soğutmada çalıştırır.', 'Klima'),
  CabinControl('rear-defrost-knob', 'Arka Cam Rezistansı', 'Arka camdaki teller buğu ve buzu çözer.', 'Klima'),
  CabinControl('ac-button', 'Klima (A/C)', 'Kompresörü devreye alır; nemi alarak buğuyu da hızlı çözer.', 'Klima'),
  CabinControl('maxac-button', 'MAX A/C Düğmesi', 'Sirkülasyon + tam soğutmayı tek dokunuşla açar.', 'Klima'),
  CabinControl('front-defrost-button', 'Ön Cam Buğu Çözücü', 'Havayı ön cama yönlendirir; buğuyu en hızlı bu ayar çözer.', 'Klima'),
  CabinControl('rear-defrost-button', 'Arka Cam Buğu Çözücü', 'Arka cam rezistansını açar; belli süre sonra kendi kapanır.', 'Klima'),
  // — Sürüş yardımcıları —
  CabinControl('park-sensor-button', 'Park Sensörü', 'Manevrada mesafe uyarısını açar/kapatır.', 'Sürüş Yardımcıları'),
  CabinControl('start-stop-off-button', 'Start/Stop Kapatma', 'Motorun durakta otomatik susmasını devre dışı bırakır.', 'Sürüş Yardımcıları'),
  CabinControl('esp-off-button', 'ESP / Çekiş Kapatma', 'Kayma önleyiciyi kapatır; normal sürüşte AÇIK kalmalıdır.', 'Sürüş Yardımcıları'),
  CabinControl('rear-fog-slider', 'Arka Sis Lambası', 'Yalnız yoğun sis/kar/yağmurda; açık havada arkadakini kör eder.', 'Sürüş Yardımcıları'),
  CabinControl('engine-start-stop', 'Marş Düğmesi', 'Anahtarsız çalıştırma; fren basılıyken motoru çalıştırır.', 'Sürüş Yardımcıları'),
  // — Kilitler ve kapaklar —
  CabinControl('central-lock-button', 'Merkezi Kilit', 'Tüm kapıları birlikte kilitler.', 'Kilitler & Kapaklar'),
  CabinControl('central-unlock-button', 'Kilit Açma', 'Tüm kapıların kilidini açar.', 'Kilitler & Kapaklar'),
  CabinControl('boot-release-button', 'Bagaj Açma', 'Bagaj kapağının kilidini içeriden açar.', 'Kilitler & Kapaklar'),
  CabinControl('fuel-flap-button', 'Yakıt Kapağı', 'Depo kapağını içeriden açar.', 'Kilitler & Kapaklar'),
  // — Konfor —
  CabinControl('seat-heater-button', 'Koltuk Isıtma', 'Oturma yüzeyini ısıtır; kademeli gösterge ışığı vardır.', 'Konfor'),
  CabinControl('seat-back-heater-button', 'Koltuk + Sırt Isıtma', 'Sırtlık dahil ısıtma kademesi.', 'Konfor'),
  CabinControl('steering-heater-button', 'Direksiyon Isıtma', 'Direksiyon simidini ısıtır.', 'Konfor'),
  CabinControl('mirror-adjust-knob', 'Ayna Ayar Düğmesi', 'L–0–R ile hangi aynanın ayarlanacağı seçilir.', 'Konfor'),
  CabinControl('mirror-fold-switch', 'Ayna Katlama', 'Dış aynaları elektrikli olarak katlar.', 'Konfor'),
  CabinControl('seat-adjust-switch', 'Elektrikli Koltuk Ayarı', 'Koltuk şeklindeki anahtar ileri-geri ve yükseklik ayarını yapar.', 'Konfor'),
  // — Soketler —
  CabinControl('socket-12v', '12V Çakmak Soketi', 'Aksesuar beslemesi; sigortası ayrıdır.', 'Soketler'),
  CabinControl('usb-a-socket', 'USB-A Soketi', 'Veri ve şarj için standart USB girişi.', 'Soketler'),
  CabinControl('usb-c-socket', 'USB-C Soketi', 'Hızlı şarj destekli yeni nesil giriş.', 'Soketler'),
  CabinControl('usb-charge-socket', 'USB Şarj Soketi', 'Yalnız şarj amaçlı (veri aktarmaz) giriş.', 'Soketler'),
  CabinControl('usb-dual-socket', 'İkili USB Soketi', 'İki cihazı aynı anda besleyen çiftli giriş.', 'Soketler'),
  CabinControl('blank-panel', 'Boş Kapak', 'Opsiyonel donanım takılmadığında yuvayı kapatan kör kapak.', 'Soketler'),
];
