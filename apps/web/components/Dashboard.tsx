'use client';

/**
 * Panel (dashboard) — kabuğun ana ekranı (Program 3 · Faz F, referans 003-panel):
 * hero nudge · istatistik kartları · ders bazlı ustalık · hızlı aksiyonlar.
 */
import { useEffect, useState } from 'react';
import { SUBJECT_LABEL, THEORY_SUBJECTS, type TheorySubject } from '@ea/content-schema';
import { statsFromAnswers } from '@ea/srs-engine';
import { loadAnswers, loadStreak } from '@/lib/progress';
import { loadReadiness, type StoredReadiness } from '@/lib/storage';
import { loadEntitlements } from '@/lib/payments';
import { computeAchievements, earnedCount } from '@/lib/achievements';
import { NudgeBanner } from '@/components/NudgeBanner';
import { StatCard, ProgressBar, Card } from '@/components/ui/primitives';
import { Section, Grid } from '@/components/ui/layout';
import { ActionCard } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';
import type { Accent } from '@/components/ui/primitives';
import type { CSSProperties } from 'react';

const LIGHT_LABEL: Record<string, string> = {
  yesil: 'Hazır',
  sari: 'Gelişiyor',
  kirmizi: 'Çalışmalı',
};

const SUBJECT_META: Record<TheorySubject, { icon: IconName; accent: Accent }> = {
  trafik: { icon: 'trafficlight', accent: 'teal' },
  ilkyardim: { icon: 'firstaid', accent: 'red' },
  motor: { icon: 'car', accent: 'purple' },
  adab: { icon: 'road', accent: 'blue' },
};

type Bar = { subject: TheorySubject; label: string; pct: number; n: number };

export function Dashboard() {
  const [ready, setReady] = useState(false);
  const [r, setR] = useState<StoredReadiness | null>(null);
  const [streak, setStreak] = useState({ current: 0, best: 0 });
  const [subjectBars, setSubjectBars] = useState<Bar[]>([]);
  const [answered, setAnswered] = useState(0);
  const [earned, setEarned] = useState(0);
  const [packs, setPacks] = useState(0);

  useEffect(() => {
    const answers = loadAnswers();
    const s = loadStreak();
    const owned = loadEntitlements();
    setR(loadReadiness());
    setStreak({ current: s.current, best: s.best });
    setAnswered(answers.length);
    setPacks(owned.length);
    const { subjects } = statsFromAnswers(
      answers.map((a) => ({ subject: a.subject, topic: a.topic, correct: a.correct }))
    );
    setSubjectBars(
      THEORY_SUBJECTS.map((sub) => {
        const st = subjects.find((x) => x.subject === sub);
        return {
          subject: sub,
          label: SUBJECT_LABEL[sub],
          pct: st ? Math.round(st.mastery * 100) : 0,
          n: st?.answered ?? 0,
        };
      })
    );
    const correct = answers.filter((a) => a.correct).length;
    setEarned(
      earnedCount(
        computeAchievements({
          streakCurrent: s.current,
          streakBest: s.best,
          totalAnswers: answers.length,
          correctAnswers: correct,
          examsFinished: 0, // sınav sayısı ayrı loglanana dek muhafazakâr
          packsOwned: owned.length,
        })
      )
    );
    setReady(true);
  }, []);

  if (!ready) {
    return (
      <Grid preset="stats" aria-busy="true" aria-label="Yükleniyor">
        {[1, 2, 3, 4].map((k) => (
          <Card key={k}>
            <div className="skeleton" style={{ width: '60%', height: 22 }} />
            <div className="skeleton" style={{ width: '40%', height: 14, marginTop: 10 }} />
          </Card>
        ))}
      </Grid>
    );
  }

  return (
    <div data-testid="dashboard">
      <NudgeBanner />

      <Grid preset="stats" style={{ margin: 'var(--sp-5) 0 var(--sp-2)' }}>
        <StatCard
          icon={<Icon name="gauge" size={22} />}
          accent="teal"
          value={r ? `%${r.overall}` : '—'}
          label={r ? `Hazırlık skoru · ${LIGHT_LABEL[r.light]}` : 'Hazırlık skoru'}
          href="/hazirlik-skorum"
        />
        <StatCard
          icon={<Icon name="flame" size={22} />}
          accent="amber"
          value={streak.current}
          label={`Günlük seri (en iyi: ${streak.best})`}
        />
        <StatCard
          icon={<Icon name="clipboard" size={22} />}
          accent="blue"
          value={answered}
          label="Cevaplanan soru"
          href="/ilerleme"
        />
        <StatCard
          icon={<Icon name="trophy" size={22} />}
          accent="green"
          value={`${earned}/8`}
          label={`Başarı rozeti · ${packs} paket`}
          href="/basarilar"
        />
      </Grid>

      <Section
        title="Ders bazlı ustalık"
        icon={<Icon name="layers" size={22} />}
        action={
          <a className="section__link" href="/dersler">
            Tüm dersleri gör ›
          </a>
        }
      >
        <Card>
          <div className="mastery">
            {subjectBars.map((b) => {
              const meta = SUBJECT_META[b.subject];
              return (
                <div key={b.subject} className="mastery-row">
                  <span
                    className="mastery-row__icon"
                    style={
                      { ['--m-accent' as string]: `var(--accent-${meta.accent})` } as CSSProperties
                    }
                    aria-hidden
                  >
                    <Icon name={meta.icon} size={20} />
                  </span>
                  <span className="mastery-row__label">{b.label}</span>
                  <span className="mastery-row__bar">
                    <ProgressBar value={b.pct} label={b.label} />
                  </span>
                  <span className="mastery-row__pct">{b.n ? `%${b.pct}` : '—'}</span>
                  <a className="mastery-row__link" href="/dersler">
                    {b.n ? 'İlerleme var' : 'Başla'} ›
                  </a>
                </div>
              );
            })}
          </div>
        </Card>
      </Section>

      <Section title="Bugün ne yapalım?" icon={<Icon name="target" size={22} />}>
        <Grid preset="cards">
          {!r && (
            <ActionCard
              icon="target"
              iconSrc="/assets/feature-icons/tani.webp"
              accent="teal"
              title="Tanı denemesi"
              desc="Önce seviyeni ölç — hazırlık skorun çıksın."
              cta={{ label: 'Hemen başla', href: '/tani' }}
            />
          )}
          <ActionCard
            icon="brain"
            iconSrc="/assets/feature-icons/beyin.webp"
            accent="amber"
            glow
            title="Akıllı çalışma"
            desc="SRS: yanlışların tam zamanında tekrar sorulur."
            cta={{ label: 'Çalışmaya başla', href: '/calis' }}
          />
          <ActionCard
            icon="timer"
            iconSrc="/assets/feature-icons/kronometre.webp"
            accent="blue"
            title="Deneme sınavı"
            desc="Gerçek format: 50 soru · 45 dakika."
            cta={{ label: 'Deneme çöz', href: '/deneme-sinavi' }}
          />
          <ActionCard
            icon="bot"
            iconSrc="/assets/feature-icons/ai.webp"
            accent="purple"
            title="AI Koç"
            desc="Takıldığın konuyu sor; içerikten kaynaklı yanıt al."
            cta={{ label: "AI Koç'a sor", href: '/ai-koc' }}
          />
        </Grid>
      </Section>
    </div>
  );
}
