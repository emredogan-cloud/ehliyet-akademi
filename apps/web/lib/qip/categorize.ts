/**
 * QIP — Faz 2 · Akıllı Sınıflandırma (BANK_QUESTİON Part 4).
 *
 * Her soruyu Part 4 taksonomisine göre bir TEMAYA (cross-cutting kategori) atar. Sinyal önceliği:
 * konu (topic) jetonları → etiketler (tags). Deterministik, sıralı kural listesi — İLK eşleşen tema
 * `primaryTheme` olur; tüm eşleşenler `themes[]`. Hiçbir özel tema eşleşmezse dersin (subject)
 * genel teması yedeğe düşer → %100 sınıflandırma, uzun kuyruk için dürüst yedek.
 */
import type { NormalizedQuestion, Subject } from '@ea/content-schema';

export interface Theme {
  id: string;
  label: string;
  /** Yalnız bu derslerde geçerli (verilmezse tüm dersler). */
  subjects?: Subject[];
  /** Konu/etiket jetonlarında aranan anahtarlar. Tireli anahtar = alt dizi; tek kelime = tam jeton. */
  match: string[];
}

/** Dersin genel (yedek) teması — hiçbir özel tema tutmazsa kullanılır. */
export const SUBJECT_FALLBACK_THEME: Record<Subject, Theme> = {
  trafik: { id: 'trafik-genel', label: 'Trafik Kuralları', match: [] },
  motor: { id: 'arac-genel', label: 'Araç Tekniği', match: [] },
  ilkyardim: { id: 'ilkyardim-genel', label: 'İlk Yardım Temelleri', match: [] },
  adab: { id: 'adab', label: 'Trafik Adabı ve Empati', match: [] },
  pratik: { id: 'direksiyon', label: 'Direksiyon Uygulaması', match: [] },
};

/**
 * Özel temalar — SIRA ÖNEMLİ (özgülden genele). Part 4 örnekleriyle hizalı.
 * Ders kapsamı (subjects) yanlış-pozitifi engeller (ör. "hiz-adabi" → Adab, "hiz" temasına düşmez).
 */
