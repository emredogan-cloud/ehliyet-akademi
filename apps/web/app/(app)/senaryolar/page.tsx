'use client';

/**
 * Senaryolar (Program 2 · Faz 8) — mekân üzerinde karar anları: seç, sonucu gör, öğren.
 */
import { useState } from 'react';
import { SCENARIOS } from '@/content/scenarios';
import { ScenarioRunner } from '@/components/scenario/ScenarioRunner';
import { SceneCanvas } from '@/components/scenario/SceneCanvas';
import { PageHeader } from '@/components/ui/layout';

export default function SenaryolarPage() {
  const [active, setActive] = useState<string | null>(null);

  if (active) {
    return (
      <div style={{ maxWidth: 680, margin: '0 auto' }} data-testid="senaryolar">
        <ScenarioRunner scenarioId={active} onExit={() => setActive(null)} />
      </div>
    );
  }

  return (
    <div data-testid="senaryolar">
      <PageHeader
        title="Sürüş Senaryoları"
        emoji="🗺️"
        subtitle={
          <>
            {SCENARIOS.length} kuş-bakışı karar senaryosu: sahneyi gör, kararını ver, sonucun
            nedenini öğren. Yanlış karar ceza değil — açıklaması en değerli kısımdır.
          </>
        }
      />
      <div className="vehicle-grid">
        {SCENARIOS.map((s) => {
          const first = s.steps.find((st) => st.id === s.start)!;
          return (
            <button
              key={s.id}
              type="button"
              className="card scenario-card"
              style={{ margin: 0, textAlign: 'left', cursor: 'pointer' }}
              onClick={() => setActive(s.id)}
              data-testid="scenario-card"
            >
              <SceneCanvas scene={first.scene} label={s.title} />
              <h3 style={{ margin: '10px 0 4px', fontSize: '1rem' }}>{s.title}</h3>
              <p className="muted" style={{ margin: 0, fontSize: '0.85rem' }}>
                {s.description}
              </p>
              <span
                style={{
                  color: 'var(--primary)',
                  fontSize: '0.85rem',
                  fontWeight: 700,
                  display: 'inline-block',
                  marginTop: 8,
                }}
              >
                Senaryoyu başlat →
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
