/**
 * İstemci ilerleme deposu (ROADMAP Faz 9/34) — SRS kartları, cevap geçmişi, seri (streak).
 * ADR-004 gereği arayüz sağlayıcı-agnostiktir; auth+DB geldiğinde aynı arayüz sunucuya bağlanır.
 */
import type { Subject } from '@ea/content-schema';
import type { SrsCard } from '@ea/srs-engine';
import { syncSet } from './authClient';

const CARDS_KEY = 'ea:cards:v1';
const ANSWERS_KEY = 'ea:answers:v1';
const STREAK_KEY = 'ea:streak:v1';

export interface AnswerLog {
  questionId: string;
  subject: Subject;
  topic: string;
  correct: boolean;
  at: number;
}

export interface StreakState {
  current: number;
  best: number;
  lastDay: string; // YYYY-MM-DD
}

function safeGet<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;
  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}
function safeSet(key: string, value: unknown): void {
  if (typeof window === 'undefined') return;
  // Sprint 1: yerel + (girişliyse) sunucu senkronu tek noktadan.
  syncSet(key, value);
}

/* ---- SRS kartları ---- */
export function loadCards(): Map<string, SrsCard> {
  const obj = safeGet<Record<string, SrsCard>>(CARDS_KEY, {});
  return new Map(Object.entries(obj));
}
export function saveCards(cards: Map<string, SrsCard>): void {
  safeSet(CARDS_KEY, Object.fromEntries(cards));
}

/* ---- Cevap geçmişi ---- */
export function loadAnswers(): AnswerLog[] {
  return safeGet<AnswerLog[]>(ANSWERS_KEY, []);
}
export function appendAnswers(logs: AnswerLog[]): void {
  const all = [...loadAnswers(), ...logs];
  // Sınırsız büyümeyi önle: son 2000 kayıt yeter (istatistik için bol).
  safeSet(ANSWERS_KEY, all.slice(-2000));
}

/* ---- Seri (streak) — Faz 34 alışkanlık temeli ---- */
function dayKey(t: number): string {
  const d = new Date(t);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
export function loadStreak(): StreakState {
  return safeGet<StreakState>(STREAK_KEY, { current: 0, best: 0, lastDay: '' });
}
/** Bugün çalışıldı olarak işaretle; ardışık gün mantığıyla seriyi güncelle. */
export function touchStreak(now = Date.now()): StreakState {
  const s = loadStreak();
  const today = dayKey(now);
  if (s.lastDay === today) return s; // bugün zaten sayıldı
  const yesterday = dayKey(now - 86_400_000);
  const current = s.lastDay === yesterday ? s.current + 1 : 1;
  const next: StreakState = { current, best: Math.max(s.best, current), lastDay: today };
  safeSet(STREAK_KEY, next);
  return next;
}

/* ---- Sayaçlar + görülen dersler (Sprint 6 oyunlaştırma; gerçek veriden XP) ---- */
const COUNTERS_KEY = 'ea:counters:v1';
const VIEWED_KEY = 'ea:lessonsViewed:v1';

export interface Counters {
  examsFinished: number;
}
export function loadCounters(): Counters {
  return safeGet<Counters>(COUNTERS_KEY, { examsFinished: 0 });
}
export function incrementExamsFinished(): Counters {
  const c = loadCounters();
  const next = { ...c, examsFinished: (c.examsFinished ?? 0) + 1 };
  safeSet(COUNTERS_KEY, next);
  return next;
}

export function loadViewedLessons(): string[] {
  return safeGet<string[]>(VIEWED_KEY, []);
}
export function markLessonViewed(slug: string): void {
  const cur = loadViewedLessons();
  if (!cur.includes(slug)) safeSet(VIEWED_KEY, [...cur, slug]);
}
