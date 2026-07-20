/**
 * QIP — Faz 3 · Soru Aileleri (BANK_QUESTİON Part 9).
 *
 * "Bir kavram → birçok varyant." Sorular birleşim-bul (union-find) ile ailelere kümelenir:
 *  (1) aynı ders + konu, (2) aynı öğrenme kazanımı (learningOutcome), (3) yakın-yineleme çiftleri.
 * Aileler ADAPTİF ÖĞRENMEYİ DESTEKLER: bir öğrenci zorlanınca aynı kavramın farklı varyantı sunulur
 * (`familyVariants`), en kaliteli soru temsilci seçilir. Saf/deterministik; bir kez kurulur.
 */
import { foldText } from '@ea/content-schema';
import { UnionFind } from './dedup';
import { analyzedQuestions, bankDedup, type AnalyzedQuestion } from './index';
import { themeLabel } from './categorize';

export interface Family {
  id: string;
  subject: string;
  topic: string;
  theme: string;
  /** İnsan-okur kavram etiketi (tema + konu). */
  concept: string;
  questionIds: string[];
  size: number;
  /** En yüksek kaliteli soru (varyant sunumunda öncelikli). */
  representativeId: string;
}

let _families: Family[] | null = null;
let _familyByQuestion: Map<string, Family> | null = null;

/** Aileleri kur (bir kez, önbellekli). */
export function buildFamilies(pool: AnalyzedQuestion[] = analyzedQuestions()): Family[] {
  if (_families && pool === analyzedQuestions()) return _families;

  const uf = new UnionFind(pool.length);
  const indexById = new Map<string, number>();
  pool.forEach((q, i) => indexById.set(q.id, i));

  // (1) aynı ders + konu
  const byTopic = new Map<string, number>();
  pool.forEach((q, i) => {
    const key = `${q.subject}::${q.topic}`;
    const first = byTopic.get(key);
    if (first !== undefined) uf.union(first, i);
    else byTopic.set(key, i);
  });

  // (2) aynı öğrenme kazanımı (özdeş objective → aynı kavram, konu farklı olsa da)
  const byOutcome = new Map<string, number>();
  pool.forEach((q, i) => {
    if (!q.learningOutcome) return;
    const key = `${q.subject}::${foldText(q.learningOutcome)}`;
    const first = byOutcome.get(key);
    if (first !== undefined) uf.union(first, i);
    else byOutcome.set(key, i);
  });

  // (3) yakın-yineleme köprüleri
  for (const p of bankDedup().topPairs) {
    const a = indexById.get(p.a);
    const b = indexById.get(p.b);
    if (a !== undefined && b !== undefined) uf.union(a, b);
  }

  // Kümeleri topla
  const groups = new Map<number, number[]>();
  pool.forEach((_, i) => {
    const r = uf.find(i);
    const g = groups.get(r);
    if (g) g.push(i);
    else groups.set(r, [i]);
  });

  const families: Family[] = [];
  for (const members of groups.values()) {
    const qs = members.map((i) => pool[i]!);
    // temsilci = en yüksek qualityScore (eşitlikte ilk)
    let rep = qs[0]!;
    for (const q of qs) if ((q.qualityScore ?? 0) > (rep.qualityScore ?? 0)) rep = q;
    families.push({
      id: `fam-${rep.subject}-${rep.topic}-${rep.id}`,
      subject: rep.subject,
      topic: rep.topic,
      theme: rep.primaryTheme,
      concept: `${themeLabel(rep.primaryTheme)} — ${rep.topic}`,
      questionIds: qs.map((q) => q.id),
      size: qs.length,
      representativeId: rep.id,
    });
  }
  families.sort((a, b) => b.size - a.size);

  if (pool === analyzedQuestions()) {
    _families = families;
    _familyByQuestion = new Map();
    for (const f of families) for (const id of f.questionIds) _familyByQuestion.set(id, f);
  }
  return families;
}

/** Bir sorunun ailesi. */
export function familyOf(questionId: string): Family | undefined {
  if (!_familyByQuestion) buildFamilies();
  return _familyByQuestion?.get(questionId);
}

/** Aynı ailedeki diğer varyantlar (adaptif öğrenme: farklı varyant sun). */
export function familyVariants(questionId: string, limit = 5): string[] {
  const f = familyOf(questionId);
  if (!f) return [];
  return f.questionIds.filter((id) => id !== questionId).slice(0, limit);
}

export interface FamilyStats {
  totalFamilies: number;
  multiVariant: number; // size > 1
  singletons: number;
  largestSize: number;
  avgSize: number;
  /** Çok-varyantlı ailelerdeki toplam soru (adaptif kapsam). */
  questionsInMultiVariant: number;
}

/** Aile istatistikleri — pano + rapor + testler için GERÇEK sayılar. */
export function familyStats(families: Family[] = buildFamilies()): FamilyStats {
  let multiVariant = 0;
  let singletons = 0;
  let largestSize = 0;
  let questionsInMultiVariant = 0;
  let total = 0;
  for (const f of families) {
    total += f.size;
    if (f.size > 1) {
      multiVariant++;
      questionsInMultiVariant += f.size;
    } else singletons++;
    if (f.size > largestSize) largestSize = f.size;
  }
  return {
    totalFamilies: families.length,
    multiVariant,
    singletons,
    largestSize,
    avgSize: families.length ? Math.round((total / families.length) * 10) / 10 : 0,
    questionsInMultiVariant,
  };
}
