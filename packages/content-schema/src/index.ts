/**
 * @ea/content-schema — platformun tipli içerik sözleşmesi.
 * ROADMAP Faz 9–12 / ADR-005. Derleme + çalışma zamanı doğrulaması (Zod).
 * Kullanıcıya görünen tüm metinler Türkçedir.
 */
import { z } from 'zod';

/** Bilgi sınıflandırma rozetleri (v1'den korunur — ROADMAP bilgi doğruluğu ilkesi). */
export const Badge = z.enum([
  'official', // Resmî Kural — yalnız doğrulanmış mevzuat
  'examiner', // Sınav Uygulaması
  'instructor', // Eğitmen Tavsiyesi
  'best', // En İyi Uygulama
  'safety', // Güvenlik İpucu
]);
export type Badge = z.infer<typeof Badge>;

export const BADGE_LABEL: Record<Badge, string> = {
  official: 'Resmî Kural',
  examiner: 'Sınav Uygulaması',
  instructor: 'Eğitmen Tavsiyesi',
  best: 'En İyi Uygulama',
  safety: 'Güvenlik İpucu',
};

/** Teorik e-Sınav dersleri (MEB dağılımı) + pratik. */
export const Subject = z.enum([
  'trafik', // Trafik ve Çevre Bilgisi — 23 soru
  'ilkyardim', // İlk Yardım Bilgisi — 12 soru
  'motor', // Araç Tekniği (Motor) — 9 soru
  'adab', // Trafik Adabı — 6 soru
  'pratik', // Direksiyon (uygulama) sınavı
]);
export type Subject = z.infer<typeof Subject>;

export const SUBJECT_LABEL: Record<Subject, string> = {
  trafik: 'Trafik ve Çevre Bilgisi',
  ilkyardim: 'İlk Yardım Bilgisi',
  motor: 'Araç Tekniği',
  adab: 'Trafik Adabı',
  pratik: 'Direksiyon (Uygulama)',
};

/** Teorik e-Sınav dersleri (pratik hariç) — dağılım indekslemesi için daraltılmış tip. */
export type TheorySubject = 'trafik' | 'ilkyardim' | 'motor' | 'adab';
export const THEORY_SUBJECTS: TheorySubject[] = ['trafik', 'ilkyardim', 'motor', 'adab'];

export const Difficulty = z.enum(['kolay', 'orta', 'zor']);
export type Difficulty = z.infer<typeof Difficulty>;

/** İçerik doğrulama/inceleme durumu (ROADMAP E.6 — uzman onayı). */
export const ReviewStatus = z.enum(['draft', 'in-review', 'approved']);
export type ReviewStatus = z.infer<typeof ReviewStatus>;

/**
 * QIP v3 · Faz 1 — soru TÜRÜ.
 *
 * Neden ayrı bir alan: bir sorunun görsel taşıyıp taşımadığı `media` alanının varlığından
 * çıkarılabilirdi, ama tür bundan FAZLASINI söyler — aynı "görselli" soru bir levha tanıma
 * sorusu da olabilir, bir kavşak önceliği sorusu da. Arayüz ikisini farklı çizer (levha kare ve
 * küçük, kavşak geniş ve şemadır), üreteç farklı oranlarda karar, kalite motoru farklı kurallar
 * uygular. Türü `media`'dan tahmin etmek bu üç yerde de tahmin yürütmek olurdu.
 *
 * Varsayılan `text` — mevcut 1.562 soru tek satır değişmeden geçerli kalır.
 */
export const QuestionKind = z.enum([
  'text',
  'image',
  'scenario',
  'diagram',
  'intersection',
  'sign',
  'mechanic',
  'dashboard',
]);
export type QuestionKind = z.infer<typeof QuestionKind>;

