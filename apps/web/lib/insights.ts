/**
 * Öğrenme içgörüleri (ROADMAP Faz 35 · Sprint 6) — kullanıcının KENDİ verisinden çıkarımlar.
 * Saf, test edilebilir; hiçbir çıkarım platform dışı kaynaktan gelmez (grounded).
 */
import { statsFromAnswers, isDue, type SrsCard } from '@ea/srs-engine';
import { SUBJECT_LABEL, type Subject } from '@ea/content-schema';
import type { AnswerLog, StreakState } from './progress';

export interface Insight {
  icon: string;
  title: string;
  detail: string;
  tone: 'good' | 'warn' | 'info';
}

function dayKey(t: number): string {
  const d = new Date(t);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

export function learningInsights(
  answers: AnswerLog[],
  streak: StreakState,
  cards: Map<string, SrsCard>,
  now = Date.now()
): Insight[] {
  const out: Insight[] = [];
  if (answers.length === 0) {
    return [
      {
        icon: '🧭',
        title: 'Başlangıç',
        detail: 'Kısa bir tanı denemesiyle başla; içgörüler cevapladıkça oluşur.',
        tone: 'info',
      },
    ];
  }

  const { subjects } = statsFromAnswers(answers);
  const rated = subjects.filter((s) => s.subject !== 'pratik' && s.answered >= 3);
  if (rated.length) {
    const best = [...rated].sort((a, b) => b.mastery - a.mastery)[0]!;
    const worst = [...rated].sort((a, b) => a.mastery - b.mastery)[0]!;
    out.push({
      icon: '💪',
      title: `En güçlü dersin: ${SUBJECT_LABEL[best.subject as Subject]}`,
      detail: `Ustalık %${Math.round(best.mastery * 100)}. Güçlü yanını koru.`,
      tone: 'good',
    });
    if (worst.subject !== best.subject) {
      out.push({
        icon: '🎯',
        title: `Odak: ${SUBJECT_LABEL[worst.subject as Subject]}`,
        detail: `Ustalık %${Math.round(worst.mastery * 100)}. En çok kazanç burada.`,
        tone: 'warn',
      });
    }
  }

  // Doğruluk eğilimi: son 20 vs önceki
  if (answers.length >= 20) {
    const sorted = [...answers].sort((a, b) => a.at - b.at);
    const recent = sorted.slice(-20);
    const older = sorted.slice(0, -20);
    const accR = recent.filter((a) => a.correct).length / recent.length;
    const accO = older.length ? older.filter((a) => a.correct).length / older.length : accR;
    if (accR - accO >= 0.05)
      out.push({
        icon: '📈',
        title: 'Yükselen grafik',
        detail: `Son sorularında doğruluğun %${Math.round(accO * 100)} → %${Math.round(accR * 100)} arttı.`,
        tone: 'good',
      });
    else if (accO - accR >= 0.08)
      out.push({
        icon: '📉',
        title: 'Hız kesme',
        detail: 'Son sorularında doğruluğun biraz düştü — kısa bir tekrar iyi gelir.',
        tone: 'warn',
      });
  }

  // Tutarlılık (seri)
  if (streak.current >= 3)
    out.push({
      icon: '🔥',
      title: `${streak.current} günlük seri`,
      detail: 'Düzenli çalışma kalıcılığı en çok artıran şeydir. Devam!',
      tone: 'good',
    });

  // Vadesi gelen tekrarlar
  let due = 0;
  for (const c of cards.values()) if (isDue(c, now)) due += 1;
  if (due > 0)
    out.push({
      icon: '🔁',
      title: `${due} kart tekrar zamanı`,
      detail: 'Aralıklı tekrar unutmayı önler — bugün gözden geçir.',
      tone: 'info',
    });

  // Tempo (son 7 gün)
  const weekAgo = now - 6 * 86_400_000;
  const activeDays = new Set(answers.filter((a) => a.at >= weekAgo).map((a) => dayKey(a.at))).size;
  out.push({
    icon: '📅',
    title: `Bu hafta ${activeDays}/7 gün aktif`,
    detail:
      activeDays >= 5
        ? 'Harika bir tempo — sınav formunda kalıyorsun.'
        : 'Haftada 5+ gün kısa çalışma en verimlisidir.',
    tone: activeDays >= 5 ? 'good' : 'info',
  });

  return out;
}
