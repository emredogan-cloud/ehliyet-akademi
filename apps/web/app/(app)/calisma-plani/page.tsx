'use client';

/**
 * Kişisel Çalışma Planı (Sprint 3) — kullanıcının cevap geçmişi + SRS kartlarından üretilen,
 * uyarlanabilir sıralı plan. Grounded: hiçbir öneri platform dışı kaynaktan türetilmez.
 */
import { useEffect, useState } from 'react';
import { SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { statsFromAnswers } from '@ea/srs-engine';
import { loadAnswers, loadCards } from '@/lib/progress';
import { MasteryRadar, type RadarDatum } from '@/components/MasteryRadar';
import {
  buildStudyPlan,
  weakTopics,
  stepKindLabel,
  type StudyPlan,
  type WeakTopic,
} from '@/lib/study';

const KIND_ICON: Record<string, string> = {
  lesson: '📘',
  practice: '✍️',
  review: '🔁',
  exam: '📝',
};

export default function CalismaPlaniPage() {
  const [plan, setPlan] = useState<StudyPlan | null>(null);
  const [weak, setWeak] = useState<WeakTopic[]>([]);
  const [radar, setRadar] = useState<RadarDatum[]>([]);

  useEffect(() => {
    const answers = loadAnswers();
    const cards = loadCards();
    const now = Date.now();
    setPlan(buildStudyPlan(answers, cards, now));
    setWeak(weakTopics(answers, { minAnswered: 2, limit: 6 }));
    const { subjects } = statsFromAnswers(answers);
    const byS = new Map(subjects.map((s) => [s.subject, s.mastery]));
    setRadar(THEORY_SUBJECTS.map((subject) => ({ subject, mastery: byS.get(subject) ?? 0 })));
  }, []);

  return (
    <>
      <h1 style={{ margin: '6px 0 4px' }}>Çalışma Planım</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Cevaplarına ve tekrar kartlarına göre uyarlanan sıralı plan — sen çalıştıkça güncellenir.
      </p>

      {!plan ? (
        <div className="grid" aria-busy="true">
          {[1, 2, 3].map((k) => (
            <div key={k} className="card">
              <div className="skeleton" style={{ width: '60%', height: 20 }} />
              <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 10 }} />
            </div>
          ))}
        </div>
      ) : (
        <div data-testid="study-plan">
          <div className="plan-top">
            <div
              className="card"
              style={{
                background: 'var(--primary-050)',
                borderColor: 'var(--primary-100)',
                margin: 0,
              }}
            >
              <strong>Bugünün odağı</strong>
              <p className="prose" style={{ margin: '8px 0 0' }}>
                {plan.summary}
              </p>
              {plan.dueCount > 0 && (
                <p className="muted" style={{ margin: '8px 0 0' }}>
                  🔁 {plan.dueCount} kartın tekrar zamanı geldi.
                </p>
              )}
            </div>
            <div className="card" style={{ margin: 0 }}>
              <strong style={{ display: 'block', marginBottom: 6 }}>Ders ustalığı</strong>
              <MasteryRadar data={radar} />
            </div>
          </div>

          <h2 className="section-title">Adımlar</h2>
          <ol className="plan-steps" data-testid="plan-steps">
            {plan.steps.map((s, i) => (
              <li key={i} className="plan-step">
                <span className="plan-step__badge" aria-hidden>
                  {KIND_ICON[s.kind]}
                </span>
                <div className="plan-step__body">
                  <div className="plan-step__head">
                    <span className={`pill pill--${s.kind}`}>{stepKindLabel(s.kind)}</span>
                    <strong>{s.title}</strong>
                  </div>
                  <p className="muted" style={{ margin: '4px 0 8px' }}>
                    {s.detail}
                  </p>
                  <a className="btn btn--ghost btn--sm" href={s.href}>
                    Aç →
                  </a>
                </div>
              </li>
            ))}
          </ol>

          {weak.length > 0 && (
            <>
              <h2 className="section-title">En çok gelişime açık konular</h2>
              <div className="grid">
                {weak.map((w) => (
                  <div className="card" key={w.topic}>
                    <span className="badge">{SUBJECT_LABEL[w.subject]}</span>
                    <h3 style={{ margin: '10px 0 6px', textTransform: 'capitalize' }}>{w.topic}</h3>
                    <div className="bar" aria-hidden>
                      <span style={{ width: `${Math.round(w.mastery * 100)}%` }} />
                    </div>
                    <p className="muted" style={{ margin: '6px 0 8px', fontSize: '0.85rem' }}>
                      Ustalık %{Math.round(w.mastery * 100)} · {w.answered} deneme
                    </p>
                    {w.lessonSlug && (
                      <a className="btn btn--ghost btn--sm" href={`/dersler/${w.lessonSlug}`}>
                        {w.lessonTitle} →
                      </a>
                    )}
                  </div>
                ))}
              </div>
            </>
          )}

          <div style={{ marginTop: 22, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <a className="btn" href="/calis">
              Akıllı çalışmaya başla
            </a>
            <a className="btn btn--ghost" href="/ai-koc">
              AI Koç'a sor
            </a>
          </div>
          <p className="muted" style={{ marginTop: 16, fontSize: '0.82rem' }}>
            Bu plan senin çalışma verinden üretilir; resmî kural için MEB/MTSK kaynakları esastır.
          </p>
        </div>
      )}
    </>
  );
}
