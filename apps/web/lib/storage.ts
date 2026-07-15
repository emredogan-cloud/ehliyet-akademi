/**
 * Yerel ilerleme deposu (ROADMAP Faz 4 — auth/DB gelene kadar mock/local katman).
 * ADR-004: sağlayıcı-agnostik; şimdilik LocalStorage. Sunucu hesabına geçişte aynı arayüz DB'ye bağlanır.
 */
import type { Subject, TrafficLight } from '@ea/srs-engine';
import { syncSet } from './authClient';

export interface StoredReadiness {
  overall: number;
  light: TrafficLight;
  predictedPassProbability: number;
  perSubject: Array<{ subject: Subject; mastery: number; light: TrafficLight }>;
  answered: number;
  correct: number;
  at: number;
}

const KEY = 'ea:readiness:v1';

export function saveReadiness(r: StoredReadiness): void {
  if (typeof window === 'undefined') return;
  syncSet(KEY, r);
}

export function loadReadiness(): StoredReadiness | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as StoredReadiness) : null;
  } catch {
    return null;
  }
}
