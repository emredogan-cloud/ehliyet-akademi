/**
 * Araç bileşen kütüphanesi meta verisi (Program 1 · Görsel Dönüşüm Bölüm 2).
 * Direksiyon + araç tekniği için: her bileşenin görevi, ipucu, ilgili ders.
 */

export type VehicleSystem = 'motor-bolmesi' | 'kabin' | 'dis' | 'muayene';

export const SYSTEM_LABEL: Record<VehicleSystem, string> = {
  'motor-bolmesi': 'Motor Bölmesi',
  kabin: 'Kabin & Kumandalar',
  dis: 'Dış & Lastikler',
  muayene: 'Muayene & Park',
};

export interface VehiclePart {
  id: string; // VehicleFigure part id ile birebir
  name: string;
  system: VehicleSystem;
  desc: string;
  tip: string;
  relatedLessonSlug?: string;
  /** Program 2 · Faz 1 — premium fotoğraf (asset-manifest kimliği). */
  photo?: string;
  /** Program 2 · Faz 7 — muayene/kontrol adımları (sıralı). */
  inspection?: string[];
  /** Sık yapılan hata/yanlış bilgi. */
  mistake?: string;
}

const BASE_PARTS: VehiclePart[] = [
  // Motor bölmesi
  {
    id: 'engine-bay',
    name: 'Motor Bölmesi',
    system: 'motor-bolmesi',
    desc: 'Motor, akü, sıvı depoları ve kayışların bulunduğu bölme.',
    tip: 'Kaput açıldığında seviye kaplarını sırayla kontrol et.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'battery',
    name: 'Akü',
    system: 'motor-bolmesi',
    desc: 'Elektrik enerjisini depolar; marş ve elektronik sistemleri besler.',
    tip: 'Kutup başları (+/−) temiz ve sıkı olmalı; takviye sırasına dikkat.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'dipstick',
    name: 'Yağ Çubuğu (Dipstick)',
    system: 'motor-bolmesi',
    desc: 'Motor yağ seviyesini gösterir.',
    tip: 'Motor soğukken; sil, batır, MIN–MAX arasında olmalı.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'coolant',
    name: 'Soğutma Suyu Deposu',
    system: 'motor-bolmesi',
    desc: 'Motoru soğutan antifriz karışımını tutar.',
    tip: 'Sıcak motorda kapağı AÇMA (yanma riski); seviye çizgileri arasında olmalı.',
    relatedLessonSlug: 'gosterge-ikaz',
  },
  {
    id: 'brake-fluid',
    name: 'Fren Hidroliği',
    system: 'motor-bolmesi',
    desc: 'Fren basıncını tekerleklere iletir.',
    tip: 'Seviye düşükse fren arızası olabilir; nem çeker, periyodik değişir.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'washer',
    name: 'Cam Suyu Deposu',
    system: 'motor-bolmesi',
    desc: 'Ön/arka cam yıkama suyunu tutar.',
    tip: 'Kışın antifrizli cam suyu kullan; görüş güvenliği içindir.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'fuse-box',
    name: 'Sigorta Kutusu',
    system: 'motor-bolmesi',
    desc: 'Elektrik devrelerini aşırı akıma karşı korur.',
    tip: 'Çalışmayan bir elektrikli sistemde önce ilgili sigortayı kontrol et.',
    relatedLessonSlug: 'motor-temel',
  },

  // Kabin
  {
    id: 'dashboard',
    name: 'Gösterge Paneli',
    system: 'kabin',
    desc: 'Hız, devir ve ikaz lambalarını gösterir.',
    tip: 'Kırmızı ikaz = dur/acil; sarı ikaz = en kısa sürede kontrol.',
    relatedLessonSlug: 'gosterge-ikaz',
  },
  {
    id: 'steering',
    name: 'Direksiyon',
    system: 'kabin',
    desc: 'Aracın yönünü kontrol eder.',
    tip: 'İki elle (9-3 veya 10-2) tut; aşırı boşluk arıza işaretidir.',
    relatedLessonSlug: 'arac-hazirlik',
  },
  {
    id: 'pedals',
    name: 'Pedallar (Debriyaj-Fren-Gaz)',
    system: 'kabin',
    desc: 'Manuelde soldan sağa: debriyaj, fren, gaz.',
    tip: 'Debriyaj sol ayak; fren ve gaz sağ ayak. Kavrama noktasını hisset.',
    relatedLessonSlug: 'debriyaj-rampa',
  },
  {
    id: 'gearbox',
    name: 'Vites Kolu (Şanzıman)',
    system: 'kabin',
    desc: 'Motor gücünü tekerleğe uygun oranda aktarır.',
    tip: 'Kalkış 1. vites; hız arttıkça yukarı; geri (R) için tam dur.',
    relatedLessonSlug: 'debriyaj-rampa',
  },
  {
    id: 'handbrake',
    name: 'El Freni',
    system: 'kabin',
    desc: 'Aracı park hâlinde sabit tutar; rampada kalkışa yardımcı olur.',
    tip: 'Rampada kalkışta el freni + kavrama noktası + gaz koordinasyonu.',
    relatedLessonSlug: 'debriyaj-rampa',
  },
  {
    id: 'seat',
    name: 'Koltuk Ayarı',
    system: 'kabin',
    desc: 'Sürüş pozisyonunu ayarlar.',
    tip: 'Pedallara rahat basacak, direksiyona hâkim olacak mesafe; baş desteği doğru yükseklikte.',
    relatedLessonSlug: 'arac-hazirlik',
  },
  {
    id: 'mirrors',
    name: 'Aynalar',
    system: 'kabin',
    desc: 'İç + sağ/sol dış aynalar çevre görüşü sağlar.',
    tip: 'Sürüşten önce üç aynayı ayarla; yine de kör nokta için omuz üstü bak.',
    relatedLessonSlug: 'arac-hazirlik',
  },
  {
    id: 'lights',
    name: 'Aydınlatma Kumandaları',
    system: 'kabin',
    desc: 'Kısa/uzun far, sinyal, sis ve dörtlü flaşör.',
    tip: 'Karşı araç varken uzun far yakma; dönüşte erken sinyal ver.',
    relatedLessonSlug: 'isik-gece',
  },

  // Dış & lastikler
  {
    id: 'tyre',
    name: 'Lastik',
    system: 'dis',
    desc: 'Yol tutuşu ve frenlemeyi belirler.',
    tip: 'Diş derinliği ve hava basıncı güvenlik içindir; aşınmayı kontrol et.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'spare-wheel',
    name: 'Stepne',
    system: 'dis',
    desc: 'Yedek lastik.',
    tip: 'Basıncını periyodik kontrol et; yerini ve çıkarma yöntemini bil.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'jack',
    name: 'Kriko',
    system: 'dis',
    desc: 'Lastik değişimi için aracı kaldırır.',
    tip: 'Düz zeminde, doğru kaldırma noktasından; el freni çekili + takoz.',
    relatedLessonSlug: 'motor-temel',
  },
  {
    id: 'wrench',
    name: 'Bijon Anahtarı',
    system: 'dis',
    desc: 'Tekerlek bijonlarını söker/takar.',
    tip: 'Kaldırmadan önce bijonları gevşet; indirdikten sonra çapraz sırayla sık.',
    relatedLessonSlug: 'motor-temel',
  },

  // Muayene & park
  {
    id: 'inspection-points',
    name: 'Muayene Noktaları',
    system: 'muayene',
    desc: 'Sürüş öncesi kontrol edilecek temel noktalar.',
    tip: 'Lastik, farlar, sinyaller, sıvı seviyeleri, ayna ve kemer.',
    relatedLessonSlug: 'arac-hazirlik',
  },
  {
    id: 'parking-reference',
    name: 'Park Referans Noktaları',
    system: 'muayene',
    desc: 'Park manevrasında hizalama için referanslar.',
    tip: 'Öndeki araçla hizala; ayna + kör nokta kontrolüyle yavaşça manevra yap.',
    relatedLessonSlug: 'park-manevra',
  },
];