/**
 * Görsel üstünde İLGİ ALANI (hotspot). **Bugün çizilmiyor** — şemada yer tutuyor.
 *
 * Neden şimdiden: "aşağıdaki kavşakta hangi araç önce geçer, ARACA DOKUN" tipi sorular
 * yol haritasında var. Alan sonradan eklenirse, o gün yayında olan bütün soruların şeması
 * değişir ve mobil istemcilerin eski sürümleri yeni yükü çözemez. Opsiyonel bir alanı bugün
 * koymak bedavadır; yarın koymak göç demektir.
 *
 * Koordinatlar 0–1 aralığında NORMALİZE: görselin piksel boyutundan bağımsız, her ekranda aynı.
 */
export const ImageHotspot = z.object({
  id: z.string().min(1),
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  w: z.number().min(0).max(1),
  h: z.number().min(0).max(1),
  label: z.string().min(1),
});
export type ImageHotspot = z.infer<typeof ImageHotspot>;

/** Soruya bağlı tek görsel. */
export const QuestionImage = z.object({
  /** Varlık kimliği — `AssetCatalog` sözleşmesiyle çözülür (`assets/<kategori>/<id>.<uzantı>`). */
  assetId: z.string().min(1),
  /**
   * ZORUNLU. Görsel yüklenmezse soru cevaplanamaz hâle gelir; ekran okuyucu kullanan biri için
   * ise soru zaten hiç var olmamış olur. Opsiyonel bırakılsaydı er geç `alt`sız soru girerdi.
   */
  alt: z.string().min(3),
  caption: z.string().optional(),
  hotspots: z.array(ImageHotspot).default([]),
});
export type QuestionImage = z.infer<typeof QuestionImage>;

/**
 * Sorunun görsel yükü. **Çoklu görsel** baştan destekleniyor: "aşağıdaki iki levhadan hangisi…"
 * ve "şu üç durumdan hangisinde…" tipleri tek görselle kurulamaz.
 */
export const QuestionMedia = z.object({
  images: z.array(QuestionImage).min(1),
  /** `single` tek görsel · `grid` yan yana · `compare` karşılaştırma (A/B). */
  layout: z.enum(['single', 'grid', 'compare']).default('single'),
});
export type QuestionMedia = z.infer<typeof QuestionMedia>;

/**
 * ÜRETİM metaverisi — soru bir üreteçten çıktıysa hangi üreteç, hangi sürüm, hangi tohum.
 *
 * Neden gerekli: üretilmiş sorularda bir kusur bulunduğunda (ör. çeldirici seçimi zayıf),
 * "hangi sorular bu üreteçten çıktı" sorusu cevaplanabilmeli ki toplu düzeltme yapılabilsin.
 * `seed` ile üretim birebir yeniden oynatılabilir.
 */
export const GenerationMeta = z.object({
  generator: z.string().min(2),
  version: z.number().int().positive(),
  seed: z.number().int().optional(),
  generatedAt: z.string().optional(),
});
export type GenerationMeta = z.infer<typeof GenerationMeta>;

/**
 * Özgün soru gövdesi (refine'siz taban) — ROADMAP C.4/E.6: kaynak = resmî müfredat, kendi
 * ifademizle. QIP Faz 1: `NormalizedQuestion` bu tabandan `.extend` ile türetilir.
 */
export const QuestionBase = z.object({
  id: z.string().regex(/^[a-z0-9-]+$/),
  subject: Subject,
  topic: z.string().min(2),
  difficulty: Difficulty.default('orta'),
  stem: z.string().min(8),
  /**
   * Faz 11 — TAM DÖRT seçenek (A/B/C/D). Bu bir biçim tercihi değil, gerçek e-Sınav'ın yapısıdır:
   * MEB e-Sınav'da her soru dört şıklıdır. Şema `.min(2).max(5)` iken bankaya 39 adet üç şıklı ve
   * 13 adet beş şıklı soru sızmıştı; kullanıcı bazı sorularda A-B-C, bazılarında A-B-C-D-E
   * görüyordu. Kural artık ŞEMADA: aynı hata bir daha sessizce giremez.
   */
  options: z.array(z.string().min(1)).length(4),
  answerIndex: z.number().int().nonnegative(),
  explanation: z.string().min(8),
  badge: Badge.optional(),
  /**
   * Sprint 3 — zenginleştirilmiş öğrenme metaverisi (hepsi opsiyonel, geriye dönük uyumlu).
   * `whyWrong`: çeldiricilerin neden yanlış olduğu (öğretici geri bildirim).
   * `objective`: sorunun ölçtüğü öğrenme kazanımı. `tags`: konu etiketleri (arama/SRS/filtre).
   */
  whyWrong: z.array(z.string().min(3)).default([]),
  objective: z.string().min(4).optional(),
  tags: z.array(z.string().min(2)).default([]),
  /** İçerik yönetişimi: özgünlük + uzman onay izi. */
  review: ReviewStatus.default('draft'),
  reviewedBy: z.string().optional(),
  sourceRef: z.string().optional(),
  /**
   * QIP v3 · Faz 1 — tür + görsel + üretim izi. **Hepsi opsiyonel/varsayılanlı**, yani mevcut
   * 1.562 soru ve onları üreten her çağrı tek satır değişmeden geçerli kalır.
   */
  kind: QuestionKind.optional(),
  media: QuestionMedia.optional(),
  generation: GenerationMeta.optional(),
});

