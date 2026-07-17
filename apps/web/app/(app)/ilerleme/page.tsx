'use client';

/**
 * İlerleme & Motivasyon panosu (Sprint 6) — XP/seviye, hedefler, ısı haritası, içgörüler,
 * öğrenme yolculuğu, başarı vitrini, kademe (lider tablosu), günün meydan okuması, davet.
 * Hepsi kullanıcının KENDİ verisinden; uydurma yok.
 * Görsel dil: new-image/021-022 (navy + teal design system) — salt sunum katmanı.
 */
import { useEffect, useState } from 'react';
import {
  loadAnswers,
  loadStreak,
  loadCards,
  loadCounters,
  loadViewedLessons,
} from '@/lib/progress';
import { computeAchievements, earnedCount, type Achievement } from '@/lib/achievements';
import { loadEntitlements } from '@/lib/payments';
import {
  totalXp,
  levelForXp,
  dailyGoal,
  weeklyGoal,
  studyHeatmap,
  learningJourney,
  type GamificationInput,
  type Goal,
  type LevelInfo,
  type HeatCell,
  type JourneyStep,
} from '@/lib/gamification';
import {
  tierForXp,
  dailyChallenge,
  getOrCreateReferralCode,
  referralLink,
  type TierStanding,
  type DailyChallenge,
} from '@/lib/community';
import { learningInsights, type Insight } from '@/lib/insights';
import { StudyHeatmap } from '@/components/StudyHeatmap';
import { PageHeader, Section } from '@/components/ui/layout';
import {
  Card,
  Button,
  IconBadge,
  Badge,
  ProgressBar,
  ProgressRing,
  type Accent,
} from '@/components/ui/primitives';
import { HeroBanner } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';

interface State {
  level: LevelInfo;
  tier: TierStanding;
  daily: Goal;
  weekly: Goal;
  grid: HeatCell[][];
  journey: JourneyStep[];
  insights: Insight[];
  achievements: Achievement[];
  challenge: DailyChallenge;
  streakBest: number;
  answered: number;
  correct: number;
}

/** İçgörü tonu → kart aksanı (salt sunum eşlemesi). */
const TONE_ACCENT: Record<Insight['tone'], Accent> = {
  good: 'green',
  warn: 'amber',
  info: 'blue',
};

