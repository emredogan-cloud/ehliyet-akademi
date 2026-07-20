/**
 * QIP — Faz 5 · Sınav Koleksiyonları (BANK_QUESTİON Part 16).
 *
 * Bankadan OTOMATİK, deterministik koleksiyonlar üretir: Günün/Haftanın Sınavı, Başlangıç, Zor
 * Sorular, Yalnız İşaretler/Motor/İlk Yardım, En Çok Yanılan, Rastgele 50, AI Challenge.
 * Tohum (gün/hafta) UI'dan verilir → gün içinde sabit, günden güne farklı. Faz 2 kalite/tema +
 * Faz 3 aileleri + Faz 5 dinamik sınav üreticisini kullanır.
 */
import { hash32 } from '@ea/content-schema';
import { analyzedQuestions, type AnalyzedQuestion } from './index';
import { buildDynamicExam } from './exam';
import { seededRng, type Rng } from './visual';
import type { QuestionAnalytics } from './analytics';

export interface CollectionSpec {
  id: string;
  label: string;
  description: string;
  emoji: string;
  count: number;
  questionIds: string[];
}

export interface CollectionsOptions {
  /** Gün tohumu (ör. 'YYYY-MM-DD' → hash). Verilmezse sabit 1. */
  daySeed?: number;
  weekSeed?: number;
  /** En-çok-yanılan sıralaması için opsiyonel soru istatistikleri. */
  stats?: QuestionAnalytics[];
  pool?: AnalyzedQuestion[];
}

/** Tarih dizesinden kararlı tohum (UI: `seedFromDate('2026-07-21')`). */
export function seedFromDate(dateStr: string): number {
  return parseInt(hash32(dateStr), 16) >>> 0;
}

/** ISO hafta anahtarı için basit hafta tohumu (aynı haftada sabit). */
export function seedFromWeek(dateStr: string): number {
  // YYYY-MM-DD → yıl + haftanın kabaca indeksini kullan (deterministik, UI'dan verilir).
  return parseInt(hash32('week:' + dateStr.slice(0, 7)), 16) >>> 0;
}

function pick(pool: AnalyzedQuestion[], rng: Rng, n: number): string[] {
  const a = [...pool];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a.slice(0, n).map((q) => q.id);
}

/** Otomatik koleksiyonları üret (GERÇEK sayılar). */
export function examCollections(opts: CollectionsOptions = {}): CollectionSpec[] {
  const pool = opts.pool ?? analyzedQuestions();
  const daySeed = opts.daySeed ?? 1;
  const weekSeed = opts.weekSeed ?? 2;

  const out: CollectionSpec[] = [];
  const add = (id: string, label: string, description: string, emoji: string, ids: string[]) =>
    out.push({ id, label, description, emoji, count: ids.length, questionIds: ids });

  // Günün / Haftanın Sınavı — dinamik, dengeli, benzersiz.
  add(
    'gunun-sinavi',
    'Günün Sınavı',
    'Her gün yenilenen, MEB dağılımına uygun dengeli 50 soruluk sınav.',
    '📅',
    buildDynamicExam({ seed: daySeed, count: 50 }).questions.map((q) => q.id)
  );
  add(
    'haftanin-sinavi',
    'Haftanın Sınavı',
    'Haftalık, zorluğu dengelenmiş 50 soruluk sınav.',
    '🗓️',
    buildDynamicExam({ seed: weekSeed, count: 50, difficultyBalance: true }).questions.map(
      (q) => q.id
    )
  );

  // Başlangıç — kolay sorular.
  add(
    'baslangic',
    'Başlangıç',
    'Yeni başlayanlar için kolay sorular.',
    '🌱',
    pick(
      pool.filter((q) => q.difficulty === 'kolay'),
      seededRng(daySeed + 11),
      40
    )
  );

  // Zor Sorular.
  add(
    'zor-sorular',
    'Zor Sorular',
    'Kendini sına: yalnızca zor sorular.',
    '🔥',
    pick(
      pool.filter((q) => q.difficulty === 'zor'),
      seededRng(daySeed + 22),
      40
    )
  );

  // Yalnız İşaretler.
  add(
    'sadece-isaretler',
    'Yalnız Trafik İşaretleri',
    'Trafik işaretleri temalı sorular.',
    '🚦',
    pick(
      pool.filter((q) => q.primaryTheme === 'trafik-isaretleri' || q.topic === 'isaretler'),
      seededRng(daySeed + 33),
      40
    )
  );

  // Yalnız Motor.
  add(
    'sadece-motor',
    'Yalnız Araç Tekniği',
    'Motor ve araç tekniği soruları.',
    '🔧',
    pick(
      pool.filter((q) => q.subject === 'motor'),
      seededRng(daySeed + 44),
      40
    )
  );

  // Yalnız İlk Yardım.
  add(
    'sadece-ilkyardim',
    'Yalnız İlk Yardım',
    'İlk yardım bilgisi soruları.',
    '🚑',
    pick(
      pool.filter((q) => q.subject === 'ilkyardim'),
      seededRng(daySeed + 55),
      40
    )
  );

  // En Çok Yanılan — istatistik varsa başarısızlık oranına göre; yoksa zorluk+süre.
  const mostFailed = mostFailedIds(pool, opts.stats, 40);
  add(
    'en-cok-yanilan',
    'En Çok Yanılan',
    opts.stats?.length
      ? 'Kullanıcıların en çok yanıldığı sorular.'
      : 'En zorlayıcı sorular (zorluk + tahmini süreye göre).',
    '⚠️',
    mostFailed
  );

  // Rastgele 50.
  add(
    'rastgele-50',
    'Rastgele 50',
    'Bankadan rastgele 50 soru.',
    '🎲',
    pick(pool, seededRng(daySeed + 66), 50)
  );

  // AI Challenge — en zor + görsel + çok-varyantlı karışımı.
  const challenge = pick(
    pool.filter((q) => q.difficulty === 'zor' || q.image || (q.qualityScore ?? 100) < 100),
    seededRng(daySeed + 77),
    30
  );
  add(
    'ai-challenge',
    'AI Challenge',
    'Zorluğu yüksek, karışık meydan okuma seti.',
    '🤖',
    challenge
  );

  return out;
}

/** En çok yanılan id'ler: istatistik varsa yanlış oranına göre; yoksa zorluk+süre yaklaşığı. */
function mostFailedIds(
  pool: AnalyzedQuestion[],
  stats: QuestionAnalytics[] | undefined,
  n: number
): string[] {
  if (stats && stats.length) {
    const byId = new Map(stats.map((s) => [s.questionId, s]));
    return [...pool]
      .filter((q) => byId.has(q.id) && (byId.get(q.id)!.attempts ?? 0) >= 3)
      .sort((a, b) => (byId.get(b.id)!.wrongRate ?? 0) - (byId.get(a.id)!.wrongRate ?? 0))
      .slice(0, n)
      .map((q) => q.id);
  }
  const rank = (q: AnalyzedQuestion) =>
    (q.difficulty === 'zor' ? 2 : q.difficulty === 'orta' ? 1 : 0) * 100 + q.estimatedSeconds;
  return [...pool]
    .sort((a, b) => rank(b) - rank(a))
    .slice(0, n)
    .map((q) => q.id);
}

/** id → koleksiyon çözümü (UI). */
export function collectionById(id: string, opts?: CollectionsOptions): CollectionSpec | undefined {
  return examCollections(opts).find((c) => c.id === id);
}
