/**
 * Başarılar (ROADMAP Faz 34 — alışkanlık döngüsü). Saf türetme: mevcut
 * istatistiklerden rozetler; karanlık desen yok (kayıp-korkusu değil, kutlama).
 */

export interface AchievementInput {
  streakCurrent: number;
  streakBest: number;
  totalAnswers: number;
  correctAnswers: number;
  examsFinished: number;
  packsOwned: number;
}

export interface Achievement {
  id: string;
  title: string;
  desc: string;
  icon: string;
  earned: boolean;
}

export function computeAchievements(s: AchievementInput): Achievement[] {
  const acc = s.totalAnswers ? s.correctAnswers / s.totalAnswers : 0;
  return [
    {
      id: 'ilk-adim',
      icon: '🚀',
      title: 'İlk Adım',
      desc: 'İlk soruyu cevapla',
      earned: s.totalAnswers >= 1,
    },
    {
      id: 'isinan-motor',
      icon: '🔧',
      title: 'Isınan Motor',
      desc: '25 soru cevapla',
      earned: s.totalAnswers >= 25,
    },
    {
      id: 'yol-tutkunu',
      icon: '🛣️',
      title: 'Yol Tutkunu',
      desc: '100 soru cevapla',
      earned: s.totalAnswers >= 100,
    },
    {
      id: 'seri-3',
      icon: '🔥',
      title: '3 Gün Seri',
      desc: '3 gün üst üste çalış',
      earned: s.streakBest >= 3,
    },
    {
      id: 'seri-7',
      icon: '🏅',
      title: 'Haftalık Seri',
      desc: '7 gün üst üste çalış',
      earned: s.streakBest >= 7,
    },
    {
      id: 'ilk-deneme',
      icon: '📝',
      title: 'İlk Deneme',
      desc: 'Bir deneme sınavı bitir',
      earned: s.examsFinished >= 1,
    },
    {
      id: 'keskin-nisanci',
      icon: '🎯',
      title: 'Keskin Nişancı',
      desc: '%80+ doğruluk (min 20 soru)',
      earned: s.totalAnswers >= 20 && acc >= 0.8,
    },
    {
      id: 'yatirimci',
      icon: '⭐',
      title: 'Kararlı Aday',
      desc: 'Bir premium paket edin',
      earned: s.packsOwned >= 1,
    },
  ];
}

export function earnedCount(list: Achievement[]): number {
  return list.filter((a) => a.earned).length;
}