/**
 * Program 2 · Faz 1 — foto-öncelikli yeni bileşenler (çizim şeması yok; premium fotoğrafla gelir).
 */
const EXTRA_PARTS: VehiclePart[] = [
  {
    id: 'warning-lights',
    name: 'İkaz Lambaları',
    system: 'kabin',
    desc: 'Gösterge panelindeki renkli uyarı lambaları; sistem durumunu bildirir.',
    tip: 'Kontak açılınca kısa süre hepsi yanar (öz test); sürüşte yanan kırmızı = dur, sarı = kontrol.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'warning-lights',
  },
  {
    id: 'dashboard-buttons',
    name: 'Konsol Düğmeleri',
    system: 'kabin',
    desc: 'Dörtlü flaşör, cam rezistansı gibi merkezî kumanda düğmeleri.',
    tip: 'Dörtlü flaşörün (kırmızı üçgen) yerini ezberle; arıza/tehlikede refleksle basabilmelisin.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'dashboard-buttons',
  },
  {
    id: 'steering-controls',
    name: 'Direksiyon Kumandaları',
    system: 'kabin',
    desc: 'Direksiyon üzerindeki tuşlar ve arkasındaki kumanda kolları.',
    tip: 'Gözün yoldayken kullanabilmen için kumandaların yerini sürüşten önce öğren.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'steering-controls',
  },
  {
    id: 'turn-signal-stalk',
    name: 'Sinyal Kolu',
    system: 'kabin',
    desc: 'Sol taraftaki kol; sinyaller ve far seçimi.',
    tip: 'Dönüş/şerit değişiminden yeterince önce sinyal ver; manevra bitince söndüğünü doğrula.',
    relatedLessonSlug: 'sollama-serit',
    photo: 'turn-signal-stalk',
  },
  {
    id: 'wiper-controls',
    name: 'Silecek Kumandası',
    system: 'kabin',
    desc: 'Sağ taraftaki kol; silecek hızı ve cam suyu püskürtme.',
    tip: 'Yağmur başlar başlamaz sileceği kademesine göre ayarla; görüş güvenliğin önceliklidir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'wiper-controls',
  },
  {
    id: 'mirror-adjust',
    name: 'Ayna Ayarı',
    system: 'kabin',
    desc: 'Elektrikli ayna ayar kumandası (kapı kolçağında).',
    tip: 'Aynaları koltuk ayarından SONRA ayarla; yan aynada aracın kenarı ince bir şerit görünmeli.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'mirror-adjust',
  },
  {
    id: 'seat-controls',
    name: 'Koltuk Ayarları',
    system: 'kabin',
    desc: 'Koltuk ileri-geri kızağı, yükseklik pompası ve sırt açısı ayarı.',
    tip: 'Debriyaja tam basarken diz hafif kırık kalmalı; direksiyona bilek mesafesi ölçüsünü kullan.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'seat-controls',
  },
  {
    id: 'seat-belt',
    name: 'Emniyet Kemeri',
    system: 'kabin',
    desc: 'Çarpışmada tutunmayı sağlayan üç noktalı kemer sistemi.',
    tip: 'Kemeri boyun değil köprücük kemiği üzerinden geçir; kıvrılmış kemer koruma sağlamaz.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'seat-belt',
  },
  {
    id: 'automatic-gearbox',
    name: 'Otomatik Vites',
    system: 'kabin',
    desc: 'P-R-N-D konumlu otomatik şanzıman seçici.',
    tip: 'Park için P + el freni; D↔R geçişinde araç TAM durmuş olmalı.',
    relatedLessonSlug: 'debriyaj-rampa',
    photo: 'automatic-gearbox',
  },
  {
    id: 'headlights',
    name: 'Farlar',
    system: 'dis',
    desc: 'Kısa ve uzun huzmeli ön aydınlatma.',
    tip: 'Karşıdan araç gelince uzun farı kısaya al; gündüz yağış/sis varsa kısa farı yak.',
    relatedLessonSlug: 'isik-gece',
    photo: 'headlights',
  },
  {
    id: 'fog-lights',
    name: 'Sis Farları',
    system: 'dis',
    desc: 'Tampon altına yerleştirilmiş, sis/yoğun yağışta kullanılan lambalar.',
    tip: 'Sis farını yalnız görüş ciddi düşünce kullan; açık havada kullanmak diğer sürücüleri rahatsız eder.',
    relatedLessonSlug: 'isik-gece',
    photo: 'fog-lights',
  },
  {
    id: 'boot',
    name: 'Bagaj',
    system: 'dis',
    desc: 'Yük alanı; stepne, kriko ve zorunlu ekipman burada taşınır.',
    tip: 'Yükü dengeli ve sabitlenmiş taşı; arka camı kapatacak yükseklikte yükleme yapma.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'boot',
  },
  {
    id: 'emergency-kit',
    name: 'Acil Durum Ekipmanı',
    system: 'muayene',
    desc: 'Reflektör üçgen, reflektif yelek ve ilk yardım seti — araçta bulunması zorunlu.',
    tip: 'Arızada üçgeni aracın en az 30 m gerisine koy; yola inmeden önce reflektif yeleği giy.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'emergency-kit',
  },
];

