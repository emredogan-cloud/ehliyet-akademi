'use client';

/**
 * Senaryolar (Program 2 · Faz 8) — mekân üzerinde karar anları: seç, sonucu gör, öğren.
 */
import { useState } from 'react';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { SCENARIOS } from '@/content/scenarios';
import { lessonBySlug } from '@/content/lessons';
import { ScenarioRunner } from '@/components/scenario/ScenarioRunner';
import { SceneCanvas } from '@/components/scenario/SceneCanvas';
import { PageHeader } from '@/components/ui/layout';
import { Icon } from '@/components/ui/icons';

export default function SenaryolarPage() {
  const [active, setActive] = useState<string | null>(null);

  // Üretilmiş kuşbakışı kapaklar (ref 013-A) — id eşleşirse SVG önizleme yerine kullanılır.
  const COVER: Record<string, string> = {
    'sagdan-gelen': '/assets/art/intersection-topdown.webp',
    'donel-kavsak': '/assets/art/roundabout-topdown.webp',
  };

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
        actions={
          <div
            className="ui-card"
            style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 18px' }}
          >
            <span className="mastery-row__icon" aria-hidden>
              <Icon name="gauge" size={20} />
            </span>
            <span>
              <span style={{ display: 'block', fontSize: 'var(--fs-xs)', color: 'var(--text-3)' }}>
                Toplam Senaryo
              </span>
              <strong style={{ fontSize: 'var(--fs-xl)' }}>{SCENARIOS.length}</strong>
            </span>
          </div>
        }
      />
      <div className="vehicle-grid">
        {SCENARIOS.map((s) => {
          const first = s.steps.find((st) => st.id === s.start)!;
          const lesson = s.relatedLessonSlug ? lessonBySlug(s.relatedLessonSlug) : undefined;
          return (
            <button
              key={s.id}
              type="button"
              className="ui-card ui-card--interactive scenario-card"
              style={{ margin: 0, textAlign: 'left', cursor: 'pointer', fontFamily: 'inherit' }}
              onClick={() => setActive(s.id)}
              data-testid="scenario-card"
            >
              {COVER[s.id] ? (
                <img src={COVER[s.id]} alt="" className="scenario-cover" aria-hidden />
              ) : (
                <SceneCanvas scene={first.scene} label={s.title} />
              )}
              <h3 style={{ margin: '10px 0 4px', fontSize: '1rem' }}>{s.title}</h3>
              <p className="muted" style={{ margin: 0, fontSize: '0.85rem' }}>
                {s.description}
              </p>
              {lesson && (
                <span
                  className="ui-tag ui-tag--accent"
                  style={{ marginTop: 8, ['--tag-accent' as string]: 'var(--primary)' }}
                >
                  {SUBJECT_LABEL[lesson.subject]}
                </span>
              )}
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