/**
 * Tür ile görsel yükü TUTARLI mı?
 *
 * Görsel gerektiren bir tür (`sign`, `dashboard`, `mechanic`, `diagram`, `intersection`, `image`)
 * `media` olmadan tanımlanamaz: soru metni "aşağıdaki levha" diyip ortada levha olmaması,
 * kullanıcı için cevaplanamaz bir sorudur. Bu kural ŞEMADA durur ki üreteç ya da yazar
 * unutamasın (Faz 11'deki "dört şık" kuralının aynı gerekçesi).
 */
/**
 * `kind` NEDEN `.default('text')` DEĞİL, `.optional()`.
 *
 * Banka dosyaları (`packages/question-bank/src/*.ts`) diziyi `Question[]` — yani şemanın ÇIKTI
 * tipiyle — bildiriyor. Zod'da `.default()` bir alanı çıktı tipinde ZORUNLU yapar; `kind` için
 * varsayılan konsaydı 1.562 sorunun tamamına elle `kind: 'text'` yazmak gerekirdi. Bu, "geriye
 * dönük uyumluluğu asla bozma" kuralının doğrudan ihlali olurdu.
 *
 * Onun yerine alan opsiyonel bırakıldı ve okuma tek bir yerden yapılıyor: [kindOf].
 */
export function kindOf(q: { kind?: QuestionKind }): QuestionKind {
  return q.kind ?? 'text';
}

export const VISUAL_KINDS: QuestionKind[] = [
  'image',
  'diagram',
  'intersection',
  'sign',
  'mechanic',
  'dashboard',
];

const mediaMatchesKind = (q: { kind?: QuestionKind; media?: unknown }): boolean =>
  !VISUAL_KINDS.includes(kindOf(q)) || q.media != null;
const MEDIA_KIND_MSG = {
  message: 'görsel gerektiren türde `media` zorunludur',
  path: ['media'] as (string | number)[],
};

/** answerIndex, options aralığında mı? (Question + NormalizedQuestion ortak kısıtı) */
const answerInRange = (q: { answerIndex: number; options: unknown[] }): boolean =>
  q.answerIndex < q.options.length;
const ANSWER_RANGE_MSG = {
  message: 'answerIndex, options aralığında olmalı',
  path: ['answerIndex'] as (string | number)[],
};

/** Özgün soru — kaynak = resmî müfredat, kendi ifademizle. */
export const Question = QuestionBase.refine(answerInRange, ANSWER_RANGE_MSG).refine(
  mediaMatchesKind,
  MEDIA_KIND_MSG
);
export type Question = z.infer<typeof Question>;
/** Yazım tipi: `.default([])` alanları (whyWrong/tags) girişte opsiyoneldir. */
export type QuestionInput = z.input<typeof Question>;

/* ================= QIP (Soru Zekâsı Platformu) — Faz 1: normalleştirme ================= */

