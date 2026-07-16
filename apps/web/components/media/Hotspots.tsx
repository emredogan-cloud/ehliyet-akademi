'use client';
/**
 * Hotspots — foto üzerinde keşfet-öğren noktaları (Program 2 · Faz 2).
 * Erişilebilir: her nokta gerçek buton (Tab ile gezilir, Enter/Space açar, Escape kapatır).
 */
import { useState } from 'react';
import Image from 'next/image';
import { visualAssetById } from '@/content/asset-manifest';
import { hotspotSceneById } from '@/content/interactive-media';

export function Hotspots({ sceneId }: { sceneId: string }) {
  const scene = hotspotSceneById(sceneId);
  const [open, setOpen] = useState<number | null>(null);
  if (!scene) return null;
  const asset = visualAssetById(scene.asset);
  if (!asset) return null;
  const active = open !== null ? scene.spots[open] : undefined;

  return (
    <div
      className="hotspots"
      data-testid="hotspots"
      onKeyDown={(e) => e.key === 'Escape' && setOpen(null)}
    >
      <p className="muted hotspots__intro">🔍 {scene.intro}</p>
      <div className="hotspots__stage">
        <Image
          src={asset.src}
          alt={asset.alt}
          width={asset.width}
          height={asset.height}
          sizes="(max-width: 760px) 100vw, 720px"
          className="hotspots__img"
        />
        {scene.spots.map((s, i) => (
          <button
            key={i}
            type="button"
            className={`hotspots__dot${open === i ? ' hotspots__dot--on' : ''}`}
            style={{ left: `${s.x}%`, top: `${s.y}%` }}
            aria-expanded={open === i}
            aria-label={s.title}
            data-testid={`hotspot-${i}`}
            onClick={() => setOpen(open === i ? null : i)}
          >
            <span aria-hidden>{open === i ? '×' : '+'}</span>
          </button>
        ))}
        {active && (
          <div
            className="hotspots__pop"
            role="status"
            data-testid="hotspot-pop"
            style={{
              left: `${Math.min(72, Math.max(4, active.x - 12))}%`,
              top: `${Math.min(70, active.y + 6)}%`,
            }}
          >
            <strong>{active.title}</strong>
            <p>{active.text}</p>
          </div>
        )}
      </div>
    </div>
  );
}
