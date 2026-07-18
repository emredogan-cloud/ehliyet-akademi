'use client';

/**
 * Akıllı dürtme bannerı (Sprint 6 · Program 3 Faz F redesign) —
 * kullanıcının kendi verisinden en önemli 1 nazik hatırlatma.
 * Referans 003-panel hero bandı görünümü: aksan kart + ikon rozeti + metin + Başla.
 */
import { useEffect, useState } from 'react';
import { loadAnswers, loadStreak, loadCards } from '@/lib/progress';
import { computeNudges, type Nudge } from '@/lib/notifications';
import { Card, IconBadge, Button, type Accent } from '@/components/ui/primitives';

export function NudgeBanner() {
  const [nudge, setNudge] = useState<Nudge | null>(null);

  useEffect(() => {
    const list = computeNudges(loadAnswers(), loadStreak(), loadCards(), Date.now());
    setNudge(list[0] ?? null);
  }, []);

  if (!nudge) return null;
  const accent: Accent = nudge.tone === 'warn' ? 'amber' : 'teal';
  return (
    <Card accent={accent} className="hero-banner" data-testid="nudge" role="status">
      <IconBadge accent={accent} size="lg">
        {nudge.icon}
      </IconBadge>
      <div className="hero-banner__body">
        <div className="hero-banner__title">{nudge.text}</div>
      </div>
      <div className="hero-banner__art" aria-hidden>
        {/* Üretilmiş panel araç görseli (ASSET A2 / 003-B) */}
        <img src="/assets/art/car-shield.webp" alt="" className="nudge-art" />
      </div>
      <div className="hero-banner__action">
        <Button variant="primary" href={nudge.href}>
          Başla →
        </Button>
      </div>
    </Card>
  );
}