/**
 * Kaynak atıf metaverisi (BANK_QUESTİON Part 1 — kaynak izlenebilirliği).
 * İçerik hukuku: `origin: 'authored'` (özgün) veya `'ai-generated'` (Faz 4, review:draft).
 * Telif korumalı üçüncü taraf soru bankaları KOPYALANMAZ; bu yüzden `'imported'` yalnız
 * açık lisanslı/kamuya açık kaynaklar için ayrılmıştır.
 */
export const QuestionSource = z.object({
  origin: z.enum(['authored', 'ai-generated', 'imported']).default('authored'),
  collection: z.string().optional(),
  attribution: z.string().optional(),
  license: z.string().default('proprietary'),
  method: z.enum(['authored', 'curriculum', 'ai', 'import']).default('authored'),
});
export type QuestionSource = z.infer<typeof QuestionSource>;

/** QIP üst kategori — ders (subject) → kategori etiketi (Faz 2 sınıflandırıcı inceltir). */
export const QIP_CATEGORY_BY_SUBJECT: Record<Subject, string> = {
  trafik: 'Trafik ve Çevre',
  ilkyardim: 'İlk Yardım',
  motor: 'Araç Tekniği',
  adab: 'Trafik Adabı',
  pratik: 'Direksiyon Uygulaması',
};

/** Zorluk → tahmini çözüm süresi (sn). MEB e-Sınav: 45 dk / 50 soru ≈ 54 sn ortalama. */
export const EST_SECONDS_BY_DIFFICULTY: Record<Difficulty, number> = {
  kolay: 45,
  orta: 60,
  zor: 80,
};

/**
 * Türkçe-duyarlı metin katlama — parmak izi + benzerlik için kararlı kanonik biçim.
 * Küçük harfe indirir, `ı→i`, aksanları (NFKD) ayıklar (ç→c, ş→s, ö→o, ü→u, ğ→g),
 * noktalamayı boşluğa çevirir, boşlukları sadeleştirir.
 */
export function foldText(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/ı/g, 'i')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Deterministik FNV-1a 32-bit hash → 8 haneli hex (kripto gerektirmez; tarayıcı + node). */
export function hash32(s: string): string {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0).toString(16).padStart(8, '0');
}

/**
 * İçerik parmak izi — katlanmış stem + SIRALI seçenek metinleri. Seçenek sırası
 * bağımsızdır (çeldiriciler karıştırılsa da aynı parmak izi) → dedup için kararlı.
 */
export function questionFingerprint(q: { stem: string; options: string[] }): string {
  const stem = foldText(q.stem);
  const opts = q.options.map(foldText).sort().join('|');
  return hash32(`${stem}##${opts}`);
}

/**
 * Birleşik (unified) soru şeması — BANK_QUESTİON Part 2. Elle yazılan `Question`'ı
 * QIP zekâ alanlarıyla zenginleştirir; normalleştirme hattının çıktısıdır.
 */
export const NormalizedQuestion = QuestionBase.extend({
  category: z.string().min(2),
  subcategory: z.string().min(2),
  learningOutcome: z.string().optional(),
  relatedLesson: z.string().optional(),
  relatedSigns: z.array(z.string()).default([]),
  relatedVehicleParts: z.array(z.string()).default([]),
  estimatedSeconds: z.number().int().positive(),
  commonMistakes: z.array(z.string()).default([]),
  image: z.string().optional(),
  video: z.string().optional(),
  source: QuestionSource,
  qualityScore: z.number().min(0).max(100).optional(),
  fingerprint: z.string().min(4),
  version: z.number().int().positive().default(1),
})
  .refine(answerInRange, ANSWER_RANGE_MSG)
  .refine(mediaMatchesKind, MEDIA_KIND_MSG);
export type NormalizedQuestion = z.infer<typeof NormalizedQuestion>;
export type NormalizedQuestionInput = z.input<typeof NormalizedQuestion>;

/**
 * Taban normalleştirme — uygulama içeriği (levha/ders/parça) GEREKTİRMEYEN alanları doldurur.
 * Cross-link alanları (relatedSigns/relatedVehicleParts/relatedLesson) uygulama katmanında
 * (`apps/web/lib/qip`) eklenir; oraya `overrides` ile geçirilir.
 */
