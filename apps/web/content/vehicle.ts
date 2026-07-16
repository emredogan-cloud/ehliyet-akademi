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

/** Çizimli temel parçaların premium fotoğraf eşlemesi (kimlik farklıysa belirt). */
const BASE_PHOTO: Record<string, string> = {
  lights: 'light-switch',
  wrench: 'wheel-bolts',
};

export const VEHICLE_PARTS: VehiclePart[] = [
  ...BASE_PARTS.map((p) => ({ ...p, photo: BASE_PHOTO[p.id] ?? p.id })),
  ...EXTRA_PARTS,
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
