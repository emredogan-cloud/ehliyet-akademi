/**
 * QIP 2.0 — İçerik Genişletme · Faz 2 · Bilgi Çıkarımı (referans katmanı).
 *
 * Sürüş alanının yapılandırılmış OLGULARI: sayısal limitler, yasal kurallar, tanımlar, prosedürler.
 * Kaynak = resmî Karayolları Trafik Kanunu/Yönetmeliği + MEB/ODSGM müfredatı + ilk yardım standartları.
 * OLGULAR telif konusu değildir (bir hız limiti bir gerçektir) — burada hiçbir sınav sorusu METNİ
 * yoktur; yalnız kavram/kural bilgisi. Bu katman: (1) üretimi topraklar (grounding), (2) bilgi
 * grafiğine kural düğümleri ekler, (3) Faz 3 boşluk analizinin ölçütüdür.
 */
import type { Subject } from '@ea/content-schema';

export type RuleCategory =
  | 'hiz'
  | 'mesafe'
  | 'oncelik'
  | 'isaret'
  | 'isik'
  | 'belge-ceza'
  | 'guvenlik'
  | 'alkol-uyusturucu'
  | 'cevre'
  | 'ilkyardim'
  | 'arac-teknik';

export interface DrivingRule {
  id: string;
  subject: Subject;
  category: RuleCategory;
  /** Kısa, olgusal ifade (özgün; mevzuat/müfredat bilgisi). */
  statement: string;
  /** Varsa sayısal değer + birim (ör. 50 km/s, 0.50 promil, 100 ceza puanı). */
  value?: string;
  /** İlişkili konu etiketleri (bankadaki topic'lerle eşleşmeye yarar). */
  topics: string[];
  /** Kaynak dayanağı (özgün ifade). */
  source: string;
}

const KTK = 'Karayolları Trafik Kanunu/Yönetmeliği (özgün ifade)';
const MEB = 'Resmî MEB/ODSGM müfredatı (özgün ifade)';
const IY = 'Resmî ilk yardım standartları (özgün ifade)';

/**
 * Çekirdek kural/olgu kümesi. Sınavda en çok ölçülen SAYISAL ve YASAL gerçekleri kapsar.
 * (Genişletilebilir; her biri özgün olgusal ifadedir, kopya soru DEĞİL.)
 */
