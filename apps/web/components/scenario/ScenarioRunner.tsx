'use client';

/**
 * ScenarioRunner — karar → sonuç → açıklama motoru (Program 2 · Faz 8).
 * Senaryo grafını yürütür, güvenli karar sayısını puanlar; özet ekranıyla biter.
 */
import { useState } from 'react';
import { scenarioById } from '@/content/scenarios';
import { SceneCanvas } from './SceneCanvas';

interface RunState {
  stepId: string;
  picked: number | null;
  safe: number;
  total: number;
  done: boolean;
}

export function ScenarioRunner({ scenarioId, onExit }: { scenarioId: string; onExit: () => void }) {
  const scenario = scenarioById(scenarioId);
  const [st, setSt] = useState<RunState>({
    stepId: scenario?.start ?? '',
    picked: null,
    safe: 0,
    total: 0,
    done: false,
  });
  if (!scenario) return null;
  const step = scenario.steps.find((s) => s.id === st.stepId);
  if (!step) return null;

  const pick = (i: number) => {
    if (st.picked !== null) return;
    const opt = step.options[i]!;
    setSt((p) => ({
      ...p,
      picked: i,
      safe: p.safe + (opt.verdict === 'safe' ? 1 : 0),
      total: p.total + 1,
    }));
  };

  const cont = () => {
    const opt = step.options[st.picked!]!;
    if (opt.next) {
      setSt((p) => ({ ...p, stepId: opt.next!, picked: null }));
    } else {
      setSt((p) => ({ ...p, done: true }));
    }
  };

  if (st.done) {
    const perfect = st.safe === st.total;
    return (
      <div className="card" style={{ textAlign: 'center' }} data-testid="scenario-summary">
        <p style={{ fontSize: '2rem', margin: '6px 0' }}>{perfect ? '🏆' : '📘'}</p>
        <strong>
          {st.safe}/{st.total} güvenli karar
        </strong>
        <p className="muted" style={{ margin: '8px 0 14px' }}>
          {perfect
            ? 'Mükemmel — tüm kararların güvenliydi.'
            : 'Riskli seçimlerin açıklamalarını tekrar gözden geçir.'}
        </p>
        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' }}>
          {scenario.relatedLessonSlug && (
            <a className="btn btn--ghost" href={`/dersler/${scenario.relatedLessonSlug}`}>
              İlgili ders →
            </a>
          )}
          <button type="button" className="btn" onClick={onExit} data-testid="scenario-exit">
            Senaryolara dön
          </button>
        </div>
      </div>
    );
  }

  const opt = st.picked !== null ? step.options[st.picked] : null;

  return (
    <div data-testid="scenario-runner">
      <h2 className="section-title" style={{ marginTop: 0 }}>
        {scenario.title}
      </h2>
      <SceneCanvas scene={step.scene} label={`${scenario.title} — sahne`} />
      <p style={{ fontWeight: 600, margin: '14px 0 10px' }} data-testid="scenario-prompt">
        {step.prompt}
      </p>
      <div style={{ display: 'grid', gap: 8 }}>
        {step.options.map((o, i) => {
          let cls = 'btn btn--ghost';
          if (st.picked !== null) {
            if (o.verdict === 'safe') cls = 'btn';
            else if (i === st.picked) cls = 'btn btn--ghost vq-wrong';
          }
          return (
            <button
              key={i}
              type="button"
              className={cls}
              style={{ justifyContent: 'flex-start', textAlign: 'left' }}
              onClick={() => pick(i)}
              data-testid="scenario-option"
            >
              {o.text}
            </button>
          );
        })}
      </div>
      {opt && (
        <div style={{ marginTop: 12 }} data-testid="scenario-feedback">
          <p style={{ margin: 0, fontWeight: 700 }}>
            {opt.verdict === 'safe' ? '✅ Güvenli karar' : '⚠️ Riskli karar'}
          </p>
          <p className="muted" style={{ margin: '6px 0 0', fontSize: '0.92rem' }}>
            {opt.explain}
          </p>
          <button
            type="button"
            className="btn"
            style={{ marginTop: 12 }}
            onClick={cont}
            data-testid="scenario-continue"
          >
            {opt.next ? 'Devam →' : 'Senaryoyu bitir'}
          </button>
        </div>
      )}
    </div>
  );
}
