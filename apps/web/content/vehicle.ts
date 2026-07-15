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
}

export const VEHICLE_PARTS: VehiclePart[] = [
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
