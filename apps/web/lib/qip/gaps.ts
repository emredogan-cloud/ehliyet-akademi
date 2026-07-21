/**
 * QIP 2.0 — İçerik Genişletme · Faz 3 · Boşluk Analizi.
 *
 * Mevcut bankanın kapsamını (tema/kural/zorluk/işaret) ölçüt karşısında karşılaştırır ve EKSİK
 * konuları ÖNCELİĞE göre sıralar → Faz 4 özgün üretimin hedef listesi. GERÇEK ölçülen sayılar.
 */
import { analyzedQuestions } from './index';
import { THEMES } from './categorize';
import { DRIVING_RULES } from './knowledge';
import { buildGraph, neighbors } from './graph';
import { SIGNS } from '@/content/signs';

export interface Gap {
  kind: 'theme' | 'rule' | 'difficulty' | 'sign';
  key: string;
  label: string;
  current: number;
  target: number;
  /** Öncelik 0–100 (yüksek = daha acil). */
  priority: number;
  detail: string;
}

export interface GapReport {
  totalGaps: number;
  byKind: Record<string, number>;
  topGaps: Gap[];
  themeCoverage: Array<{ theme: string; label: string; count: number }>;
  ruleCoverage: { total: number; covered: number; uncovered: string[] };
  signCoverage: { total: number; withQuestions: number; withoutQuestions: number };
}

const THEME_TARGET = 30; // her özel tema için hedeflenen asgari soru
const RULE_TOPIC_TARGET = 3; // bir kural konusunun asgari soru kapsamı
const clampP = (n: number) => Math.max(0, Math.min(100, Math.round(n)));

/** Boşluk analizi — mevcut bankaya karşı (deterministik, gerçek sayılar). */
export function analyzeGaps(): GapReport {
  const pool = analyzedQuestions();
  const gaps: Gap[] = [];

  // Konu (topic) → soru sayısı; tema → soru sayısı.
  const byTopic = new Map<string, number>();
  const byTheme = new Map<string, number>();
  const bySubjectDiff = new Map<string, Record<string, number>>();
  for (const q of pool) {
    byTopic.set(q.topic, (byTopic.get(q.topic) ?? 0) + 1);
    byTheme.set(q.primaryTheme, (byTheme.get(q.primaryTheme) ?? 0) + 1);
    const d = bySubjectDiff.get(q.subject) ?? { kolay: 0, orta: 0, zor: 0 };
    d[q.difficulty] = (d[q.difficulty] ?? 0) + 1;
    bySubjectDiff.set(q.subject, d);
  }

  // 1) Tema boşlukları — özel temalar (THEMES) hedefin altındaysa.
  const themeCoverage: GapReport['themeCoverage'] = [];
  for (const theme of THEMES) {
    const count = byTheme.get(theme.id) ?? 0;
    themeCoverage.push({ theme: theme.id, label: theme.label, count });
    if (count < THEME_TARGET) {
      gaps.push({
        kind: 'theme',
        key: theme.id,
        label: theme.label,
        current: count,
        target: THEME_TARGET,
        priority: clampP(((THEME_TARGET - count) / THEME_TARGET) * 70 + 20),
        detail: `${count}/${THEME_TARGET} soru`,
      });
    }
  }
  themeCoverage.sort((a, b) => a.count - b.count);

  // 2) Kural boşlukları — bir kural olgusunun konularında soru kapsamı yetersizse.
  const uncovered: string[] = [];
  let covered = 0;
  for (const rule of DRIVING_RULES) {
    const cov = rule.topics.reduce((a, t) => a + (byTopic.get(t) ?? 0), 0);
    if (cov >= RULE_TOPIC_TARGET) covered++;
    else {
      uncovered.push(rule.id);
      gaps.push({
        kind: 'rule',
        key: rule.id,
        label: rule.statement.slice(0, 60),
        current: cov,
        target: RULE_TOPIC_TARGET,
        priority: clampP(cov === 0 ? 95 : 70), // hiç kapsanmayan kural en acil
        detail: `${rule.value ? rule.value + ' · ' : ''}${cov}/${RULE_TOPIC_TARGET} soru`,
      });
    }
  }

  // 3) Zorluk dengesi boşlukları — bir derste bir zorluk %10'un altındaysa.
  for (const [subject, d] of bySubjectDiff) {
    const total = d.kolay! + d.orta! + d.zor!;
    for (const level of ['kolay', 'zor'] as const) {
      const frac = total ? d[level]! / total : 0;
      if (frac < 0.1) {
        gaps.push({
          kind: 'difficulty',
          key: `${subject}-${level}`,
          label: `${subject} · ${level} zorluk`,
          current: d[level]!,
          target: Math.ceil(total * 0.1),
          priority: clampP((0.1 - frac) * 300),
          detail: `${d[level]}/${total} (%${Math.round(frac * 100)})`,
        });
      }
    }
  }

  // 4) İşaret boşlukları — hiç sorusu olmayan trafik işaretleri (grafik üzerinden).
  const g = buildGraph();
  let signWith = 0;
  const signGapKeys: string[] = [];
  for (const s of SIGNS) {
    const qs = neighbors(`sign:${s.id}`, { nodeType: 'question' }, g);
    if (qs.length > 0) signWith++;
    else signGapKeys.push(s.id);
  }
  // İşaret boşluklarını tek bir toplu boşluk olarak da ekleyelim (öncelik orta).
  if (signGapKeys.length > 0) {
    gaps.push({
      kind: 'sign',
      key: 'signs-uncovered',
      label: 'Sorusu olmayan trafik işaretleri',
      current: signWith,
      target: SIGNS.length,
      priority: clampP((signGapKeys.length / SIGNS.length) * 60 + 15),
      detail: `${signGapKeys.length}/${SIGNS.length} işaretin sorusu yok`,
    });
  }

  gaps.sort((a, b) => b.priority - a.priority);
  const byKind: Record<string, number> = {};
  for (const gp of gaps) byKind[gp.kind] = (byKind[gp.kind] ?? 0) + 1;

  return {
    totalGaps: gaps.length,
    byKind,
    topGaps: gaps.slice(0, 25),
    themeCoverage,
    ruleCoverage: { total: DRIVING_RULES.length, covered, uncovered },
    signCoverage: {
      total: SIGNS.length,
      withQuestions: signWith,
      withoutQuestions: signGapKeys.length,
    },
  };
}