export default function IlerlemePage() {
  const [s, setS] = useState<State | null>(null);
  const [refLink, setRefLink] = useState('');
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const answers = loadAnswers();
    const streak = loadStreak();
    const cards = loadCards();
    const counters = loadCounters();
    const viewed = loadViewedLessons();
    const now = Date.now();
    const input: GamificationInput = {
      answers,
      streak,
      examsFinished: counters.examsFinished,
      lessonsViewed: viewed.length,
    };
    const xp = totalXp(input);
    setS({
      level: levelForXp(xp),
      tier: tierForXp(xp),
      daily: dailyGoal(answers, 15, now),
      weekly: weeklyGoal(answers, 75, now),
      grid: studyHeatmap(answers, 13, now),
      journey: learningJourney(input),
      insights: learningInsights(answers, streak, cards, now),
      achievements: computeAchievements({
        streakCurrent: streak.current,
        streakBest: streak.best,
        totalAnswers: answers.length,
        correctAnswers: answers.filter((a) => a.correct).length,
        examsFinished: counters.examsFinished,
        packsOwned: loadEntitlements().length,
      }),
      challenge: dailyChallenge(now),
      streakBest: streak.best,
      answered: answers.length,
      correct: answers.filter((a) => a.correct).length,
    });
    const code = getOrCreateReferralCode();
    setRefLink(referralLink(window.location.origin, code));
  }, []);

  async function copyRef() {
    try {
      await navigator.clipboard.writeText(refLink);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      /* pano yok */
    }
  }

  if (!s) {
    return (
      <div className="grid-auto" style={{ ['--grid-min' as string]: '220px' }} aria-busy="true">
        {[1, 2, 3].map((k) => (
          <div key={k} className="ui-card">
            <div className="skeleton" style={{ width: '50%', height: 20 }} />
            <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 12 }} />
          </div>
        ))}
      </div>
    );
  }

  const accPct = s.answered > 0 ? Math.round((s.correct / s.answered) * 100) : null;

  const GoalCard = ({
    label,
    icon,
    accent,
    g,
  }: {
    label: string;
    icon: IconName;
    accent: Accent;
    g: Goal;
  }) => {
    const pct = g.target > 0 ? Math.round((g.done / g.target) * 100) : 0;
    return (
      <Card>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--sp-4)' }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 'var(--sp-2)',
                marginBottom: 'var(--sp-3)',
              }}
            >
              <IconBadge accent={accent} size="sm">
                <Icon name={icon} size={16} />
              </IconBadge>
              <strong>{label}</strong>
            </div>
            <ProgressBar value={Math.min(100, pct)} label={label} />
            <div
              className="muted"
              style={{
                marginTop: 'var(--sp-2)',
                fontSize: 'var(--fs-sm)',
                display: 'inline-flex',
                alignItems: 'center',
                gap: 6,
              }}
            >
              {g.done}/{g.target}
              {g.met && (
                <span
                  style={{ color: 'var(--accent-green)', display: 'inline-flex' }}
                  aria-label="Hedef tamamlandı"
                >
                  <Icon name="check-circle" size={14} />
                </span>
              )}
            </div>
          </div>
          <ProgressRing value={Math.min(100, pct)} size={56} stroke={6} accent={accent}>
            <small>%{pct}</small>
          </ProgressRing>
        </div>
      </Card>
    );
  };

  return (
    <div data-testid="ilerleme">
      <PageHeader
        title="İlerleme"
        emoji="📈"
        subtitle="XP, seviye, hedefler ve çalışma haritan — hepsi senin verinden."
        actions={
          // Üretilmiş başlık dekoru (ASSET A10)
          <img src="/assets/ui/progress-hero.webp" alt="" className="page-decor" aria-hidden />
        }
      />

      {/* XP + Seviye + Kademe */}
      <Card accent="teal" className="level-hero">
        <div style={{ flex: 1, minWidth: 240 }}>
          <div style={{ fontSize: 'var(--fs-sm)', color: 'var(--text-3)' }}>
            Seviye {s.level.level}
          </div>
          <div
            style={{ fontSize: 'var(--fs-2xl)', fontWeight: 800, lineHeight: 1.2 }}
            data-testid="level-title"
          >
            {s.level.title}
          </div>
          <div style={{ margin: 'var(--sp-3) 0 var(--sp-2)', maxWidth: 360 }}>
            <ProgressBar value={Math.round(s.level.progress * 100)} label="Seviye ilerlemesi" />
          </div>
          <div className="muted" style={{ fontSize: 'var(--fs-sm)' }}>
            {s.level.xp} XP · sonraki seviyeye{' '}
            {Math.max(0, s.level.xpForNext - s.level.xpIntoLevel)} XP
          </div>
        </div>
        <div style={{ textAlign: 'center', display: 'grid', justifyItems: 'center', gap: 4 }}>
          <IconBadge accent="amber" size="lg">
            <Icon name="trophy" size={26} />
          </IconBadge>
          <div style={{ fontWeight: 700 }}>{s.tier.current.name}</div>
          <div className="muted" style={{ fontSize: 'var(--fs-xs)' }}>
            {s.tier.next ? `${s.tier.toNext} XP → ${s.tier.next.name}` : 'En üst kademe'}
          </div>
        </div>
      </Card>

      {/* Günün meydan okuması */}
      <Section>
        <HeroBanner
          icon="flame"
          accent="teal"
          title={`Günün meydan okuması: ${s.challenge.title}`}
          text={s.challenge.detail}
          action={
            <Button variant="primary" href={s.challenge.href}>
              Başla
              <Icon name="chevron-right" size={16} />
            </Button>
          }
          data-testid="daily-challenge"
        />
      </Section>

      {/* Hedefler */}
      <Section title="Hedefler" icon={<Icon name="target" size={18} />}>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '300px' }}>
          <GoalCard label="Günlük hedef" icon="target" accent="teal" g={s.daily} />
          <GoalCard label="Haftalık hedef" icon="calendar" accent="blue" g={s.weekly} />
        </div>
      </Section>

      {/* Isı haritası + özet istatistikler */}
      <Section title="Çalışma haritası (son 13 hafta)" icon={<Icon name="calendar" size={18} />}>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '320px' }}>
          <Card>
            <StudyHeatmap grid={s.grid} />
          </Card>
          <div className="exam-stats" style={{ margin: 0 }}>
            <div className="ui-card exam-stat">
              <span style={{ display: 'flex', justifyContent: 'center' }} aria-hidden>
                <IconBadge accent="amber" size="sm">
                  <Icon name="flame" size={16} />
                </IconBadge>
              </span>
              <span className="exam-stat__label">En uzun seri</span>
              <strong className="exam-stat__value" style={{ color: 'var(--accent-amber)' }}>
                {s.streakBest} gün
              </strong>
            </div>
            <div className="ui-card exam-stat">
              <span style={{ display: 'flex', justifyContent: 'center' }} aria-hidden>
                <IconBadge accent="blue" size="sm">
                  <Icon name="clipboard" size={16} />
                </IconBadge>
              </span>
              <span className="exam-stat__label">Çözülen soru</span>
              <strong className="exam-stat__value">{s.answered.toLocaleString('tr-TR')}</strong>
            </div>
            <div className="ui-card exam-stat">
              <span style={{ display: 'flex', justifyContent: 'center' }} aria-hidden>
                <IconBadge accent="red" size="sm">
                  <Icon name="target" size={16} />
                </IconBadge>
              </span>
              <span className="exam-stat__label">Doğru oranı</span>
              <strong className="exam-stat__value" style={{ color: 'var(--accent-teal)' }}>
                {accPct == null ? '—' : `%${accPct}`}
              </strong>
            </div>
          </div>
        </div>
      </Section>

      {/* İçgörüler */}
      <Section title="İçgörüler" icon={<Icon name="brain" size={18} />}>
        <div
          className="grid-auto"
          style={{ ['--grid-min' as string]: '240px' }}
          data-testid="insights"
        >
          {s.insights.map((i, k) => (
            <Card accent={TONE_ACCENT[i.tone]} key={k}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 'var(--sp-3)' }}>
                <IconBadge accent={TONE_ACCENT[i.tone]} size="md">
                  <span style={{ fontSize: '1.1rem' }}>{i.icon}</span>
                </IconBadge>
                <div>
                  <strong>{i.title}</strong>
                  <p className="muted" style={{ margin: '4px 0 0', fontSize: 'var(--fs-sm)' }}>
                    {i.detail}
                  </p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </Section>

      {/* Öğrenme yolculuğu */}
      <Section title="Öğrenme yolculuğu" icon={<Icon name="map" size={18} />}>
        <Card>
          <ol
            data-testid="journey"
            style={{
              listStyle: 'none',
              margin: 0,
              padding: 0,
              display: 'flex',
              flexWrap: 'wrap',
              gap: 'var(--sp-4) var(--sp-5)',
            }}
          >
            {s.journey.map((j, k) => (
              <li
                key={k}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-2)',
                  fontSize: 'var(--fs-sm)',
                  fontWeight: j.done ? 600 : 400,
                  color: j.done ? 'var(--text)' : 'var(--text-3)',
                  opacity: j.done ? 1 : 0.65,
                }}
              >
                <IconBadge accent="teal" size="sm">
                  <Icon name={j.done ? 'check-circle' : 'lock'} size={14} />
                </IconBadge>
                {j.label}
              </li>
            ))}
          </ol>
        </Card>
      </Section>

      {/* Başarı vitrini */}
      <Section
        title={`Başarılar (${earnedCount(s.achievements)}/${s.achievements.length})`}
        icon={<Icon name="trophy" size={18} />}
      >
        <div className="grid-auto" style={{ ['--grid-min' as string]: '210px' }}>
          {s.achievements.map((a) => (
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
                  style={{ fontSize: '1.7rem', filter: a.earned ? undefined : 'grayscale(0.7)' }}
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

      {/* Davet */}
      <Section title="Arkadaşını davet et" icon={<Icon name="rocket" size={18} />}>
        <HeroBanner
          icon="rocket"
          accent="teal"
          title="Bağlantını paylaş — birlikte çalışmak motivasyonu artırır."
          text="Global lider tablosu ve arkadaş sistemi sunucu bağlanınca açılır."
          action={
            <div
              style={{
                display: 'flex',
                gap: 'var(--sp-3)',
                flexWrap: 'wrap',
                alignItems: 'center',
              }}
            >
              <code
                style={{
                  padding: '8px 12px',
                  background: 'var(--surface-3)',
                  borderRadius: 8,
                  wordBreak: 'break-all',
                }}
              >
                {refLink}
              </code>
              <Button variant="primary" size="sm" onClick={copyRef} data-testid="copy-ref">
                {copied ? 'Kopyalandı ✓' : 'Kopyala'}
              </Button>
            </div>
          }
        />
      </Section>
    </div>
  );
}