/**
 * Program 2 · Faz 7 — genişletilmiş bileşen kataloğu (muayene adımları + sık hata bilgisiyle).
 */
const PHASE7_PARTS: VehiclePart[] = [
  {
    id: 'wiper-blade',
    name: 'Silecek Lastiği',
    system: 'dis',
    desc: 'Cam yüzeyindeki suyu ve kiri sıyırarak yağışta net görüş sağlar.',
    tip: 'Silerken iz bırakıyor veya cıyaklıyorsa lastik ömrünü doldurmuştur; genellikle yılda bir yenilenir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'wiper-blade',
    inspection: [
      'Silecek kolunu kaldırıp lastik kenarını parmakla yokla; çatlak ve sertleşme ara.',
      'Cam suyu püskürtüp sileceği çalıştır; iz veya atlanan bölge var mı bak.',
      'Lastiğin taşıyıcıya tam oturduğunu ve kolda boşluk olmadığını kontrol et.',
    ],
    mistake: 'Buzlanmış camda sileceği çalıştırmak lastiği yırtar; önce buz kazınmalıdır.',
  },
  {
    id: 'isofix',
    name: 'ISOFIX Bağlantısı',
    system: 'kabin',
    desc: 'Çocuk koltuğunu araç gövdesine standart metal kancalarla sabitleyen bağlantı sistemidir.',
    tip: 'Kancalar arka koltuk minderi ile sırtlığı arasında gizlidir; koltuk oturunca kilit göstergesinin yeşile döndüğünü doğrula.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'isofix',
    inspection: [
      'Arka koltukta ISOFIX etiketini ve minder arasındaki metal kancaları bul.',
      'Çocuk koltuğunu kancalara oturt; kilit sesini duy ve yeşil göstergeyi gör.',
      'Koltuğu öne ve yanlara çekerek boşluk kalmadığını test et.',
    ],
    mistake:
      'Üst bağlantı kayışını (top-tether) veya destek ayağını takmayı unutmak; koltuk çarpışmada öne doğru döner.',
  },
  {
    id: 'climate-controls',
    name: 'Klima Kumandası',
    system: 'kabin',
    desc: 'Kabin sıcaklığını, fan hızını ve hava yönlendirmesini ayarlar.',
    tip: 'Buğulanan ön cam için havayı cama yönlendirip A/C düğmesini aç; kurutulmuş hava buğuyu hızla alır.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'climate-controls',
    inspection: [
      'Fanı kademe kademe artırıp her hızda çalıştığını dinle.',
      'Hava yönünü cam konumuna al; üflemenin ön cama geldiğini hisset.',
      'A/C açıkken soğutmanın geldiğini ve iç sirkülasyon düğmesinin konumunu kontrol et.',
    ],
    mistake:
      'Uzun süre iç sirkülasyonda kalmak camların buğulanmasını artırır ve kabin havasını bayatlatır.',
  },
  {
    id: 'window-switches',
    name: 'Cam Kumandaları',
    system: 'kabin',
    desc: 'Elektrikli camları açıp kapatır; sürücü kapısından tüm camlar yönetilebilir.',
    tip: 'Çocuklar arkadayken cam kilidi düğmesini etkinleştir; arka camlar yalnızca sürücüden kumanda edilir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'window-switches',
    inspection: [
      'Kontak açıkken her camı ayrı ayrı indirip kaldır; takılma olup olmadığını dinle.',
      'Cam kilidi düğmesini test et; arka kumandaların devre dışı kaldığını doğrula.',
      'Tek dokunuşla (otomatik) açma-kapama işlevinin çalıştığını dene.',
    ],
    mistake:
      'Sıkışma korumasına güvenip cam kapanırken açıklıkta el veya kol bırakmak yaralanmaya yol açabilir.',
  },
  {
    id: 'fuel-cap',
    name: 'Yakıt Depo Kapağı',
    system: 'dis',
    desc: 'Yakıt deposunun ağzını sızdırmaz biçimde kapatarak buhar kaçağını ve kirlenmeyi önler.',
    tip: 'Deponun hangi tarafta olduğunu gösterge panelindeki pompa simgesinin yanındaki ok gösterir.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'fuel-cap',
    inspection: [
      'Kapağı aç; contasında çatlak ve yıpranma olup olmadığına bak.',
      'Yakıt aldıktan sonra kapağı klik sesi gelene kadar çevirerek kapat.',
      'Dış kapak varsa mandalının tam kilitlendiğini kontrol et.',
    ],
    mistake: 'Kapağı gevşek bırakmak bazı araçlarda motor arıza lambasının yanmasına neden olur.',
  },
  {
    id: 'exhaust',
    name: 'Egzoz',
    system: 'dis',
    desc: 'Yanma gazlarını susturucudan geçirerek sesi azaltır ve aracın arkasından dışarı atar.',
    tip: 'Rölantide mavi duman yağ yakmaya, siyah duman zengin karışıma, sürekli beyaz duman conta sorununa işaret edebilir.',
    relatedLessonSlug: 'motor-temel',
    photo: 'exhaust',
    inspection: [
      'Araç altına göz at; sarkan boru, paslanıp delinmiş bölüm veya gevşek kelepçe ara.',
      'Motoru çalıştırıp kaçak sesi (patlamalı üfleme) olup olmadığını dinle.',
      'Duman rengini gözle; mavi, siyah veya sürekli yoğun beyaz duman anormaldir.',
    ],
    mistake:
      'Kapalı garajda motoru çalışır bırakmak egzozdaki karbonmonoksit nedeniyle zehirlenmeye yol açar.',
  },
  {
    id: 'suspension',
    name: 'Süspansiyon & Amortisör',
    system: 'dis',
    desc: 'Yoldan gelen darbeleri sönümleyerek lastiğin yola temasını ve sürüş dengesini korur.',
    tip: 'Çamurluk üstünden bastırıp bıraktığında araç bir-iki salınımda duruyorsa amortisör sağlıklıdır.',
    relatedLessonSlug: 'hiz-takip',
    photo: 'suspension',
    inspection: [
      'Her çamurluk üstünden aracı bastırıp bırak; bir-iki salınımda durmalı.',
      'Amortisör gövdesinde yağ sızıntısı izi ara.',
      'Lastik yüzeyinde dalgalı, kupa şeklinde düzensiz aşınma olup olmadığını kontrol et.',
    ],
    mistake:
      'Yağ kaçıran amortisörle sürüşe devam etmek fren mesafesini uzatır ve lastiği düzensiz aşındırır.',
  },
  {
    id: 'brake-disc',
    name: 'Fren Diski',
    system: 'dis',
    desc: 'Balataların sıkıştırdığı, sürtünmeyle tekerleğin dönüşünü yavaşlatan metal disktir.',
    tip: 'Uzun inişlerde motor freni kullan; sürekli frenleme diski aşırı ısıtıp fren zayıflamasına yol açar.',
    relatedLessonSlug: 'hiz-takip',
    photo: 'brake-disc',
    inspection: [
      'Jant aralığından disk yüzeyine bak; derin çizik ve renk atması ara.',
      'Disk kenarında elle hissedilir çıkıntı (aşınma dudağı) olup olmadığını kontrol et.',
      'Frenlerken direksiyona titreşim geliyorsa disk yamulması olabileceğini not et.',
    ],
    mistake:
      'Islak diskin frenlemeyi geciktirebileceğini unutmak; su birikintisinden sonra frene hafifçe dokunarak diski kurut.',
  },
  {
    id: 'brake-pads',
    name: 'Fren Balatası',
    system: 'dis',
    desc: 'Fren diskine sürtünerek aracın kinetik enerjisini ısıya çevirir ve aracı yavaşlatır.',
    tip: 'Frenlemede duyulan metalik gıcırtı çoğu balatada aşınma ikaz sacının sesidir; gecikmeden kontrol ettir.',
    relatedLessonSlug: 'hiz-takip',
    photo: 'brake-pads',
    inspection: [
      'Jant aralığından balata kalınlığına bak; yaklaşık 3 mm altı değişim zamanıdır.',
      'Frenleme sırasında gıcırtı veya sürtme sesi olup olmadığını dinle.',
      'Balata aşınma ikaz lambası yanıyorsa ertelemeden servise git.',
    ],
    mistake:
      'Balata bittiği hâlde sürmeye devam etmek; metal metale sürtünme diski de bozar ve fren gücünü ciddi düşürür.',
  },
  {
    id: 'timing-belt',
    name: 'Triger Kayışı',
    system: 'motor-bolmesi',
    desc: 'Krank mili ile eksantrik milini senkron döndürerek supapların pistonlarla uyumlu çalışmasını sağlar.',
    tip: 'Üreticinin belirttiği kilometrede veya yılda mutlaka değiştir; kopması motorda ağır hasara yol açar.',
    relatedLessonSlug: 'motor-temel',
    photo: 'timing-belt',
    inspection: [
      'Servis kaydından son değişim kilometresini ve tarihini doğrula.',
      'Muhafaza açıksa kayış yüzeyinde çatlak, sırlanma veya diş kopması ara.',
      'Motor çalışırken kayış bölgesinden gelen tıkırtı veya hışırtıyı dinle.',
    ],
    mistake:
      'Kayışı sağlam göründüğü için değiştirmemek; triger belirti vermeden kopabilir ve supaplar pistonlara çarpar.',
  },
  {
    id: 'alternator',
    name: 'Alternatör',
    system: 'motor-bolmesi',
    desc: 'Motor çalışırken elektrik üreterek aküyü şarj eder ve araç elektrik sistemini besler.',
    tip: 'Sürüş sırasında yanan akü ikaz lambası genellikle akünün değil, şarj sisteminin arızasını gösterir.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'alternator',
    inspection: [
      'Motor çalışınca akü ikaz lambasının söndüğünü doğrula.',
      'Alternatörü döndüren kayışın gerginliğini ve yüzeyini kontrol et.',
      'Rölantide farlar açıkken belirgin ışık titremesi olup olmadığına bak.',
    ],
    mistake:
      'Akü lambası yanınca yalnızca aküyü değiştirmek; sorun çoğu zaman alternatörde veya kayışındadır.',
  },
  {
    id: 'serpentine-belt',
    name: 'V Kayışı',
    system: 'motor-bolmesi',
    desc: 'Krank kasnağından aldığı hareketle alternatör, su pompası ve klima kompresörü gibi donanımları döndürür.',
    tip: 'Soğuk kalkışta duyulan cıyaklama genellikle gevşemiş veya camlaşmış kayışın işaretidir.',
    relatedLessonSlug: 'motor-temel',
    photo: 'serpentine-belt',
    inspection: [
      'Motor kapalıyken kayış yüzeyinde çatlak, saçaklanma ve parlama ara.',
      'Başparmakla bastırınca kayış aşırı esniyorsa gerginliği kontrol ettir.',
      'Soğuk çalıştırmada cıyaklama sesi olup olmadığını dinle.',
    ],
    mistake:
      'Cıyaklayan kayışı spreyle susturmaya çalışmak; gerginlik ve aşınma giderilmezse kayış kopar, şarj ve soğutma durur.',
  },
  {
    id: 'radiator-fan',
    name: 'Radyatör Fanı',
    system: 'motor-bolmesi',
    desc: 'Araç yavaşken veya dururken radyatör üzerinden hava geçişi sağlayarak motorun hararet yapmasını önler.',
    tip: 'Hararet trafikte yükselip seyir hâlinde düşüyorsa ilk şüphe fan veya fan müşiridir.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'radiator-fan',
    inspection: [
      'Motor sıcakken rölantide bekle; fanın belirli sıcaklıkta devreye girdiğini duy.',
      'Motor kapalı ve soğukken fan kanatlarında kırık ve göbekte boşluk kontrol et.',
      'Klima açıkken fanın çalıştığını gözle.',
    ],
    mistake:
      'Kontak kapalı diye fanın dönmeyeceğini sanmak; fan, motor sıcakken kendiliğinden devreye girebilir.',
  },
  {
    id: 'cabin-filter',
    name: 'Polen Filtresi',
    system: 'kabin',
    desc: 'Kabine giren havadaki toz ve polenleri tutarak iç hava kalitesini korur.',
    tip: 'Camlar sık buğulanıyor veya fan zayıf üflüyorsa filtre tıkanmış olabilir; genellikle yılda bir değişir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'cabin-filter',
    inspection: [
      'Genellikle torpido arkasında bulunan filtre yuvasını aç.',
      'Filtre yüzeyindeki toz, yaprak ve kararmayı kontrol et.',
      'Yenisini takarken hava akış yönü okuna dikkat et.',
    ],
    mistake:
      'Polen filtresini motorun hava filtresiyle karıştırmak; polen filtresi kabin havasını süzer, torpido arkasındadır.',
  },
  {
    id: 'air-filter',
    name: 'Hava Filtresi',
    system: 'motor-bolmesi',
    desc: 'Motora emilen havadaki toz ve partikülleri tutarak silindirleri aşınmadan korur.',
    tip: 'Tıkalı filtre yakıt tüketimini artırıp gücü düşürür; tozlu bölgede daha sık değiştir.',
    relatedLessonSlug: 'motor-temel',
    photo: 'air-filter',
    inspection: [
      'Filtre kutusunun klipslerini açıp elemanı çıkar.',
      'Filtreyi ışığa tut; ışık geçmiyorsa tıkanmıştır.',
      'Kutu içine kaçan yaprak ve tozu temizleyip filtreyi yuvasına düzgün oturt.',
    ],
    mistake:
      'Kâğıt filtreyi basınçlı havayla temizleyip uzun süre kullanmak; filtre delinirse toz doğrudan motora kaçar.',
  },
  {
    id: 'oil-filter',
    name: 'Yağ Filtresi',
    system: 'motor-bolmesi',
    desc: 'Motor yağındaki metal parçacıkları ve kurumu süzerek yağlama sistemini temiz tutar.',
    tip: 'Her yağ değişiminde filtre de birlikte yenilenmelidir; eski filtre yeni yağı hemen kirletir.',
    relatedLessonSlug: 'motor-temel',
    photo: 'oil-filter',
    inspection: [
      'Yağ değişiminde filtrenin de yenilendiğini servis kaydından doğrula.',
      'Filtre gövdesi çevresinde yağ sızıntısı izi ara.',
      'Aracın park ettiği zeminde yağ damlası olup olmadığını kontrol et.',
    ],
    mistake:
      'Yağı değiştirip filtreyi eski bırakmak; filtredeki kirli yağ ve tortu yeni yağa karışır.',
  },
  {
    id: 'spark-plug',
    name: 'Buji',
    system: 'motor-bolmesi',
    desc: 'Benzinli motorda silindire alınan yakıt-hava karışımını kıvılcımla ateşler.',
    tip: 'Rölantide teklemenin sık nedeni aşınmış bujidir; üreticinin aralığında takım hâlinde değiştir.',
    relatedLessonSlug: 'motor-temel',
    photo: 'spark-plug',
    inspection: [
      'Rölantide düzensizlik ve tekleme olup olmadığını dinle.',
      'Servis kaydından buji değişim aralığının geçilmediğini kontrol et.',
      'Sökülen bujinin elektrot rengine bak; açık kahverengi normal, isli veya yağlı uç arıza işaretidir.',
    ],
    mistake:
      'Dizel motorda da buji olduğunu sanmak; dizel sıkıştırmayla ateşler, kızdırma bujisi yalnızca soğuk ilk çalıştırmaya yardım eder.',
  },
  {
    id: 'car-key',
    name: 'Anahtar & İmmobilizer',
    system: 'kabin',
    desc: 'Aracı açıp çalıştırır; içindeki immobilizer çipi tanınmayan anahtarla motorun çalışmasını engeller.',
    tip: 'Yedek anahtarı araçta değil evde sakla; kumanda menzili kısalmaya başladıysa pili değiştir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'car-key',
    inspection: [
      'Uzaktan kumandanın kilitleme ve açma menzilini test et.',
      'Anahtar içindeki mekanik gizli anahtarın yerini ve kapıyı nasıl açtığını öğren.',
      'Yedek anahtarın çalıştığını ara sıra dene.',
    ],
    mistake:
      'Anahtar dönmeyince aküden şüphelenmek; direksiyon kilidi geçmişse anahtarı çevirirken direksiyon hafifçe oynatılmalıdır.',
  },
  {
    id: 'obd-port',
    name: 'OBD Arıza Soketi',
    system: 'kabin',
    desc: 'Arıza tespit cihazının bağlandığı, motor ve sistem hata kodlarının okunduğu standart sokettir.',
    tip: 'Genellikle direksiyonun altındaki panelde bulunur; motor arıza lambası yandığında kodlar buradan okunur.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'obd-port',
    inspection: [
      'Direksiyon altı paneline bakarak 16 pinli soketin yerini öğren.',
      'Soket kapağının ve pinlerinin hasarsız olduğunu kontrol et.',
      'Arıza lambası yanıyorsa cihaz bağlatıp kodu sildirmeden önce not ettir.',
    ],
    mistake:
      'Hata kodunu sildirmenin arızayı giderdiğini sanmak; neden çözülmezse lamba yeniden yanar.',
  },
  {
    id: 'tow-rope',
    name: 'Çekme Halatı',
    system: 'muayene',
    desc: 'Arızalanan aracı kısa mesafede başka bir araçla çekmek için kullanılan dayanıklı halattır.',
    tip: 'Çekilen araçta kontak açık kalmalı; motor çalışmadığında fren ve direksiyon desteği zayıflar, pedala daha fazla kuvvet gerekir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'tow-rope',
    inspection: [
      'Halatın kopma yükünün araç ağırlığına uygun ve uyarı bezinin/bayrağının takılı olduğunu kontrol et.',
      'Her iki araçta çeki kancası noktasını bul; gerekiyorsa tampondaki vidalı kancayı yerine tak.',
      'Sürücüler işaretleşmeyi kararlaştırsın; çeken araç ani gaz ve fren yapmadan yavaşça kalksın.',
    ],
    mistake:
      'Halatı tampona veya taşıyıcı olmayan bir noktaya bağlamak; yalnızca araçtaki çeki kancası kullanılmalıdır.',
  },
  {
    id: 'wheel-chock',
    name: 'Takoz',
    system: 'muayene',
    desc: 'Park hâlindeki veya krikoyla kaldırılan aracın tekerleğinin yuvarlanmasını engeller.',
    tip: 'Rampada takoz, tekerin iniş yönündeki tarafına yani aracın kayabileceği yöne yerleştirilir.',
    relatedLessonSlug: 'debriyaj-rampa',
    photo: 'wheel-chock',
    inspection: [
      'El frenini çek; inişte geri, yokuşta birinci vitesi tak.',
      'Eğime bakarak aracın hangi yöne kayabileceğini belirle.',
      'Takozu tekerin iniş yönündeki yüzüne sıkıca daya.',
    ],
    mistake:
      'Takozu tekerin yokuş yukarı tarafına koymak; araç iniş yönüne kayacağı için takoz işe yaramaz.',
  },
  {
    id: 'snow-chain-fitting',
    name: 'Zincir Takma',
    system: 'dis',
    desc: 'Karlı ve buzlu yolda lastiğin tutunmasını artıran zincirlerin doğru biçimde takılması işlemidir.',
    tip: 'Zincir çekişli aksın lastiklerine takılır; önden çekişli araçta ön tekerleklere.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'snow-chain-fitting',
    inspection: [
      'Aracı düz ve güvenli bir yere çek, dörtlü flaşörü yak.',
      'Zinciri çekişli akstaki lastiğe eşit biçimde yerleştirip gergi kilidini kapat.',
      'Kısa bir mesafe ilerledikten sonra durup zinciri yeniden ger.',
    ],
    mistake:
      'Zincirle kuru asfaltta veya yüksek hızda gitmek; hem zincir hem lastik zarar görür, genellikle 50 km/s sınırı önerilir.',
  },
  {
    id: 'alloy-wheel',
    name: 'Jant & Sibop',
    system: 'dis',
    desc: 'Jant lastiği taşır; sibop ise lastiğe hava basılan ve basıncı içeride tutan valftir.',
    tip: 'Sibop kapağını daima takılı tut; toz ve nem valfi bozarak yavaş hava kaçağına neden olur.',
    relatedLessonSlug: 'motor-temel',
    photo: 'alloy-wheel',
    inspection: [
      'Jant yüzeyinde çatlak, eğilme ve kaldırım çarpması izi ara.',
      'Sibop kapaklarının takılı olduğunu kontrol et.',
      'Sibop çevresine sabunlu su sürerek kabarcıkla hava kaçağı testi yap.',
    ],
    mistake:
      'Kaldırıma sürtmeyi önemsememek; deforme olan jant balans bozukluğuna ve hava kaçağına yol açar.',
  },
  {
    id: 'tyre-pressure',
    name: 'Lastik Basıncı Ölçümü',
    system: 'muayene',
    desc: 'Lastik havasının üreticinin belirttiği değere göre ölçülüp ayarlanması işlemidir.',
    tip: 'Basınç soğuk lastikte ölçülür; doğru değer kapı sövesindeki veya yakıt kapağındaki etikette yazar.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'tyre-pressure',
    inspection: [
      'Araç en az birkaç saat durmuşken, lastikler soğukken ölçüm yap.',
      'Kapı sövesindeki etiketten yük durumuna uygun basınç değerini oku.',
      'Manometreyle ölç; gerekirse hava ekleyip sibop kapağını geri tak.',
      'Aynı seansta stepnenin basıncını da kontrol et.',
    ],
    mistake:
      'Uzun yol dönüşünde sıcak lastikte ölçüp basıncı düşürmek; ısınan lastik doğal olarak daha yüksek değer gösterir.',
  },
  {
    id: 'tie-rod',
    name: 'Rot Başı',
    system: 'dis',
    desc: 'Direksiyon hareketini tekerleğe ileten mafsallı bağlantıdır; aşınırsa direksiyonda boşluk oluşur.',
    tip: 'Direksiyon boşluğu, düz yolda tek tarafa çekme veya lastik omzunda düzensiz aşınma rot arızasının işaretidir.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'tie-rod',
    inspection: [
      'Motor kapalıyken direksiyonu sağa sola hafifçe oynat; tekerleğe geçmeyen boşluk olup olmadığını hisset.',
      'Düz yolda aracın tek tarafa çekip çekmediğini gözle.',
      'Lastiğin iç ve dış omzundaki düzensiz aşınmayı kontrol et.',
    ],
    mistake:
      'Rot ayarı ile rot başı değişimini karıştırmak; aşınmış rot başı ayarla düzelmez, parçanın değişmesi gerekir.',
  },
  {
    id: 'cv-axle',
    name: 'Aks Körüğü',
    system: 'dis',
    desc: 'Aks mafsalını saran lastik körüktür; içindeki gresi tutar, su ve tozu dışarıda bırakır.',
    tip: 'Direksiyon tam kırıkken manevrada gelen düzenli tık tık sesi çoğu zaman körüğü yırtılmış aks mafsalındandır.',
    relatedLessonSlug: 'park-manevra',
    photo: 'cv-axle',
    inspection: [
      'Tekerleğin arkasındaki körükte yırtık ve gres sızıntısı ara.',
      'Körük kelepçelerinin yerinde ve sıkı olduğuna bak.',
      'Direksiyon tam kırık hâlde yavaşça ilerleyip düzenli tıkırtı olup olmadığını dinle.',
    ],
    mistake:
      'Yırtık körüğü ertelemek; gres kaçar, mafsala pislik dolar ve küçük bir onarım aks değişimine dönüşür.',
  },
  {
    id: 'catalytic',
    name: 'Katalitik Konvertör',
    system: 'dis',
    desc: 'Egzoz gazındaki zararlı bileşenleri kimyasal tepkimeyle daha az zararlı gazlara dönüştürür.',
    tip: 'Çalışma sıcaklığı çok yüksektir; kuru ot veya saman üzerine park etmek yangın riski oluşturur.',
    relatedLessonSlug: 'motor-temel',
    photo: 'catalytic',
    inspection: [
      'Araç altında katalizör gövdesinde ezik ve darbe izi ara.',
      'İçeriden gelen metalik çıngırtıyı dinle; kırılmış petek işareti olabilir.',
      'Egzoz emisyon değerlerinin muayenede sınırlar içinde kaldığını takip et.',
    ],
    mistake:
      'Arızalı katalizörü söktürüp boş boru taktırmak; emisyonu bozar ve araç muayeneden geçemez.',
  },
  {
    id: 'park-sensor',
    name: 'Park Sensörü',
    system: 'dis',
    desc: 'Tamponlardaki ultrasonik sensörlerle engel mesafesini ölçüp sesli ve görsel uyarı verir.',
    tip: 'Sensör alçak bordürü, ince direği veya çukuru algılamayabilir; manevrada ayna ve omuz kontrolünü sürdür.',
    relatedLessonSlug: 'park-manevra',
    photo: 'park-sensor',
    inspection: [
      'Tampondaki sensör yüzeylerini temizle; çamur ve kar ölçümü bozar.',
      'Geri vitese alınca sistemin kendini tanıtan bip sesini doğrula.',
      'Bir engele yavaşça yaklaşıp uyarı sıklığının arttığını test et.',
    ],
    mistake:
      'Manevrayı tamamen sensöre bırakmak; sensör her engeli algılamaz, sorumluluk sürücüdedir.',
  },
  {
    id: 'rear-camera',
    name: 'Geri Görüş Kamerası',
    system: 'dis',
    desc: 'Geri viteste aracın arkasını ekrana yansıtarak görüşü destekler.',
    tip: 'Kılavuz çizgileri mesafe için referanstır; dönerken yanlardan yaklaşanlar için aynalara bakmayı sürdür.',
    relatedLessonSlug: 'park-manevra',
    photo: 'rear-camera',
    inspection: [
      'Kamera lensini yumuşak bezle temizle; kir ve su damlası görüntüyü bozar.',
      'Geri vitese alınca görüntünün gecikmesiz geldiğini doğrula.',
      'Kılavuz çizgilerinin gerçek mesafeyle uyumunu sabit bir engelle test et.',
    ],
    mistake:
      'Yalnızca ekrana bakarak geri gitmek; kameranın görüş açısı sınırlıdır ve yanlardan gelenleri göstermez.',
  },
  {
    id: 'windshield-chip',
    name: 'Cam Çatlağı',
    system: 'dis',
    desc: 'Ön cama taş çarpmasıyla oluşan, büyümeden onarılması gereken görüş ve dayanım hasarıdır.',
    tip: 'Küçük taş izi reçineyle onarılabilir; ani sıcaklık farkı ve titreşim izi boydan boya çatlağa büyütür.',
    relatedLessonSlug: 'arac-hazirlik',
    photo: 'windshield-chip',
    inspection: [
      'Camı temizleyip taş izi ve kılcal çatlak olup olmadığını kontrol et.',
      'Hasarın sürücünün görüş alanında olup olmadığına bak.',
      'Küçük izi şeffaf bantla tozdan koru ve vakit kaybetmeden onarıma götür.',
    ],
    mistake:
      'Küçük taş izini önemsememek; soğuk camda kalorifer açılınca iz bir anda büyük çatlağa dönüşebilir.',
  },
  {
    id: 'oil-cap',
    name: 'Yağ Dolum Kapağı',
    system: 'motor-bolmesi',
    desc: 'Motora yağ eklenen ağzı kapatır; üzerinde genellikle uygun yağ standardı yazar.',
    tip: 'Kapağın iç yüzeyinde mayonez kıvamında birikinti görürsen yağa su karışıyor olabilir; servise danış.',
    relatedLessonSlug: 'motor-temel',
    photo: 'oil-cap',
    inspection: [
      'Motor kapalı ve soğukken kapağı açıp iç yüzeyine bak.',
      'Yağ eklerken huni kullan; sıcak parçalara taşan yağ duman yapar.',
      'Kapağı sonuna kadar sıkıp çevresinde kaçak olmadığını kontrol et.',
    ],
    mistake:
      'Yağ seviyesini dolum ağzından bakarak anlamaya çalışmak; seviye yalnızca yağ çubuğundan okunur.',
  },
  {
    id: 'temp-gauge',
    name: 'Hararet Göstergesi',
    system: 'kabin',
    desc: 'Motor soğutma suyu sıcaklığını gösterir; normalde ibre orta bölgede seyreder.',
    tip: 'İbre kırmızıya yaklaşırsa kaloriferi sonuna kadar açıp güvenli bir yerde dur; sıcak motorda radyatör kapağını açma.',
    relatedLessonSlug: 'gosterge-ikaz',
    photo: 'temp-gauge',
    inspection: [
      'Kontak açıldığında göstergenin tepki verdiğini gözle.',
      'Seyir hâlinde ibrenin orta bölgede sabitlendiğini kontrol et.',
      'İbre yükseliyorsa kaloriferi aç, güvenli yerde dur ve motoru soğumaya bırak.',
    ],
    mistake:
      'Hararet yapan motora hemen soğuk su dökmek; ani sıcaklık farkı silindir kapağını çatlatabilir.',
  },
  {
    id: 'jump-cables',
    name: 'Takviye Kablosu',
    system: 'muayene',
    desc: 'Boşalmış aküyü başka bir aracın aküsünden çalıştırmak için kullanılan kalın iletken kablolardır.',
    tip: 'Bağlantı sırası önemlidir: önce artı uçlar, sonra sağlam akünün eksisi, en son boş akülü araçta şase noktası.',
    relatedLessonSlug: 'motor-temel',
    photo: 'jump-cables',
    inspection: [
      'İki aracı birbirine değmeyecek şekilde yaklaştır ve kontakları kapat.',
      'Kırmızı kabloyu iki akünün artı kutbuna bağla.',
      'Siyah kabloyu sağlam akünün eksi kutbuna, diğer ucunu boş akülü araçta boyasız metal şaseye bağla.',
      'Önce sağlam aracı, sonra boş akülü aracı çalıştır; sökümü ters sırayla yap.',
    ],
    mistake:
      'Siyah kablonun son ucunu doğrudan boş akünün eksi kutbuna takmak; oluşan kıvılcım akü gazını tutuşturabilir.',
  },
  {
    id: 'fire-extinguisher',
    name: 'Yangın Söndürücü',
    system: 'muayene',
    desc: 'Araç yangınına ilk müdahale için bulundurulması zorunlu basınçlı söndürme tüpüdür.',
    tip: 'Sürücünün kolayca ulaşacağı yerde sabitlenmiş olmalı; söndürürken hedefin alevin kökü olduğunu unutma.',
    relatedLessonSlug: 'arac-hazirlik',
    inspection: [
      'Manometre ibresinin yeşil bölgede olduğunu kontrol et.',
      'Pimin ve mührün yerinde, tüpün yuvasına sabitlenmiş olduğuna bak.',
      'Dolum ve son kullanma tarihini kontrol et; süresi geçen tüpü yeniletmek gerekir.',
    ],
    mistake:
      'Motor yangınında kaputu sonuna kadar açmak; ani gelen oksijen alevi büyütür, kaput aralığından müdahale edilir.',
  },
  {
    id: 'warning-triangle-road',
    name: 'Üçgen Yerleşimi',
    system: 'muayene',
    desc: 'Arızalanan aracın gerisine konularak yaklaşan sürücüleri önceden uyaran reflektörlü işaretin doğru yerleştirilmesidir.',
    tip: 'Yerleşim yeri içinde en az 30 m geriye, otoyol gibi yüksek hızlı yollarda çok daha uzağa koy; viraj veya tepe varsa mesafeyi artır.',
    relatedLessonSlug: 'arac-hazirlik',
    inspection: [
      'Dörtlü flaşörü yak ve aracı olabildiğince sağa çek.',
      'Yola inmeden önce reflektif yeleği giy.',
      'Üçgeni trafiğin geldiği yönde, yerleşim içinde en az 30 m geriye yerleştir.',
      'Bölünmüş yolda gerekiyorsa ikinci üçgeni kullan ve aracın güvenli tarafında bekle.',
    ],
    mistake:
      'Üçgeni aracın hemen arkasına koymak; yaklaşan sürücüye tepki mesafesi bırakmadığı için işlevsiz kalır.',
  },
  {
    id: 'child-lock',
    name: 'Çocuk Kilidi',
    system: 'kabin',
    desc: 'Arka kapıların içeriden açılmasını engelleyen mekanik kilittir; kapı yalnızca dışarıdan açılabilir.',
    tip: 'Yalnızca arka kapılarda bulunur; kapı kenarındaki küçük mandal veya vida yuvasıyla etkinleştirilir.',
    relatedLessonSlug: 'arac-hazirlik',
    inspection: [
      'Arka kapıyı açıp kilit mekanizması yanındaki çocuk kilidi mandalını bul.',
      'Mandalı kilit konumuna alıp kapıyı kapat.',
      'İçeriden kola çekildiğinde kapının açılmadığını, dışarıdan açıldığını doğrula.',
    ],
    mistake:
      'Çocuk kilidini merkezi kilitle karıştırmak; çocuk kilidi devredeyken kilitler açık olsa bile kapı içeriden açılamaz.',
  },
];

/** Çizimli temel parçaların premium fotoğraf eşlemesi (kimlik farklıysa belirt). */
const BASE_PHOTO: Record<string, string> = {
  lights: 'light-switch',
  wrench: 'wheel-bolts',
};

export const VEHICLE_PARTS: VehiclePart[] = [
  ...BASE_PARTS.map((p) => ({ ...p, photo: BASE_PHOTO[p.id] ?? p.id })),
  ...EXTRA_PARTS,
  ...PHASE7_PARTS,
];

export function partsBySystem(): Record<VehicleSystem, VehiclePart[]> {
  const out = {
    'motor-bolmesi': [] as VehiclePart[],
    kabin: [] as VehiclePart[],
    dis: [] as VehiclePart[],
    muayene: [] as VehiclePart[],
  };
  for (const p of VEHICLE_PARTS) out[p.system].push(p);
  return out;
}

export function vehiclePartById(id: string): VehiclePart | undefined {
  return VEHICLE_PARTS.find((p) => p.id === id);
}
