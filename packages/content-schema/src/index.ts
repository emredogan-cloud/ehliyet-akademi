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

/** Özgün soru — ROADMAP C.4/E.6: kaynak = resmî müfredat, kendi ifademizle. */
export const Question = z
  .object({
    id: z.string().regex(/^[a-z0-9-]+$/),
    subject: Subject,
    topic: z.string().min(2),
    difficulty: Difficulty.default('orta'),
    stem: z.string().min(8),
    options: z.array(z.string().min(1)).min(2).max(5),
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
  })
  .refine((q) => q.answerIndex < q.options.length, {
    message: 'answerIndex, options aralığında olmalı',
    path: ['answerIndex'],
  });
export type Question = z.infer<typeof Question>;
/** Yazım tipi: `.default([])` alanları (whyWrong/tags) girişte opsiyoneldir. */
export type QuestionInput = z.input<typeof Question>;

/** Ders bölümü (rozetli anlatım). */
export const LessonSection = z.object({
  heading: z.string().min(2),
  badge: Badge.optional(),
  body: z.string().min(2),
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
