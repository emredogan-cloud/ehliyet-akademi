'use client';

/** Panel (dashboard) — kabuğun ana ekranı: hazırlık, seri, ders ilerlemesi, hızlı aksiyonlar. */
import { useEffect, useState } from 'react';
import { SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { statsFromAnswers } from '@ea/srs-engine';
import { loadAnswers, loadStreak } from '@/lib/progress';
import { loadReadiness, type StoredReadiness } from '@/lib/storage';
import { loadEntitlements } from '@/lib/payments';
import { computeAchievements, earnedCount } from '@/lib/achievements';
import { NudgeBanner } from '@/components/NudgeBanner';

const LIGHT_LABEL: Record<string, string> = {
  yesil: 'Hazır',
  sari: 'Gelişiyor',
  kirmizi: 'Çalışmalı',
};

export function Dashboard() {
  const [ready, setReady] = useState(false);
  const [r, setR] = useState<StoredReadiness | null>(null);
  const [streak, setStreak] = useState({ current: 0, best: 0 });
  const [subjectBars, setSubjectBars] = useState<Array<{ label: string; pct: number; n: number }>>(
    []
  );
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
      <div className="grid" aria-busy="true" aria-label="Yükleniyor">
        {[1, 2, 3, 4].map((k) => (
          <div key={k} className="card">
            <div className="skeleton" style={{ width: '60%', height: 22 }} />
            <div className="skeleton" style={{ width: '40%', height: 14, marginTop: 10 }} />
          </div>
        ))}
      </div>
    );
  }

  return (
    <div data-testid="dashboard">
      <NudgeBanner />
      <div
        className="grid"
        style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))' }}
      >
        <div className="stat-tile">
          <div className="stat-tile__num">{r ? `${r.overall}%` : '—'}</div>
          <div className="stat-tile__cap">
            Hazırlık skoru{' '}
            {r && (
              <>
                · <span className={`light light--${r.light}`} aria-hidden /> {LIGHT_LABEL[r.light]}
              </>
            )}
          </div>
        </div>
        <div className="stat-tile">
          <div className="stat-tile__num">🔥 {streak.current}</div>
          <div className="stat-tile__cap">Günlük seri (en iyi: {streak.best})</div>
        </div>
        <div className="stat-tile">
          <div className="stat-tile__num">{answered}</div>
          <div className="stat-tile__cap">Cevaplanan soru</div>
        </div>
        <div className="stat-tile">
          <div className="stat-tile__num">🏆 {earned}/8</div>
          <div className="stat-tile__cap">Başarı rozeti · {packs} paket</div>
        </div>
      </div>

      <h2 className="section-title">Ders bazlı ustalık</h2>
      <div className="card" style={{ display: 'grid', gap: 14 }}>
        {subjectBars.map((b) => (
          <div key={b.label}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                fontSize: '0.9rem',
                marginBottom: 4,
              }}
            >
              <span>{b.label}</span>
              <span className="muted">{b.n ? `${b.pct}% · ${b.n} soru` : 'henüz veri yok'}</span>
            </div>
            <div
              className="bar"
              role="progressbar"
              aria-valuenow={b.pct}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label={b.label}
            >
              <span style={{ width: `${b.pct}%` }} />
            </div>
          </div>
        ))}
      </div>

      <h2 className="section-title">Bugün ne yapalım?</h2>
      <div className="grid">
        {!r && (
          <a className="card card--link" href="/tani" data-testid="cta-tani">
            <h3>🎯 Tanı denemesi</h3>
            <p className="muted">Önce seviyeni ölç — hazırlık skorun çıksın.</p>
          </a>
        )}
        <a className="card card--link" href="/calis">
          <h3>🧠 Akıllı çalışma</h3>
          <p className="muted">SRS: yanlışların tam zamanında tekrar sorulur.</p>
        </a>
        <a className="card card--link" href="/deneme-sinavi">
          <h3>⏱️ Deneme sınavı</h3>
          <p className="muted">Gerçek format: 50 soru · 45 dakika.</p>
        </a>
        <a className="card card--link" href="/ai-koc">
          <h3>🤖 AI Koç</h3>
          <p className="muted">Takıldığın konuyu sor; içerikten kaynaklı yanıt al.</p>
        </a>
      </div>
    </div>
  );
}
