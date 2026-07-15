'use client';

/** Akıllı dürtme bannerı (Sprint 6) — kullanıcının kendi verisinden en önemli 1 nazik hatırlatma. */
import { useEffect, useState } from 'react';
import { loadAnswers, loadStreak, loadCards } from '@/lib/progress';
import { computeNudges, type Nudge } from '@/lib/notifications';

export function NudgeBanner() {
  const [nudge, setNudge] = useState<Nudge | null>(null);

  useEffect(() => {
    const list = computeNudges(loadAnswers(), loadStreak(), loadCards(), Date.now());
    setNudge(list[0] ?? null);
  }, []);

  if (!nudge) return null;
  return (
    <div
      className={`nudge ${nudge.tone === 'warn' ? 'nudge--warn' : ''}`}
      data-testid="nudge"
      role="status"
    >
      <span aria-hidden style={{ fontSize: '1.3rem' }}>
        {nudge.icon}
      </span>
      <span className="nudge__text">{nudge.text}</span>
      <a className="btn btn--sm" href={nudge.href}>
        Başla
      </a>
    </div>
  );
}
