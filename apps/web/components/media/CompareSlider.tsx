'use client';
/**
 * CompareSlider — önce/sonra karşılaştırma (Program 2 · Faz 2).
 * Kontrol gerçek <input type="range"> → klavye ve dokunmatikte doğal erişilebilir.
 */
import { useState } from 'react';
import Image from 'next/image';
import { visualAssetById } from '@/content/asset-manifest';
import { compareSceneById } from '@/content/interactive-media';

export function CompareSlider({ sceneId }: { sceneId: string }) {
  const scene = compareSceneById(sceneId);
  const [pos, setPos] = useState(50);
  if (!scene) return null;
  const before = visualAssetById(scene.beforeAsset);
  const after = visualAssetById(scene.afterAsset);
  if (!before || !after) return null;

  return (
    <div className="cmp-slider" data-testid="compare-slider">
      <div className="cmp-slider__stage">
        <Image
          src={after.src}
          alt={after.alt}
          width={after.width}
          height={after.height}
          sizes="(max-width: 760px) 100vw, 720px"
          className="cmp-slider__img"
        />
        <div className="cmp-slider__topwrap" style={{ width: `${pos}%` }} aria-hidden>
          <Image
            src={before.src}
            alt=""
            width={before.width}
            height={before.height}
            sizes="(max-width: 760px) 100vw, 720px"
            className="cmp-slider__img cmp-slider__img--top"
          />
        </div>
        <div className="cmp-slider__divider" style={{ left: `${pos}%` }} aria-hidden />
        <span className="cmp-slider__tag cmp-slider__tag--l" aria-hidden>
          {scene.beforeLabel}
        </span>
        <span className="cmp-slider__tag cmp-slider__tag--r" aria-hidden>
          {scene.afterLabel}
        </span>
      </div>
      <input
        type="range"
        min={0}
        max={100}
        value={pos}
        onChange={(e) => setPos(Number(e.target.value))}
        className="cmp-slider__range"
        aria-label={`${scene.beforeLabel} / ${scene.afterLabel} karşılaştırma kaydırıcısı`}
        data-testid="compare-range"
      />
      <p className="muted cmp-slider__cap">{scene.caption}</p>
    </div>
  );
}