export function baseNormalize(
  q: Question,
  overrides: Partial<NormalizedQuestionInput> = {}
): NormalizedQuestion {
  const draft: NormalizedQuestionInput = {
    ...q,
    category: QIP_CATEGORY_BY_SUBJECT[q.subject],
    subcategory: q.topic,
    learningOutcome: q.objective,
    relatedSigns: [],
    relatedVehicleParts: [],
    estimatedSeconds: EST_SECONDS_BY_DIFFICULTY[q.difficulty],
    commonMistakes: q.whyWrong,
    source: {
      origin: 'authored',
      collection: q.subject,
      attribution: q.sourceRef,
      license: 'proprietary',
      method: 'curriculum',
    },
    fingerprint: questionFingerprint(q),
    version: 1,
    ...overrides,
  };
  return NormalizedQuestion.parse(draft);
}

/** Vurgu kutusu (callout) — ders içi görsel öne çıkarma. */
export const Callout = z.object({
  tone: z.enum(['info', 'success', 'warning', 'danger']),
  title: z.string().min(2).optional(),
  text: z.string().min(2),
});
export type Callout = z.infer<typeof Callout>;

/** Karşılaştırma tablosu — metin-ağırlıklı anlatımı görselleştirir. */
export const CompareTable = z.object({
  caption: z.string().min(2).optional(),
  headers: z.array(z.string().min(1)).min(2).max(4),
  rows: z.array(z.array(z.string()).min(2).max(4)).min(1),
});
export type CompareTable = z.infer<typeof CompareTable>;

/** Ders bölümü (rozetli anlatım + opsiyonel görsel bloklar). */
export const LessonSection = z.object({
  heading: z.string().min(2),
  badge: Badge.optional(),
  body: z.string().min(2),
  /** Program 1 · Bölüm D — bölüm gövdesini görselleştiren opsiyonel bloklar (geriye dönük uyumlu). */
  callout: Callout.optional(),
  compare: CompareTable.optional(),
});
export type LessonSection = z.infer<typeof LessonSection>;

/** Tekrar kartı (aktif hatırlama) — ön yüz soru/ipucu, arka yüz cevap. */
export const ReviewCard = z.object({
  front: z.string().min(2),
  back: z.string().min(2),
});
export type ReviewCard = z.infer<typeof ReviewCard>;

export const Lesson = z.object({
  id: z.string().regex(/^[a-z0-9-]+$/),
  slug: z.string().regex(/^[a-z0-9-]+$/),
  no: z.number().int().positive(),
  subject: Subject,
  title: z.string().min(4),
  summary: z.string().min(8),
  minutes: z.number().int().positive().max(60),
  objectives: z.array(z.string().min(4)).min(1),
  sections: z.array(LessonSection).min(1),
  mistakes: z.array(z.object({ text: z.string(), fix: z.string() })).default([]),
  tips: z.array(z.string()).default([]),
  quizQuestionIds: z.array(z.string()).default([]),
  references: z.array(z.string()).default([]),
  /**
   * Sprint 3 — derinleştirilmiş ders yapısı (hepsi opsiyonel, geriye dönük uyumlu).
   * memoryTips: hafıza teknikleri · examStrategy: sınav stratejisi · keyTakeaways: özet maddeleri
   * reviewCards: aktif hatırlama kartları · practiceQuestionIds: alıştırma soruları · figureId: görsel eşlemesi
   */
  memoryTips: z.array(z.string().min(3)).default([]),
  examStrategy: z.array(z.string().min(3)).default([]),
  keyTakeaways: z.array(z.string().min(3)).default([]),
  reviewCards: z.array(ReviewCard).default([]),
  practiceQuestionIds: z.array(z.string()).default([]),
  figureId: z.string().optional(),
  /** Sprint 4 — premium içerik kapısı. true ise ilgili paket olmadan içeriği kilitlidir. */
  premium: z.boolean().default(false),
  /**
   * Evolution Faz E5 — dersin geçerli olduğu ehliyet sınıfları ('b' | 'a' | 'd').
   * BOŞ ise ders sınıftan bağımsızdır (e-Sınav teorisi Türkiye'de tüm sınıflar için ORTAKTIR;
   * sınıfa özgü olan araç kullanma tekniği, mekanik ve mevzuat farklarıdır).
   */
  licences: z.array(z.enum(['b', 'a', 'd'])).default([]),
});
export type Lesson = z.infer<typeof Lesson>;
/** Yazım tipi: Sprint 3 zenginleştirme alanları girişte opsiyoneldir. */
export type LessonInput = z.input<typeof Lesson>;

