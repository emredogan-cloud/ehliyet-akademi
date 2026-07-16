'use client';
/**
 * AnimPlayer — eğitsel animasyon oynatıcısı (Program 2 · Faz 3 · ADR-012).
 * Oynat/Duraklat (animation-play-state) + Baştan (key remount). Adım metinleri her zaman
 * görünür; prefers-reduced-motion'da animasyon CSS ile kapalı, sahne statik kalır.
 */
import { useState } from 'react';
import { animationById } from '@/content/animations';
import { SCENE_COMPONENTS } from './scenes';

export function AnimPlayer({ animId }: { animId: string }) {
  const meta = animationById(animId);
  const Scene = SCENE_COMPONENTS[animId];
  const [playing, setPlaying] = useState(true);
  const [run, setRun] = useState(0);
  if (!meta || !Scene) return null;

  return (
    <div className="animp" data-testid={`anim-${animId}`}>
      <div className="animp__head">
        <strong>🎬 {meta.title}</strong>
        <div className="animp__controls">
          <button
            type="button"
            className="btn btn--ghost animp__btn"
            onClick={() => setPlaying((p) => !p)}
            aria-pressed={!playing}
            data-testid="anim-toggle"
          >
            {playing ? '⏸ Duraklat' : '▶ Oynat'}
          </button>
          <button
            type="button"
            className="btn btn--ghost animp__btn"
            onClick={() => {
              setRun((r) => r + 1);
              setPlaying(true);
            }}
            data-testid="anim-restart"
          >
            ↺ Baştan
          </button>
        </div>
      </div>
      <div
        key={run}
        className={`animp__stage${playing ? '' : ' animp__stage--paused'}`}
        style={{ ['--anim-dur' as string]: `${meta.duration}s` }}
        data-playing={playing}
      >
        <Scene />
      </div>
      <p className="muted animp__desc">{meta.description}</p>
      <ol className="animp__steps">
        {meta.steps.map((s, i) => (
          <li key={i}>{s}</li>
        ))}
      </ol>
    </div>
  );
}