export const THEMES: Theme[] = [
  // — Trafik / kural temaları —
  {
    id: 'trafik-isaretleri',
    label: 'Trafik İşaretleri',
    match: ['levha', 'isaret', 'yon-levha', 'oklari', 'gorevli-isaret', 'yatay'],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'isikli-cihaz',
    label: 'Işıklı İşaret Cihazları',
    match: ['isikli-isaret', 'sari-isik', 'kirmizida', 'sari-cizgi', 'isik-ihlali'],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'hiz-mesafe',
    label: 'Hız ve Takip Mesafesi',
    match: ['hiz', 'takip-mesafesi', 'mesafe', 'guvenli-mesafe'],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'oncelik',
    label: 'Öncelik ve Geçiş Hakkı',
    match: ['oncelik', 'gecis-ustunlugu', 'gecis-hakki', 'yol-ver', 'yol-verme', 'hak-kavrami'],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'kavsak-serit',
    label: 'Kavşak ve Şerit',
    match: ['kavsak', 'serit', 'donel', 'sollama', 'donus', 'fermuar', 'refuj', 'seritler'],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'park-duraklama',
    label: 'Duraklama ve Park',
    match: ['park', 'duraklama'],
    subjects: ['trafik'],
  },
  {
    id: 'farlar',
    label: 'Farlar ve Aydınlatma',
    match: ['far', 'selektor', 'gece', 'aydinlatma', 'sis-lamba', 'gunduz-far', 'plaka-lambasi'],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'yaya-okul',
    label: 'Yaya, Okul ve Kırılgan Yol Kullanıcıları',
    match: [
      'yaya',
      'okul',
      'cocuk',
      'engelli',
      'yasli',
      'bisiklet',
      'motosiklet',
      'scooter',
      'hayvan',
    ],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'kis-hava',
    label: 'Kış ve Olumsuz Hava',
    match: [
      'kis',
      'buzlanma',
      'zincir',
      'sis',
      'yagmur',
      'kaygan',
      'aquaplaning',
      'olumsuz-hava',
      'gunes-kamasma',
      'islak',
      'su-birikintisi',
      'su-gecisi',
    ],
    subjects: ['trafik', 'pratik'],
  },
  {
    id: 'guvenlik-donanimi',
    label: 'Güvenlik Donanımı',
    match: [
      'emniyet-kemeri',
      'kemer',
      'airbag',
      'hava-yastigi',
      'koltuk',
      'bas-destegi',
      'kask',
      'cocuk-guvenligi',
      'guvenlik-sistemleri',
      'guvenlik-donanimi',
      'kafalik',
    ],
    subjects: ['trafik', 'motor'],
  },
  {
    id: 'cevre',
    label: 'Çevreci Sürüş',
    match: [
      'cevre',
      'emisyon',
      'yakit-tasarruf',
      'ekonomik',
      'egzoz',
      'katalitik',
      'atik',
      'hurda',
      'gereksiz-yuk',
      'siyah-duman',
      'gurultu',
    ],
  },
  {
    id: 'yasal',
    label: 'Yasal Sorumluluk',
    match: [
      'sorumluluk',
      'ceza',
      'puan',
      'sigorta',
      'belge',
      'muayene',
      'trafikten-men',
      'kaza-sorumluluk',
      'tutanak',
      'ehliyet',
      'yaptirimi',
      'zorunlu',
      'taniklik',
    ],
    subjects: ['trafik', 'adab'],
  },
  // — Araç tekniği (motor) temaları —
  {
    id: 'fren',
    label: 'Fren Sistemi',
    match: ['fren', 'abs'],
    subjects: ['motor'],
  },
  {
    id: 'lastik',
    label: 'Lastik ve Tekerlek',
    match: [
      'lastik',
      'tekerlek',
      'rot',
      'balans',
      'jant',
      'stepne',
      'amortisor',
      'suspansiyon',
      'rulman',
      'aks',
    ],
    subjects: ['motor'],
  },
  {
    id: 'yaglama-sogutma',
    label: 'Yağlama ve Soğutma',
    match: [
      'yaglama',
      'yag',
      'sogutma',
      'radyator',
      'antifriz',
      'termostat',
      'hararet',
      'sogutma-fani',
      'devirdaim',
      'genlesme',
      'polen-filtresi',
      'hava-filtresi',
      'yag-filtresi',
    ],
    subjects: ['motor'],
  },
  {
    id: 'elektrik-sarj',
    label: 'Elektrik ve Şarj',
    match: ['aku', 'elektrik', 'sarj', 'alternator', 'mars', 'atesleme', 'buji', 'obd'],
    subjects: ['motor'],
  },
  {
    id: 'yakit',
    label: 'Yakıt Sistemi',
    match: ['yakit', 'lpg', 'depo', 'oktan', 'enjektor', 'benzinli', 'dizel', 'turbo'],
    subjects: ['motor'],
  },
  {
    id: 'gosterge',
    label: 'Gösterge Paneli',
    match: ['gosterge', 'ikaz', 'uyari-lamba', 'ikaz-lamba', 'lamba', 'sicaklik-gostergesi'],
    subjects: ['motor'],
  },
  {
    id: 'motor-aktarma',
    label: 'Motor ve Aktarma Organları',
    match: [
      'motor',
      'vites',
      'debriyaj',
      'sanziman',
      'triger',
      'rolanti',
      'supap',
      'rodaj',
      'diferansiyel',
      'aktarma',
      'kavrama',
      'kayis',
      'kafa-contasi',
      'start-stop',
    ],
    subjects: ['motor'],
  },
  {
    id: 'periyodik-bakim',
    label: 'Periyodik Bakım',
    match: ['bakim', 'filtre', 'klima', 'silecek', 'cam-suyu', 'periyodik', 'muayene'],
    subjects: ['motor'],
  },
  // — İlk yardım temaları —
  {
    id: 'tyd',
    label: 'Temel Yaşam Desteği',
    match: [
      'tyd',
      'temel-yasam',
      'solunum',
      'nabiz',
      'kalp',
      'oed',
      'koma',
      'bilinc',
      'hava-yolu',
      'abc',
      'kbk',
      'dolasim',
      'normal',
    ],
    subjects: ['ilkyardim'],
  },
  {
    id: 'kanama-yara',
    label: 'Kanama ve Yaralanma',
    match: [
      'kanama',
      'yara',
      'uzuv',
      'kesik',
      'ezilme',
      'goz-yaralanma',
      'gogus',
      'karin',
      'omurga',
      'kafa-travma',
      'damar',
      'atardamar',
      'turnike',
      'sargi',
    ],
    subjects: ['ilkyardim'],
  },
  {
    id: 'kirik-cikik',
    label: 'Kırık, Çıkık ve Burkulma',
    match: ['kirik', 'cikik', 'burkulma', 'iskelet', 'kas', 'atel'],
    subjects: ['ilkyardim'],
  },
  {
    id: 'yanik-sicaklik',
    label: 'Yanık ve Sıcaklık Acilleri',
    match: ['yanik', 'sicak', 'donma', 'hipotermi', 'elektrik-carpma', 'vucut-sicakligi'],
    subjects: ['ilkyardim'],
  },
  {
    id: 'zehir-bogulma',
    label: 'Zehirlenme ve Boğulma',
    match: [
      'zehir',
      'bogulma',
      'tikanma',
      'bocek',
      'kene',
      'isirik',
      'alerji',
      'yabanci-cisim',
      'sokma',
    ],
    subjects: ['ilkyardim'],
  },
  {
    id: 'sok-acil',
    label: 'Şok ve Acil Durumlar',
    match: [
      'sok',
      'bayilma',
      'havale',
      'epilepsi',
      'diyabet',
      'inme',
      'felc',
      'acil',
      '112',
      'triyaj',
      'olay-yeri',
      'nakil',
      'tasima',
      'kaza-yeri',
      'kaza-ilk',
    ],
    subjects: ['ilkyardim'],
  },
  // — Direksiyon (pratik) —
  {
    id: 'sinav-uygulama',
    label: 'Direksiyon Sınavı Uygulaması',
    match: [
      'sinav',
      'direksiyon',
      'manevra',
      'geri',
      'kalkis',
      'ayna',
      'bakis',
      'pozisyon',
      'rampa',
      'u-donusu',
      'patinaj',
      'koltuk',
      'vites',
      'debriyaj',
      'el-freni',
      'park',
      'duraklama',
    ],
    subjects: ['pratik'],
  },
];

