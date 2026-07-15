/**
 * Oyunlaştırma (ROADMAP Faz 34 · Sprint 6) — XP, seviye, günlük/haftalık hedef, çalışma ısı haritası,
 * öğrenme yolculuğu. Saf ve test edilebilir; hepsi GERÇEK ilerleme verisinden türetilir (uydurma yok).
 * Karanlık desen yok: motivasyon kutlamadır, kayıp-korkusu değil.
 */
import type { AnswerLog, StreakState } from './progress';

export const XP = {
  perCorrect: 10,
  perWrong: 3, // deneme de değerlidir
  perExam: 60,
  perStreakDay: 15,
  perLessonView: 8,
} as const;

export interface GamificationInput {
  answers: AnswerLog[];
  streak: StreakState;
  examsFinished: number;
  lessonsViewed: number;
}

export function totalXp(input: GamificationInput): number {
  const correct = input.answers.filter((a) => a.correct).length;
  const wrong = input.answers.length - correct;
  return (
    correct * XP.perCorrect +
    wrong * XP.perWrong +
    input.examsFinished * XP.perExam +
    input.streak.best * XP.perStreakDay +
    input.lessonsViewed * XP.perLessonView
  );
}

/* ---- Seviyeler ---- */
const LEVEL_TITLES = [
  'Acemi Sürücü',
  'Aday Sürücü',
  'Yol Bilgini',
  'Trafik Ustası',
  'Direksiyon Ustası',
  'Kural Bilgesi',
  'Yol Efsanesi',
];

/** n. seviyeye ulaşmak için gereken KÜMÜLATİF XP (L1=0, L2=100, L3=300, L4=600 …). */
export function xpToReach(level: number): number {
  return 50 * level * (level - 1);
}

export interface LevelInfo {
  level: number;
  title: string;
  xp: number;
  xpIntoLevel: number;
  xpForNext: number; // bu seviyeden sonrakine gereken toplam aralık
  progress: number; // 0..1
}

export function levelForXp(xp: number): LevelInfo {
  let level = 1;
  while (xpToReach(level + 1) <= xp) level += 1;
  const base = xpToReach(level);
  const next = xpToReach(level + 1);
  const xpForNext = next - base;
  const xpIntoLevel = xp - base;
  return {
    level,
    title: LEVEL_TITLES[Math.min(level - 1, LEVEL_TITLES.length - 1)]!,
    xp,
    xpIntoLevel,
    xpForNext,
    progress: xpForNext > 0 ? Math.min(1, xpIntoLevel / xpForNext) : 1,
  };
}

/* ---- Günlük / haftalık hedef ---- */
function dayKey(t: number): string {
  const d = new Date(t);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export interface Goal {
  target: number;
  done: number;
  met: boolean;
  progress: number;
}
function goal(done: number, target: number): Goal {
  return { target, done, met: done >= target, progress: Math.min(1, done / target) };
}

export function dailyGoal(answers: AnswerLog[], target = 15, now = Date.now()): Goal {
  const today = dayKey(now);
  const done = answers.filter((a) => dayKey(a.at) === today).length;
  return goal(done, target);
}

export function weeklyGoal(answers: AnswerLog[], target = 75, now = Date.now()): Goal {
  const weekAgo = now - 6 * 86_400_000;
  const done = answers.filter((a) => a.at >= weekAgo && a.at <= now + 86_400_000).length;
  return goal(done, target);
}

/* ---- Çalışma ısı haritası (GitHub tarzı) ---- */
export interface HeatCell {
  date: string;
  count: number;
  level: 0 | 1 | 2 | 3 | 4;
}
function intensity(count: number): HeatCell['level'] {
  if (count === 0) return 0;
  if (count <= 4) return 1;
  if (count <= 9) return 2;
  if (count <= 19) return 3;
  return 4;
}

/**
 * Son `weeks` haftanın günlük çalışma yoğunluğu. Sütun = hafta, satır = gün (Pazartesi=0).
 * Bugünle biten hizalı ızgara.
 */
export function studyHeatmap(answers: AnswerLog[], weeks = 13, now = Date.now()): HeatCell[][] {
  const perDay = new Map<string, number>();
  for (const a of answers) perDay.set(dayKey(a.at), (perDay.get(dayKey(a.at)) ?? 0) + 1);

  // Bugünün haftadaki günü (Pzt=0..Paz=6)
  const todayDow = (new Date(now).getDay() + 6) % 7;
  const totalDays = weeks * 7;
  const start = now - (totalDays - 1 - (6 - todayDow)) * 86_400_000; // ızgarayı hafta sınırına hizala
  const grid: HeatCell[][] = [];
  for (let w = 0; w < weeks; w++) {
    const col: HeatCell[] = [];
    for (let d = 0; d < 7; d++) {
      const t = start + (w * 7 + d) * 86_400_000;
      const key = dayKey(t);
      const count = t <= now ? (perDay.get(key) ?? 0) : -1; // gelecekteki günler boş
      col.push({ date: key, count: Math.max(0, count), level: count < 0 ? 0 : intensity(count) });
    }
    grid.push(col);
  }
  return grid;
}

/* ---- Öğrenme yolculuğu ---- */
export interface JourneyStep {
  label: string;
  done: boolean;
}
export function learningJourney(input: GamificationInput): JourneyStep[] {
  const answered = input.answers.length;
  const correct = input.answers.filter((a) => a.correct).length;
  const acc = answered ? correct / answered : 0;
  return [
    { label: 'İlk soruyu çöz', done: answered >= 1 },
    { label: 'İlk dersi oku', done: input.lessonsViewed >= 1 },
    { label: '50 soru çöz', done: answered >= 50 },
    { label: '3 günlük seri yakala', done: input.streak.best >= 3 },
    { label: 'İlk deneme sınavını bitir', done: input.examsFinished >= 1 },
    { label: '5 dersi tamamla', done: input.lessonsViewed >= 5 },
    { label: '200 soru çöz', done: answered >= 200 },
    { label: '%80 doğruluğa ulaş (100+ soru)', done: answered >= 100 && acc >= 0.8 },
  ];
}