/** Gerçek e-Sınav yapısı — ROADMAP C.1 (doğrulanmış dağılım). */
export const EXAM_BLUEPRINT = {
  totalQuestions: 50,
  passCorrect: 35,
  durationMinutes: 45,
  distribution: { trafik: 23, ilkyardim: 12, motor: 9, adab: 6 },
} as const;

export type ExamDistribution = typeof EXAM_BLUEPRINT.distribution;

/** Yardımcılar */
export function parseQuestion(input: unknown): Question {
  return Question.parse(input);
}
export function parseLesson(input: unknown): Lesson {
  return Lesson.parse(input);
}

/** Bir soru kümesinin geçerliliğini ve id benzersizliğini doğrular. */
export function validateBank(questions: unknown[]): {
  ok: boolean;
  count: number;
  errors: string[];
} {
  const errors: string[] = [];
  const ids = new Set<string>();
  const parsed: Question[] = [];
  questions.forEach((q, i) => {
    const r = Question.safeParse(q);
    if (!r.success) {
      errors.push(`#${i}: ${r.error.issues.map((e) => e.message).join(', ')}`);
      return;
    }
    if (ids.has(r.data.id)) errors.push(`#${i}: tekrar eden id "${r.data.id}"`);
    ids.add(r.data.id);
    parsed.push(r.data);
  });
  return { ok: errors.length === 0, count: parsed.length, errors };
}

/* ================= Sprint 2 — CMS sözleşmeleri ================= */

/** Makale/SEO sayfası/bilgi-tabanı gövdesi (ROADMAP Faz 15/33). */
export const Article = z.object({
  title: z.string().min(4),
  summary: z.string().min(8),
  body: z.string().min(20), // markdown-lite (** ve [link](/yol))
  seo: z
    .object({
      metaDescription: z.string().max(160).optional(),
      canonicalPath: z.string().startsWith('/').optional(),
    })
    .default({}),
});
export type Article = z.infer<typeof Article>;

/** İçerik yayın akışı — izinli geçişler (ADR-007; sunucuda zorlanır). */
export const WORKFLOW: Record<string, string[]> = {
  draft: ['in_review', 'retired'],
  in_review: ['approved', 'draft'],
  approved: ['published', 'draft'],
  published: ['retired'],
  retired: ['draft'],
};
export function canTransition(from: string, to: string): boolean {
  return (WORKFLOW[from] ?? []).includes(to);
}

/** Tür → payload doğrulayıcı eşlemesi (CMS yazım kapısı). */
export function validatePayload(type: string, payload: unknown): { ok: boolean; errors: string[] } {
  const map: Record<string, z.ZodTypeAny> = {
    question: Question,
    lesson: Lesson,
    article: Article,
    seo_page: Article,
    kb: Article,
  };
  const schema = map[type];
  if (!schema) return { ok: false, errors: [`Bilinmeyen içerik türü: ${type}`] };
  const r = schema.safeParse(payload);
  return r.success
    ? { ok: true, errors: [] }
    : { ok: false, errors: r.error.issues.map((e) => `${e.path.join('.')}: ${e.message}`) };
}

/* ——— Soru kalite ölçümü (Ürün Evrimi v1.1 · Faz 1) ——— */
export {
  longestOptionWins,
  answerLengthRatio,
  hasParallelOptions,
  measureBank,
  checkQualityGate,
  formatQualityReport,
  PARALLEL_RATIO_LIMIT,
  QUALITY_GATE,
  QUALITY_RATCHET,
  type ScorableQuestion,
  type BankQualityReport,
  type GateFailure,
} from './quality';