/**
 * Bir konu/etiket jeton kümesinde anahtar geçiyor mu?
 * - Tireli anahtar (çok kelimeli) → alt dizi eşleşmesi.
 * - Tek kelime, uzun (≥5) → ÖNEK eşleşmesi (`levha` → `levhasi`).
 * - Tek kelime, kısa (<5) → TAM jeton (`far` ≠ `farkindaligi`; `hiz` = `hiz`).
 */
function matchKeyword(topic: string, tokens: string[], tags: string[], kw: string): boolean {
  if (kw.includes('-')) return topic.includes(kw) || tags.some((t) => t.includes(kw));
  if (kw.length >= 5)
    return tokens.some((t) => t.startsWith(kw)) || tags.some((t) => t.startsWith(kw));
  return tokens.includes(kw) || tags.includes(kw);
}

export interface Classification {
  primaryTheme: string;
  primaryLabel: string;
  themes: string[];
}

/** Bir soruyu sınıflandır (deterministik). Konu + etiket sinyalleri; ders kapsamına saygılı. */
export function classify(
  nq: Pick<NormalizedQuestion, 'topic' | 'tags' | 'subject'>
): Classification {
  const topic = nq.topic.toLowerCase();
  const tokens = topic.split('-').filter(Boolean);
  const tags = nq.tags.map((t) => t.toLowerCase());
  const matched: Theme[] = [];
  for (const theme of THEMES) {
    if (theme.subjects && !theme.subjects.includes(nq.subject)) continue;
    if (theme.match.some((kw) => matchKeyword(topic, tokens, tags, kw))) matched.push(theme);
  }
  const fallback = SUBJECT_FALLBACK_THEME[nq.subject];
  const primary = matched[0] ?? fallback;
  const themes = matched.length > 0 ? matched.map((t) => t.id) : [fallback.id];
  return { primaryTheme: primary.id, primaryLabel: primary.label, themes };
}

/** id → etiket (tema veya ders-yedeği). */
export function themeLabel(id: string): string {
  const t = THEMES.find((x) => x.id === id);
  if (t) return t.label;
  const fb = Object.values(SUBJECT_FALLBACK_THEME).find((x) => x.id === id);
  return fb?.label ?? id;
}
