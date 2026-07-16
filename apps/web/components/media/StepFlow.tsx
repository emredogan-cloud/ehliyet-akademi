'use client';
/**
 * StepFlow — fotoğraflı adım adım akış (Program 2 · Faz 2).
 * Sürüş öncesi kontrol gibi sıralı prosedürleri görselle öğretir; klavye erişilebilir.
 */
import { useState } from 'react';
import Image from 'next/image';
import { visualAssetById } from '@/content/asset-manifest';
import { stepFlowById } from '@/content/interactive-media';

export function StepFlow({ sceneId }: { sceneId: string }) {
  const flow = stepFlowById(sceneId);
  const [i, setI] = useState(0);
  if (!flow || flow.steps.length === 0) return null;
  const step = flow.steps[i];
  if (!step) return null;
  const asset = visualAssetById(step.asset);

  return (
    <div className="stepflow" data-testid="stepflow" aria-label={flow.title}>
      <div className="stepflow__head">
        <strong>{flow.title}</strong>
        <span className="muted" data-testid="stepflow-progress">
          {i + 1} / {flow.steps.length}
        </span>
      </div>
      {asset && (
        <div className="stepflow__stage">
          <Image
            src={asset.src}
            alt={asset.alt}
            width={asset.width}
            height={asset.height}
            sizes="(max-width: 760px) 100vw, 720px"
            className="stepflow__img"
          />
        </div>
      )}
      <div className="stepflow__body">
        <strong data-testid="stepflow-title">{step.title}</strong>
        <p className="muted" style={{ margin: '4px 0 0' }}>
          {step.text}
        </p>
      </div>
      <div className="stepflow__nav">
        <button
          type="button"
          className="btn btn--ghost"
          onClick={() => setI(Math.max(0, i - 1))}
          disabled={i === 0}
        >
          ← Önceki
        </button>
        <div className="stepflow__dots" aria-hidden>
          {flow.steps.map((_, k) => (
            <button
              key={k}
              type="button"
              className={`stepflow__dot${k === i ? ' stepflow__dot--on' : ''}`}
              onClick={() => setI(k)}
              tabIndex={-1}
            />
          ))}
        </div>
        <button
          type="button"
          className="btn"
          onClick={() => setI(Math.min(flow.steps.length - 1, i + 1))}
          disabled={i === flow.steps.length - 1}
          data-testid="stepflow-next"
        >
          Sonraki →
        </button>
      </div>
    </div>
  );
}
