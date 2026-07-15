/**
 * Akıllı bildirimler (ROADMAP Faz 35 · Sprint 6) — GİZLİLİK-DOSTU uygulama-içi dürtmeler.
 * Saf ve test edilebilir. OS/push bildirimi YOK (SW push + backend gerektirir → gelecek mimarisi);
 * bunun yerine kullanıcının kendi verisinden nazik, zamanında hatırlatmalar.
 */
import { isDue, type SrsCard } from '@ea/srs-engine';
import type { AnswerLog, StreakState } from './progress';

export interface Nudge {
  id: string;
  icon: string;
  text: string;
  href: string;
  tone: 'good' | 'warn' | 'info';
}

function dayKey(t: number): string {
  const d = new Date(t);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/** Bağlama göre 0-3 dürtme üret (en önemli önce). */
export function computeNudges(
  answers: AnswerLog[],
  streak: StreakState,
  cards: Map<string, SrsCard>,
  now = Date.now()
): Nudge[] {
  const out: Nudge[] = [];
  const today = dayKey(now);
  const yesterday = dayKey(now - 86_400_000);
  const studiedToday = answers.some((a) => dayKey(a.at) === today);

  let due = 0;
  for (const c of cards.values()) if (isDue(c, now)) due += 1;

  // 1) Seri riski: dün çalışmış, bugün henüz çalışmamış → serini koru
  if (streak.current >= 2 && streak.lastDay === yesterday && !studiedToday) {
    out.push({
      id: 'streak-risk',
      icon: '🔥',
      text: `${streak.current} günlük serini koru — bugün kısa bir çalışma yeter.`,
      href: '/calis',
      tone: 'warn',
    });
  }

  // 2) Vadesi gelen tekrarlar
  if (due > 0) {
    out.push({
      id: 'due-cards',
      icon: '🔁',
      text: `${due} kartın tekrar zamanı geldi.`,
      href: '/calis?mod=tekrar',
      tone: 'info',
    });
  }

  // 3) Bugün hiç çalışılmadıysa nazik başlangıç
  if (!studiedToday && out.length < 2) {
    out.push({
      id: 'start-today',
      icon: '🎯',
      text: 'Bugün 10 soruyla başla — küçük adımlar büyük fark yaratır.',
      href: '/calis',
      tone: 'info',
    });
  }

  return out.slice(0, 3);
}