export const DRIVING_RULES: DrivingRule[] = [
  // — Hız —
  {
    id: 'rule-hiz-yerlesim',
    subject: 'trafik',
    category: 'hiz',
    statement: 'Yerleşim yeri içinde otomobil için genel azami hız sınırı.',
    value: '50 km/s',
    topics: ['hiz'],
    source: KTK,
  },
  {
    id: 'rule-hiz-sehirlerarasi',
    subject: 'trafik',
    category: 'hiz',
    statement: 'Şehirlerarası çift yönlü karayolunda otomobil için genel azami hız.',
    value: '90 km/s',
    topics: ['hiz'],
    source: KTK,
  },
  {
    id: 'rule-hiz-bolunmus',
    subject: 'trafik',
    category: 'hiz',
    statement: 'Bölünmüş şehirlerarası yolda otomobil için genel azami hız.',
    value: '110 km/s',
    topics: ['hiz'],
    source: KTK,
  },
  {
    id: 'rule-hiz-otoyol',
    subject: 'trafik',
    category: 'hiz',
    statement: 'Otoyolda otomobil için genel azami hız.',
    value: '120 km/s',
    topics: ['hiz', 'otoyol'],
    source: KTK,
  },
  {
    id: 'rule-hiz-kotu-hava',
    subject: 'trafik',
    category: 'hiz',
    statement:
      'Yasal hız sınırı bir azami değerdir; yağış, sis, buzlanma gibi koşullarda hız sınırın altına düşürülür.',
    topics: ['hiz', 'hava-kosullari'],
    source: KTK,
  },
  // — Takip mesafesi —
  {
    id: 'rule-takip-mesafesi',
    subject: 'trafik',
    category: 'mesafe',
    statement:
      'Öndeki araçla güvenli takip mesafesi kural olarak hızın en az yarısı kadar metredir.',
    value: 'hız/2 metre',
    topics: ['takip-mesafesi', 'guvenli-mesafe'],
    source: KTK,
  },
  // — Alkol —
  {
    id: 'rule-alkol-ozel',
    subject: 'trafik',
    category: 'alkol-uyusturucu',
    statement: 'Hususi otomobil sürücüleri için yasal kandaki azami alkol sınırı.',
    value: '0.50 promil',
    topics: ['alkol'],
    source: KTK,
  },
  {
    id: 'rule-alkol-ticari',
    subject: 'trafik',
    category: 'alkol-uyusturucu',
    statement: 'Ticari araç sürücüleri alkollü olarak araç kullanamaz (sıfır tolerans).',
    value: '0.00 promil',
    topics: ['alkol'],
    source: KTK,
  },
  // — Ceza puanı / belge —
  {
    id: 'rule-ceza-puani',
    subject: 'trafik',
    category: 'belge-ceza',
    statement:
      'Bir takvim yılı içinde toplam ceza puanı belirtilen sınırı aşınca sürücü belgesi süreli geri alınır.',
    value: '100 ceza puanı',
    topics: ['ceza-puani', 'belge-geri-alma'],
    source: KTK,
  },
  // — Emniyet / güvenlik —
  {
    id: 'rule-emniyet-kemeri',
    subject: 'trafik',
    category: 'guvenlik',
    statement: 'Araçta emniyet kemeri takmak, önde ve arkada oturan tüm yolcular için zorunludur.',
    topics: ['emniyet-kemeri'],
    source: KTK,
  },
  {
    id: 'rule-cocuk-guvenlik',
    subject: 'trafik',
    category: 'guvenlik',
    statement:
      'Belirli boy/yaş altındaki çocuklar uygun çocuk koltuğu/oturağı ile taşınır ve ön koltukta oturmaz.',
    topics: ['cocuk-guvenligi'],
    source: KTK,
  },
  // — Işıklı işaret —
  {
    id: 'rule-kirmizi-isik',
    subject: 'trafik',
    category: 'isik',
    statement: 'Kırmızı ışıkta araç dur çizgisinde durur; yaya ve trafiğe geçiş vermez.',
    topics: ['isikli-isaret-cihazlari', 'isik'],
    source: KTK,
  },
  {
    id: 'rule-sari-isik',
    subject: 'trafik',
    category: 'isik',
    statement: 'Sarı ışıkta sürücü durmaya hazırlanır; güvenle durabiliyorsa durur.',
    topics: ['isikli-isaret-cihazlari', 'sari-isik-karar'],
    source: KTK,
  },
  // — Öncelik —
  {
    id: 'rule-oncelik-saga',
    subject: 'trafik',
    category: 'oncelik',
    statement:
      'Işıksız, işaretsiz eşit yolların kesiştiği kavşakta sağdan gelen araca geçiş hakkı verilir.',
    topics: ['oncelik', 'kavsak-gecis'],
    source: KTK,
  },
  {
    id: 'rule-oncelik-donel',
    subject: 'trafik',
    category: 'oncelik',
    statement:
      'Dönel kavşakta ada etrafında dönen araç, kavşağa girmek isteyene göre geçiş üstünlüğüne sahiptir.',
    topics: ['donel-kavsak', 'oncelik'],
    source: KTK,
  },
  {
    id: 'rule-gecis-ustunlugu',
    subject: 'trafik',
    category: 'oncelik',
    statement:
      'Ambulans, itfaiye, polis gibi geçiş üstünlüğüne sahip araçlara yol verilir; onları takip etmek yasaktır.',
    topics: ['gecis-ustunlugu', 'oncelik'],
    source: KTK,
  },
  // — İşaret —
  {
    id: 'rule-dur-levhasi',
    subject: 'trafik',
    category: 'isaret',
    statement:
      'Kırmızı sekizgen DUR levhasında araç tam olarak durur ve geçiş hakkı olana yol verir.',
    topics: ['isaretler'],
    source: KTK,
  },
  {
    id: 'rule-yol-ver',
    subject: 'trafik',
    category: 'isaret',
    statement:
      'Ters üçgen YOL VER levhasında sürücü yavaşlar ve ana yoldaki araçlara geçiş hakkı verir; gerekirse durur.',
    topics: ['isaretler', 'yol-verme'],
    source: KTK,
  },
  // — Çevre —
  {
    id: 'rule-cevre-ekonomik',
    subject: 'trafik',
    category: 'cevre',
    statement:
      'Ani hızlanma/frenden kaçınmak, uygun vites ve düzenli bakım yakıt tüketimini ve emisyonu azaltır.',
    topics: ['cevre', 'yakit-tasarrufu'],
    source: MEB,
  },
  // — İlk yardım (sayısal) —
  {
    id: 'rule-tyd-basi-solunum',
    subject: 'ilkyardim',
    category: 'ilkyardim',
    statement: 'Yetişkinde temel yaşam desteğinde kalp basısı/suni solunum oranı.',
    value: '30:2',
    topics: ['tyd', 'temel-yasam-destegi'],
    source: IY,
  },
  {
    id: 'rule-tyd-basi-derinlik',
    subject: 'ilkyardim',
    category: 'ilkyardim',
    statement: 'Yetişkinde kalp basısı derinliği yaklaşık 5 cm, hızı dakikada 100-120 basıdır.',
    value: '~5 cm, 100-120/dk',
    topics: ['tyd', 'temel-yasam-destegi'],
    source: IY,
  },
  {
    id: 'rule-112',
    subject: 'ilkyardim',
    category: 'ilkyardim',
    statement:
      'Türkiye’de acil çağrı numarası 112’dir; olay yeri güvenliği sağlanmadan müdahaleye başlanmaz.',
    value: '112',
    topics: ['112-iletisim', 'olay-yeri-guvenligi'],
    source: IY,
  },
  {
    id: 'rule-kanama-basi',
    subject: 'ilkyardim',
    category: 'ilkyardim',
    statement: 'Dış kanamada ilk uygulama, yara üzerine temiz bezle doğrudan bası yapmaktır.',
    topics: ['kanama'],
    source: IY,
  },
  // — Araç teknik —
  {
    id: 'rule-lastik-dis',
    subject: 'motor',
    category: 'arac-teknik',
    statement:
      'Lastik diş derinliği yasal asgari sınırın altına düşen lastik güvenli değildir, değiştirilir.',
    topics: ['lastik', 'lastik-dis'],
    source: MEB,
  },
  {
    id: 'rule-fren-arizasi',
    subject: 'motor',
    category: 'arac-teknik',
    statement:
      'Fren boşaldığında motor freni (vites küçültme) ve el freni kademeli kullanılarak güvenle yavaşlanır.',
    topics: ['fren'],
    source: MEB,
  },
  {
    id: 'rule-hararet',
    subject: 'motor',
    category: 'arac-teknik',
    statement:
      'Motor hararet yaptığında araç güvenli yerde durdurulur; radyatör kapağı sıcakken açılmaz.',
    topics: ['hararet', 'sogutma'],
    source: MEB,
  },
];

/** Kategori/ders bazlı özet (Faz 3 boşluk analizi + KG için). */
export function rulesBySubject(): Record<string, number> {
  const out: Record<string, number> = {};
  for (const r of DRIVING_RULES) out[r.subject] = (out[r.subject] ?? 0) + 1;
  return out;
}

export function rulesByCategory(): Record<string, number> {
  const out: Record<string, number> = {};
  for (const r of DRIVING_RULES) out[r.category] = (out[r.category] ?? 0) + 1;
  return out;
}

/** Bir kuralın değindiği tüm topic'ler (KG kural→konu bağı için). */
export function ruleTopics(): Set<string> {
  const s = new Set<string>();
  for (const r of DRIVING_RULES) for (const t of r.topics) s.add(t);
  return s;
}
