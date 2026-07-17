'use client';

import { useEffect, useState } from 'react';
import { computeAchievements, earnedCount, type Achievement } from '@/lib/achievements';
import { loadAnswers, loadStreak, loadCounters, loadViewedLessons } from '@/lib/progress';
import { loadEntitlements } from '@/lib/payments';
import { totalXp, levelForXp, type LevelInfo } from '@/lib/gamification';
import { PageHeader, Section } from '@/components/ui/layout';
import {
  Card,
  Badge,
  Button,
  ProgressBar,
  ProgressRing,
  type Accent,
} from '@/components/ui/primitives';
import { HeroBanner } from '@/components/ui/patterns';
import { Icon } from '@/components/ui/icons';

interface State {
  list: Achievement[];
  xp: number;
  level: LevelInfo;
  streakBest: number;
  answered: number;
  correct: number;
}

/** Önerilen kartlarda dönen aksan paleti (salt sunum). */
const SUGGEST_ACCENTS: Accent[] = ['teal', 'amber', 'purple', 'blue', 'red', 'green'];

export default function BasarilarPage() {
  const [s, setS] = useState<State | null>(null);

  useEffect(() => {
    const answers = loadAnswers();
    const streak = loadStreak();
    const counters = loadCounters();
    const viewed = loadViewedLessons();
    const correct = answers.filter((a) => a.correct).length;
    const xp = totalXp({
      answers,
      streak,
      examsFinished: counters.examsFinished,
      lessonsViewed: viewed.length,
    });
    setS({
      list: computeAchievements({
        streakCurrent: streak.current,
        streakBest: streak.best,
        totalAnswers: answers.length,
        correctAnswers: correct,
        examsFinished: 0,
        packsOwned: loadEntitlements().length,
      }),
      xp,
      level: levelForXp(xp),
      streakBest: streak.best,
      answered: answers.length,
      correct,
    });
  }, []);

  if (!s) {
    return (
      <>
        <PageHeader
          title="Başarılar"
          emoji="🏆"
          subtitle="Çalıştıkça rozetler açılır — hepsi kutlama, hiçbiri baskı."
        />
        <div className="grid-auto" style={{ ['--grid-min' as string]: '220px' }} aria-busy="true">
          {[1, 2, 3].map((k) => (
            <div key={k} className="ui-card">
              <div className="skeleton" style={{ width: '50%', height: 20 }} />
            </div>
          ))}
        </div>
      </>
    );
  }

  const earned = earnedCount(s.list);
  const total = s.list.length;
  const locked = s.list.filter((a) => !a.earned);
  const overallPct = total > 0 ? Math.round((earned / total) * 100) : 0;
  const accPct = s.answered > 0 ? Math.round((s.correct / s.answered) * 100) : null;

  return (
    <>
      <PageHeader
        title="Başarılar"
        emoji="🏆"
        subtitle="Çalıştıkça rozetler açılır — hepsi kutlama, hiçbiri baskı."
        actions={
          <div style={{ display: 'flex', gap: 'var(--sp-3)', flexWrap: 'wrap' }}>
            <Card style={{ padding: 'var(--sp-3) var(--sp-4)', minWidth: 200 }}>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-2)',
                  marginBottom: 'var(--sp-2)',
                }}
              >
                <span style={{ color: 'var(--accent-amber)' }} aria-hidden>
                  <Icon name="trophy" size={18} />
                </span>
                <span style={{ fontSize: 'var(--fs-xs)', color: 'var(--text-3)' }}>
                  Toplam başarı
                </span>
                <strong>
                  {earned} / {total}
                </strong>
              </div>
              <ProgressBar value={overallPct} label="Başarı ilerlemesi" />
            </Card>
            <Card style={{ padding: 'var(--sp-3) var(--sp-4)', minWidth: 200 }}>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-2)',
                  marginBottom: 'var(--sp-2)',
                }}
              >
                <span style={{ color: 'var(--accent-teal)' }} aria-hidden>
                  <Icon name="flame" size={18} />
                </span>
                <span style={{ fontSize: 'var(--fs-xs)', color: 'var(--text-3)' }}>
                  Seviye {s.level.level}
                </span>
                <strong>{s.xp} XP</strong>
              </div>
              <ProgressBar value={Math.round(s.level.progress * 100)} label="Seviye ilerlemesi" />
            </Card>
          </div>
        }
      />

      <Section
        title={`Kazanılan başarılar (${earned}/${total})`}
        icon={<Icon name="trophy" size={18} />}
      >
        <div
          className="grid-auto"
          style={{ ['--grid-min' as string]: '210px' }}
          data-testid="achievements"
        >
          {s.list.map((a) => (
            <Card
              key={a.id}
              accent={a.earned ? 'teal' : undefined}
              style={a.earned ? undefined : { opacity: 0.6 }}
              data-testid={a.earned ? 'ach-earned' : 'ach-locked'}
            >
              <div
                style={{
                  display: 'flex',
                  alignItems: 'flex-start',
                  justifyContent: 'space-between',
                  gap: 'var(--sp-2)',
                }}
              >
                <span
                  style={{
                    fontSize: '1.7rem',
                    filter: a.earned ? undefined : 'grayscale(0.7)',
                  }}
                  aria-hidden
                >
                  {a.icon}
                </span>
                {a.earned && (
                  <Badge accent="teal">
                    <Icon name="check-circle" size={12} /> Kazanıldı
                  </Badge>
                )}
              </div>
              <h3 style={{ margin: 'var(--sp-2) 0 2px', fontSize: 'var(--fs-md)' }}>{a.title}</h3>
              <p className="muted" style={{ margin: 0, fontSize: 'var(--fs-sm)' }}>
                {a.desc}
              </p>
              {!a.earned && (
                <span
                  style={{
                    marginTop: 'var(--sp-3)',
                    color: 'var(--text-3)',
                    display: 'inline-flex',
                  }}
                  aria-label="Kilitli"
                >
                  <Icon name="lock" size={16} />
                </span>
              )}
            </Card>
          ))}
        </div>
      </Section>

      <Section title="Başarı istatistiklerin" icon={<Icon name="gauge" size={18} />}>
        <div className="exam-stats">
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Kazanılan</span>
            <strong className="exam-stat__value" style={{ color: 'var(--accent-teal)' }}>
              {earned}
            </strong>
            <span className="muted exam-stat__sub">
              {earned} / {total}
            </span>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Kilitli</span>
            <strong className="exam-stat__value">{total - earned}</strong>
            <span className="muted exam-stat__sub">Sonraki için çalış!</span>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">En uzun seri</span>
            <strong className="exam-stat__value" style={{ color: 'var(--accent-amber)' }}>
              {s.streakBest}
            </strong>
            <span className="muted exam-stat__sub">gün</span>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Ortalama doğruluk</span>
            <strong className="exam-stat__value">{accPct == null ? '—' : `%${accPct}`}</strong>
            <span className="muted exam-stat__sub">
              {s.answered > 0 ? `${s.answered} soru` : 'Henüz soru çözülmedi'}
            </span>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Toplam XP</span>
            <strong className="exam-stat__value" style={{ color: 'var(--accent-teal)' }}>
              {s.xp} XP
            </strong>
            <span className="muted exam-stat__sub">Seviye {s.level.level}</span>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Genel ilerleme</span>
            <span className="exam-stat__value">
              <ProgressRing value={overallPct} size={52} stroke={6}>
                <small>%{overallPct}</small>
              </ProgressRing>
            </span>
            <span className="muted exam-stat__sub">Tüm başarılar</span>
          </div>
        </div>
      </Section>

      {locked.length > 0 && (
        <Section title="Önerilen başarılar" icon={<Icon name="target" size={18} />}>
          <div className="grid-auto" style={{ ['--grid-min' as string]: '230px' }}>
            {locked.map((a, i) => (
              <Card key={a.id} accent={SUGGEST_ACCENTS[i % SUGGEST_ACCENTS.length]}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--sp-3)' }}>
                  <span style={{ fontSize: '1.4rem' }} aria-hidden>
                    {a.icon}
                  </span>
                  <div>
                    <h3 style={{ margin: 0, fontSize: 'var(--fs-md)' }}>{a.title}</h3>
                    <p className="muted" style={{ margin: '2px 0 0', fontSize: 'var(--fs-sm)' }}>
                      {a.desc}
                    </p>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </Section>
      )}

      <HeroBanner
        icon="trophy"
        accent="teal"
        title="Başarılarını kutla, yolculuğuna devam et!"
        text="Her rozet bir adım ileri. Tutarlılık senin en büyük gücün."
        action={
          <Button variant="primary" href="/calis">
            Çalışmaya devam et
            <Icon name="chevron-right" size={16} />
          </Button>
        }
      />
    </>
  );
}
