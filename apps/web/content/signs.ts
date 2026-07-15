/**
 * Trafik işaretleri kataloğu (Program 1 · Görsel Dönüşüm Bölüm 1). ÖZGÜN eğitimsel sunum.
 * Standart şekil/renk (serbest) kullanılır; çizim dili kendimize aittir (telif-güvenli).
 * Her işaret: resmî anlam + hafıza tekniği + sınav önemi + sık hata + ilgili ders.
 */

export type SignCategory =
  'tehlike' | 'yasak' | 'mecburiyet' | 'bilgi' | 'park' | 'otoyol' | 'gecici' | 'oncelik';

export type SignShape =
  | 'triangle'
  | 'inv-triangle'
  | 'ring'
  | 'disc'
  | 'rect-blue'
  | 'rect-green'
  | 'octagon'
  | 'diamond';

export const CATEGORY_LABEL: Record<SignCategory, string> = {
  tehlike: 'Tehlike Uyarı',
  yasak: 'Yasaklayıcı / Kısıtlayıcı',
  mecburiyet: 'Mecburiyet',
  bilgi: 'Bilgi',
  park: 'Duraklama & Park',
  otoyol: 'Otoyol & Yönlendirme',
  gecici: 'Geçici / Çalışma',
  oncelik: 'Öncelik (DUR / Yol Ver)',
};

export type ExamImportance = 'çok yüksek' | 'yüksek' | 'orta';

export interface TrafficSign {
  id: string;
  category: SignCategory;
  name: string;
  shape: SignShape;
  glyph?: string;
  glyphText?: string;
  meaning: string;
  memoryTip: string;
  examImportance: ExamImportance;
  commonMistake?: string;
  relatedLessonSlug?: string;
  keywords: string[];
}

