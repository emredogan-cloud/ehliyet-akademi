'use client';

/**
 * İlerleme & Motivasyon panosu (Sprint 6) — XP/seviye, hedefler, ısı haritası, içgörüler,
 * öğrenme yolculuğu, başarı vitrini, kademe (lider tablosu), günün meydan okuması, davet.
 * Hepsi kullanıcının KENDİ verisinden; uydurma yok.
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
import { PageHeader } from '@/components/ui/layout';

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
}

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
      <div className="grid" aria-busy="true">
        {[1, 2, 3].map((k) => (
          <div key={k} className="card">
            <div className="skeleton" style={{ width: '50%', height: 20 }} />
            <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 12 }} />
          </div>
        ))}
      </div>
    );
  }

  const GoalBar = ({ label, g }: { label: string; g: Goal }) => (
    <div className="card" style={{ margin: 0 }}>
      <strong>{label}</strong>
      <div className="bar" aria-hidden style={{ margin: '8px 0 6px' }}>
        <span style={{ width: `${Math.round(g.progress * 100)}%` }} />
      </div>
      <p className="muted" style={{ margin: 0, fontSize: '0.85rem' }}>
        {g.done}/{g.target} {g.met ? '✅' : ''}
      </p>
    </div>
  );

  return (
    <div data-testid="ilerleme">
      <PageHeader
        title="İlerleme"
        emoji="📈"
        subtitle="XP, seviye, hedefler ve çalışma haritan — hepsi senin verinden."
      />

      {/* XP + Seviye + Kademe */}
      <div className="level-hero card" style={{ borderColor: 'var(--primary-100)' }}>
        <div>
          <div style={{ fontSize: '0.85rem', color: 'var(--text-3)' }}>Seviye {s.level.level}</div>
          <div style={{ fontSize: '1.5rem', fontWeight: 800 }} data-testid="level-title">
            {s.level.title}
          </div>
          <div className="bar" aria-hidden style={{ margin: '10px 0 6px', maxWidth: 360 }}>
            <span style={{ width: `${Math.round(s.level.progress * 100)}%` }} />
          </div>
          <div className="muted" style={{ fontSize: '0.85rem' }}>
            {s.level.xp} XP · sonraki seviyeye{' '}
            {Math.max(0, s.level.xpForNext - s.level.xpIntoLevel)} XP
          </div>
        </div>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '2.4rem', lineHeight: 1 }} aria-hidden>
            {s.tier.current.icon}
          </div>
          <div style={{ fontWeight: 700 }}>{s.tier.current.name}</div>
          <div className="muted" style={{ fontSize: '0.78rem' }}>
            {s.tier.next ? `${s.tier.toNext} XP → ${s.tier.next.name}` : 'En üst kademe'}
          </div>
        </div>
      </div>

      {/* Günün meydan okuması */}
      <div
        className="card"
        style={{
          marginTop: 14,
          background: 'var(--primary-050)',
          borderColor: 'var(--primary-100)',
        }}
        data-testid="daily-challenge"
      >
        <strong>🏁 Günün meydan okuması: {s.challenge.title}</strong>
        <p className="muted" style={{ margin: '6px 0 10px' }}>
          {s.challenge.detail}
        </p>
        <a className="btn btn--sm" href={s.challenge.href}>
          Başla →
        </a>
      </div>

      {/* Hedefler */}
      <h2 className="section-title">Hedefler</h2>
      <div className="plan-top">
        <GoalBar label="Günlük hedef" g={s.daily} />
        <GoalBar label="Haftalık hedef" g={s.weekly} />
      </div>

      {/* Isı haritası */}
      <h2 className="section-title">Çalışma haritası (son 13 hafta)</h2>
      <div className="card">
        <StudyHeatmap grid={s.grid} />
      </div>

      {/* İçgörüler */}
      <h2 className="section-title">İçgörüler</h2>
      <div className="grid" data-testid="insights">
        {s.insights.map((i, k) => (
          <div className="card" key={k}>
            <div style={{ fontSize: '1.4rem' }} aria-hidden>
              {i.icon}
            </div>
            <strong>{i.title}</strong>
            <p className="muted" style={{ margin: '4px 0 0', fontSize: '0.88rem' }}>
              {i.detail}
            </p>
          </div>
        ))}
      </div>

      {/* Öğrenme yolculuğu */}
      <h2 className="section-title">Öğrenme yolculuğu</h2>
      <ol className="journey" data-testid="journey">
        {s.journey.map((j, k) => (
          <li key={k} className={`journey__step ${j.done ? 'journey__step--done' : ''}`}>
            <span className="journey__dot" aria-hidden>
              {j.done ? '✓' : ''}
            </span>
            {j.label}
          </li>
        ))}
      </ol>

      {/* Başarı vitrini */}
      <h2 className="section-title">
        Başarılar ({earnedCount(s.achievements)}/{s.achievements.length})
      </h2>
      <div className="grid">
        {s.achievements.map((a) => (
          <div
            className="card"
            key={a.id}
            style={{ opacity: a.earned ? 1 : 0.55 }}
            data-testid={a.earned ? 'ach-earned' : 'ach-locked'}
          >
            <div style={{ fontSize: '1.6rem' }} aria-hidden>
              {a.earned ? a.icon : '🔒'}
            </div>
            <strong>{a.title}</strong>
            <p className="muted" style={{ margin: '2px 0 0', fontSize: '0.82rem' }}>
              {a.desc}
            </p>
          </div>
        ))}
      </div>

      {/* Davet */}
      <h2 className="section-title">Arkadaşını davet et</h2>
      <div className="card">
        <p className="muted" style={{ marginTop: 0 }}>
          Bağlantını paylaş — birlikte çalışmak motivasyonu artırır. (Global lider tablosu ve
          arkadaş sistemi sunucu bağlanınca açılır.)
        </p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
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
          <button className="btn btn--sm" onClick={copyRef} data-testid="copy-ref">
            {copied ? 'Kopyalandı ✓' : 'Kopyala'}
          </button>
        </div>
      </div>
    </div>
  );
}