export const SIGNS: TrafficSign[] = [
  // ——— TEHLİKE UYARI (üçgen, kırmızı kenar) ———
  {
    id: 'kaygan-yol',
    category: 'tehlike',
    name: 'Kaygan Yol',
    shape: 'triangle',
    glyph: 'slippery',
    meaning: 'İleride zemin kaygandır; kaymaya karşı hız düşürülür ve ani manevradan kaçınılır.',
    memoryTip: 'Üçgen = dikkat; kayan araç sembolü = zemin kaygan.',
    examImportance: 'yüksek',
    commonMistake: 'Kuru havada da olsa hızı korumak.',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['kaygan', 'buz', 'yagmur', 'kayma'],
  },
  {
    id: 'tehlikeli-viraj-sol',
    category: 'tehlike',
    name: 'Sola Tehlikeli Viraj',
    shape: 'triangle',
    glyph: 'curveLeft',
    meaning: 'İleride sola keskin viraj vardır; hız düşürülür.',
    memoryTip: 'Okun büküldüğü yön = virajın yönü.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['viraj', 'sol', 'donemec'],
  },
  {
    id: 'tehlikeli-viraj-sag',
    category: 'tehlike',
    name: 'Sağa Tehlikeli Viraj',
    shape: 'triangle',
    glyph: 'curveRight',
    meaning: 'İleride sağa keskin viraj vardır; hız düşürülür.',
    memoryTip: 'Okun büküldüğü yön = virajın yönü.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['viraj', 'sag', 'donemec'],
  },
  {
    id: 'devamli-viraj',
    category: 'tehlike',
    name: 'Devamlı Virajlar',
    shape: 'triangle',
    glyph: 'sCurve',
    meaning: 'Birbirini izleyen virajlar vardır; sürekli dikkat ve düşük hız gerekir.',
    memoryTip: 'S çizgisi = arka arkaya viraj.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['viraj', 'devamli', 's'],
  },
  {
    id: 'tumsek',
    category: 'tehlike',
    name: 'Tümsek',
    shape: 'triangle',
    glyph: 'bump',
    meaning: 'Yol yüzeyinde tümsek vardır; hız düşürülür.',
    memoryTip: 'Kambur çizgi = yol kabarması.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['tumsek', 'kasis'],
  },
  {
    id: 'yaya-geciti-tehlike',
    category: 'tehlike',
    name: 'Yaya Geçidi (yaklaşım)',
    shape: 'triangle',
    glyph: 'pedestrian',
    meaning: 'İleride yaya geçidi vardır; yavaşla, yayaya öncelik ver.',
    memoryTip: 'Üçgen içinde yürüyen figür = geçit yaklaşıyor.',
    examImportance: 'çok yüksek',
    commonMistake: 'Yaya geçidinde yayaya yol vermemek.',
    relatedLessonSlug: 'yaya-gecidi',
    keywords: ['yaya', 'gecit', 'oncelik'],
  },
  {
    id: 'okul-gecidi',
    category: 'tehlike',
    name: 'Okul Geçidi / Çocuklar',
    shape: 'triangle',
    glyph: 'children',
    meaning: 'İleride okul/çocukların bulunduğu bölge vardır; çok yavaş ve dikkatli sürülür.',
    memoryTip: 'İki çocuk figürü = okul bölgesi.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'yaya-gecidi',
    keywords: ['okul', 'cocuk'],
  },
  {
    id: 'ehli-hayvan',
    category: 'tehlike',
    name: 'Ehli Hayvan Çıkabilir',
    shape: 'triangle',
    glyph: 'animal',
    meaning: 'Yola evcil/çiftlik hayvanı çıkabilir; hız düşürülür.',
    memoryTip: 'Hayvan silüeti = ani çıkış riski.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['hayvan', 'ciftlik'],
  },
  {
    id: 'donel-kavsak-yaklasim',
    category: 'tehlike',
    name: 'Dönel Kavşak (yaklaşım)',
    shape: 'triangle',
    glyph: 'roundabout',
    meaning: 'İleride dönel kavşak vardır; yavaşla, içerideki araca yol ver.',
    memoryTip: 'Dairesel oklar = ada etrafında dönüş.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-uygulama',
    keywords: ['donel', 'kavsak', 'ada'],
  },
  {
    id: 'yol-daralmasi',
    category: 'tehlike',
    name: 'Yol Daralması',
    shape: 'triangle',
    glyph: 'narrow',
    meaning: 'Yol ileride daralır; hız ayarlanır, karşıdan gelene dikkat edilir.',
    memoryTip: 'İçe kapanan çizgiler = daralma.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['daralma', 'dar'],
  },
  {
    id: 'iki-yonlu-trafik',
    category: 'tehlike',
    name: 'İki Yönlü Trafik',
    shape: 'triangle',
    glyph: 'twoway',
    meaning: 'İleride karşılıklı iki yönlü trafik başlar; sollama ve mesafede dikkat.',
    memoryTip: 'Zıt iki ok = karşılıklı akış.',
    examImportance: 'orta',
    relatedLessonSlug: 'sollama-serit',
    keywords: ['iki-yonlu', 'karsi'],
  },
  {
    id: 'isikli-isaret-yaklasim',
    category: 'tehlike',
    name: 'Işıklı İşaret Cihazı',
    shape: 'triangle',
    glyph: 'light',
    meaning: 'İleride trafik ışıkları vardır; yaklaşırken hazır ol.',
    memoryTip: 'Üç renkli kutu = trafik lambası.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['isik', 'lamba', 'trafik-isigi'],
  },
  {
    id: 'egimli-inis',
    category: 'tehlike',
    name: 'Tehlikeli Eğim (iniş)',
    shape: 'triangle',
    glyph: 'hillDown',
    meaning: 'Dik iniş vardır; motor freninden yararlan, hızı kontrol et.',
    memoryTip: 'Aşağı inen yokuş = iniş eğimi.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['egim', 'inis', 'yokus'],
  },
  {
    id: 'hemzemin-gecit',
    category: 'tehlike',
    name: 'Demiryolu Hemzemin Geçit',
    shape: 'triangle',
    glyph: 'levelCross',
    meaning: 'Bariyersiz/bariyerli tren geçidi yaklaşır; dur-bak-dinle, tren varsa geçme.',
    memoryTip: 'Ray + bariyer çizgisi = tren geçidi.',
    examImportance: 'yüksek',
    commonMistake: 'Bariyer inerken geçmeye çalışmak.',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['tren', 'demiryolu', 'hemzemin', 'bariyer'],
  },

  // ——— YASAKLAYICI / KISITLAYICI (kırmızı çember) ———
  {
    id: 'azami-hiz-20',
    category: 'yasak',
    name: 'Azami Hız 20',
    shape: 'ring',
    glyphText: '20',
    meaning: 'Bu kesimde en yüksek hız 20 km/saattir.',
    memoryTip: 'Kırmızı çember + rakam = üst hız sınırı.',
    examImportance: 'çok yüksek',
    relatedLessonSlug: 'hiz-takip',
    keywords: ['hiz', 'azami', '20'],
  },
  {
    id: 'azami-hiz-30',
    category: 'yasak',
    name: 'Azami Hız 30',
    shape: 'ring',
    glyphText: '30',
    meaning: 'Bu kesimde en yüksek hız 30 km/saattir (genelde okul/yerleşim içi).',
    memoryTip: 'Kırmızı çember + rakam = üst hız sınırı.',
    examImportance: 'çok yüksek',
    relatedLessonSlug: 'hiz-takip',
    keywords: ['hiz', 'azami', '30', 'okul'],
  },
  {
    id: 'azami-hiz-50',
    category: 'yasak',
    name: 'Azami Hız 50',
    shape: 'ring',
    glyphText: '50',
    meaning: 'Bu kesimde en yüksek hız 50 km/saattir (yerleşim içi genel sınır).',
    memoryTip: 'Levha varsa levha, yoksa yerleşim içi 50.',
    examImportance: 'çok yüksek',
    commonMistake: 'Levha değeri ile genel sınırı karıştırmak.',
    relatedLessonSlug: 'hiz-takip',
    keywords: ['hiz', 'azami', '50', 'sehir'],
  },
  {
    id: 'azami-hiz-70',
    category: 'yasak',
    name: 'Azami Hız 70',
    shape: 'ring',
    glyphText: '70',
    meaning: 'Bu kesimde en yüksek hız 70 km/saattir.',
    memoryTip: 'Kırmızı çember + rakam = üst hız sınırı.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'hiz-takip',
    keywords: ['hiz', 'azami', '70'],
  },
  {
    id: 'sollama-yasak',
    category: 'yasak',
    name: 'Sollama Yasağı',
    shape: 'ring',
    glyph: 'twoCars',
    meaning: 'Bu kesimde öndeki aracı sollamak yasaktır.',
    memoryTip: 'İki araç + kırmızı = geçme yok.',
    examImportance: 'çok yüksek',
    commonMistake: 'Yasağın bittiği yeri gözden kaçırmak.',
    relatedLessonSlug: 'sollama-serit',
    keywords: ['sollama', 'gecme', 'yasak'],
  },
  {
    id: 'donus-yasak-sol',
    category: 'yasak',
    name: 'Sola Dönülmez',
    shape: 'ring',
    glyph: 'arrowLeft',
    meaning: 'Bu kavşakta sola dönüş yasaktır.',
    memoryTip: 'Kırmızı çember + sol ok = sola dönme.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['donus', 'sol', 'yasak'],
  },
  {
    id: 'donus-yasak-sag',
    category: 'yasak',
    name: 'Sağa Dönülmez',
    shape: 'ring',
    glyph: 'arrowRight',
    meaning: 'Bu kavşakta sağa dönüş yasaktır.',
    memoryTip: 'Kırmızı çember + sağ ok = sağa dönme.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['donus', 'sag', 'yasak'],
  },
  {
    id: 'tasit-giremez',
    category: 'yasak',
    name: 'Taşıt Trafiğine Kapalı',
    shape: 'ring',
    glyph: 'noStop',
    meaning: 'Bu yola taşıt giremez.',
    memoryTip: 'Boş kırmızı çember = araç girişi kapalı.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['giremez', 'kapali', 'tasit'],
  },
  {
    id: 'bisiklet-giremez',
    category: 'yasak',
    name: 'Bisiklet Giremez',
    shape: 'ring',
    glyph: 'bike',
    meaning: 'Bu yola bisiklet giremez.',
    memoryTip: 'Bisiklet + kırmızı = giriş yok.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['bisiklet', 'giremez'],
  },
  {
    id: 'otomobil-giremez',
    category: 'yasak',
    name: 'Otomobil Giremez',
    shape: 'ring',
    glyph: 'car',
    meaning: 'Bu yola otomobil giremez.',
    memoryTip: 'Otomobil + kırmızı = giriş yok.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['otomobil', 'giremez'],
  },

  // ——— MECBURİYET (mavi daire) ———
  {
    id: 'ileri-mecburi',
    category: 'mecburiyet',
    name: 'İleri Mecburi Yön',
    shape: 'disc',
    glyph: 'arrowStraight',
    meaning: 'Sadece ileri gidilebilir.',
    memoryTip: 'Mavi daire + ok = zorunlu yön.',
    examImportance: 'yüksek',
    commonMistake: 'Mavi (zorunlu) ile kırmızıyı (yasak) karıştırmak.',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['mecburi', 'ileri', 'yon'],
  },
  {
    id: 'saga-mecburi',
    category: 'mecburiyet',
    name: 'Sağa Mecburi Yön',
    shape: 'disc',
    glyph: 'arrowRight',
    meaning: 'Sadece sağa dönülebilir.',
    memoryTip: 'Mavi daire + sağ ok = zorunlu sağ.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['mecburi', 'sag', 'yon'],
  },
  {
    id: 'sola-mecburi',
    category: 'mecburiyet',
    name: 'Sola Mecburi Yön',
    shape: 'disc',
    glyph: 'arrowLeft',
    meaning: 'Sadece sola dönülebilir.',
    memoryTip: 'Mavi daire + sol ok = zorunlu sol.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['mecburi', 'sol', 'yon'],
  },
  {
    id: 'donel-mecburi',
    category: 'mecburiyet',
    name: 'Ada Etrafında Dönünüz',
    shape: 'disc',
    glyph: 'roundabout',
    meaning: 'Dönel kavşakta ada etrafında belirtilen yönde dönülür.',
    memoryTip: 'Mavi daire + dönme okları = ada etrafı.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-uygulama',
    keywords: ['donel', 'ada', 'mecburi'],
  },
  {
    id: 'bisiklet-yolu',
    category: 'mecburiyet',
    name: 'Bisiklet Yolu',
    shape: 'disc',
    glyph: 'bike',
    meaning: 'Bu yol bisikletlilere ayrılmıştır.',
    memoryTip: 'Mavi daire + bisiklet = bisiklet yolu.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['bisiklet', 'yol'],
  },

  // ——— BİLGİ (mavi dikdörtgen) ———
  {
    id: 'hastane',
    category: 'bilgi',
    name: 'Hastane',
    shape: 'rect-blue',
    glyph: 'hospital',
    meaning: 'Yakında hastane vardır; gürültüden kaçın, dikkatli sür.',
    memoryTip: 'Mavi zemin + artı = sağlık/hastane.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['hastane', 'saglik'],
  },
  {
    id: 'yaya-gecidi-bilgi',
    category: 'bilgi',
    name: 'Yaya Geçidi (bilgi)',
    shape: 'rect-blue',
    glyph: 'pedestrian',
    meaning: 'Burada yaya geçidi bulunur; yayaya öncelik ver.',
    memoryTip: 'Mavi kare + yürüyen = geçit yeri.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'yaya-gecidi',
    keywords: ['yaya', 'gecit', 'bilgi'],
  },
  {
    id: 'park-yeri-bilgi',
    category: 'bilgi',
    name: 'Park Yeri',
    shape: 'rect-blue',
    glyph: 'parkingP',
    meaning: 'Burada park etmek serbesttir.',
    memoryTip: 'Mavi + P = park izni.',
    examImportance: 'orta',
    relatedLessonSlug: 'park-manevra',
    keywords: ['park', 'p', 'yer'],
  },

  // ——— DURAKLAMA & PARK ———
  {
    id: 'park-serbest',
    category: 'park',
    name: 'Park Serbest (P)',
    shape: 'rect-blue',
    glyph: 'parkingP',
    meaning: 'Belirtilen alanda park etmek serbesttir.',
    memoryTip: 'Mavi P = izin.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'park-manevra',
    keywords: ['park', 'serbest', 'p'],
  },
  {
    id: 'park-yasak',
    category: 'park',
    name: 'Parketmek Yasaktır',
    shape: 'ring',
    glyph: 'parkingP',
    meaning: 'Bu kesimde park etmek yasaktır (duraklama olabilir).',
    memoryTip: 'Kırmızı çember + P = park yasak.',
    examImportance: 'yüksek',
    commonMistake: 'Park ile duraklama yasağını karıştırmak.',
    relatedLessonSlug: 'park-manevra',
    keywords: ['park', 'yasak'],
  },
  {
    id: 'duraklama-yasak',
    category: 'park',
    name: 'Duraklamak Yasaktır',
    shape: 'ring',
    glyph: 'cross',
    meaning: 'Bu kesimde duraklamak da park etmek de yasaktır.',
    memoryTip: 'Çapraz X = hiç durma.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'park-manevra',
    keywords: ['duraklama', 'yasak'],
  },

  // ——— OTOYOL & YÖNLENDİRME ———
  {
    id: 'otoyol-baslangic',
    category: 'otoyol',
    name: 'Otoyol Başlangıcı',
    shape: 'rect-green',
    glyph: 'arrowStraight',
    meaning: 'Otoyol başlar; asgari/azami hız ve otoyol kuralları geçerli olur.',
    memoryTip: 'Yeşil zemin = otoyol.',
    examImportance: 'orta',
    relatedLessonSlug: 'hiz-takip',
    keywords: ['otoyol', 'yesil'],
  },
  {
    id: 'devlet-yolu',
    category: 'otoyol',
    name: 'Devlet Yolu Yönlendirme',
    shape: 'rect-blue',
    glyph: 'arrowStraight',
    meaning: 'Devlet yolu yön/mesafe bilgisi verir.',
    memoryTip: 'Mavi zemin = devlet yolu yönlendirme.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['devlet-yolu', 'yon', 'mavi'],
  },

  // ——— GEÇİCİ / ÇALIŞMA (sarı zemin — burada üçgen ile stilize) ———
  {
    id: 'yol-calismasi',
    category: 'gecici',
    name: 'Yolda Çalışma',
    shape: 'triangle',
    glyph: 'digger',
    meaning:
      'İleride yol çalışması vardır (gerçek levha sarı zeminlidir); yavaşla, işçilere dikkat.',
    memoryTip: 'Sarı zemin = geçici durum; kürek/iş makinesi = çalışma.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['calisma', 'yol', 'gecici', 'sari'],
  },
  {
    id: 'gevsek-malzeme',
    category: 'gecici',
    name: 'Gevşek Malzeme',
    shape: 'triangle',
    glyph: 'exclam',
    meaning: 'Yolda gevşek mıcır/malzeme vardır; hız düşür, takip mesafesini artır.',
    memoryTip: 'Geçici uyarı = dikkat + yavaşla.',
    examImportance: 'orta',
    relatedLessonSlug: 'trafik-isaretleri',
    keywords: ['gevsek', 'micir', 'malzeme'],
  },

  // ——— ÖNCELİK (özel şekiller) ———
  {
    id: 'dur',
    category: 'oncelik',
    name: 'DUR',
    shape: 'octagon',
    meaning: 'Araç durma çizgisinden önce TAM durur ve geçiş üstünlüğü olana yol verir.',
    memoryTip: 'Sekizgen = sadece DUR bu şekle sahiptir.',
    examImportance: 'çok yüksek',
    commonMistake: 'Yavaşlayıp durmadan geçmek.',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['dur', 'stop', 'tam-dur'],
  },
  {
    id: 'yol-ver',
    category: 'oncelik',
    name: 'Yol Ver',
    shape: 'inv-triangle',
    meaning: 'Geçiş üstünlüğü olan trafiğe yol verilir; gerekirse durulur.',
    memoryTip: 'Ters üçgen = yol ver (benzersiz şekil).',
    examImportance: 'çok yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['yol-ver', 'oncelik'],
  },
  {
    id: 'ana-yol',
    category: 'oncelik',
    name: 'Ana Yol',
    shape: 'diamond',
    meaning: 'Bulunduğun yol ana yoldur; tali yoldan çıkanlar sana yol verir.',
    memoryTip: 'Sarı eşkenar dörtgen = ana yol.',
    examImportance: 'yüksek',
    relatedLessonSlug: 'kavsak-oncelik',
    keywords: ['ana-yol', 'oncelik', 'tali'],
  },
];

/* ---- yardımcılar (saf, test edilebilir) ---- */

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

export function filterSigns(query: string, category: SignCategory | 'all'): TrafficSign[] {
  const q = norm(query.trim());
  return SIGNS.filter((s) => {
    if (category !== 'all' && s.category !== category) return false;
    if (!q) return true;
    const hay = norm(s.name + ' ' + s.meaning + ' ' + s.keywords.join(' '));
    return hay.includes(q);
  });
}

export function signById(id: string): TrafficSign | undefined {
  return SIGNS.find((s) => s.id === id);
}

export function signsByCategory(): Record<SignCategory, number> {
  const out = {} as Record<SignCategory, number>;
  for (const s of SIGNS) out[s.category] = (out[s.category] ?? 0) + 1;
  return out;
}
