'use client';
/**
 * ZoomImage — yakınlaştırılabilir muayene görseli (Program 2 · Faz 2).
 * Tıkla → tam ekran inceleme: tekerlek/butonlarla zoom, sürükleyerek pan, Escape kapatır.
 */
import { useCallback, useEffect, useRef, useState } from 'react';
import Image from 'next/image';
import { visualAssetById } from '@/content/asset-manifest';

export function ZoomImage({ assetId, caption }: { assetId: string; caption?: string }) {
  const asset = visualAssetById(assetId);
  const [open, setOpen] = useState(false);
  const [scale, setScale] = useState(1);
  const [tx, setTx] = useState(0);
  const [ty, setTy] = useState(0);
  const drag = useRef<{ x: number; y: number } | null>(null);

  const reset = useCallback(() => {
    setScale(1);
    setTx(0);
    setTy(0);
  }, []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  if (!asset) return null;

  return (
    <>
      <button
        type="button"
        className="zoomable"
        onClick={() => {
          reset();
          setOpen(true);
        }}
        aria-label={`${asset.title} görselini büyüt ve incele`}
        data-testid="zoom-open"
      >
        <Image
          src={asset.src}
          alt={asset.alt}
          width={asset.width}
          height={asset.height}
          sizes="(max-width: 760px) 100vw, 720px"
          className="zoomable__img"
        />
        <span className="zoomable__hint" aria-hidden>
          🔍 İncele
        </span>
      </button>
      {caption && <p className="muted zoomable__cap">{caption}</p>}

      {open && (
        <div
          className="zoom-overlay"
          role="dialog"
          aria-modal="true"
          aria-label={`${asset.title} — yakınlaştırılmış inceleme`}
          data-testid="zoom-overlay"
          onClick={(e) => e.target === e.currentTarget && setOpen(false)}
        >
          <div
            className="zoom-overlay__stage"
            onWheel={(e) =>
              setScale((s) => Math.min(4, Math.max(1, s - Math.sign(e.deltaY) * 0.3)))
            }
            onPointerDown={(e) => {
              drag.current = { x: e.clientX - tx, y: e.clientY - ty };
              (e.target as HTMLElement).setPointerCapture(e.pointerId);
            }}
            onPointerMove={(e) => {
              if (!drag.current) return;
              setTx(e.clientX - drag.current.x);
              setTy(e.clientY - drag.current.y);
            }}
            onPointerUp={() => (drag.current = null)}
          >
            {/* Tam ekran inceleme: optimize edilmemiş tam çözünürlük kasıtlı (next/image yerine ham img) */}
            <img
              src={asset.src}
              alt={asset.alt}
              className="zoom-overlay__img"
              style={{ transform: `translate(${tx}px, ${ty}px) scale(${scale})` }}
              draggable={false}
            />
          </div>
          <div className="zoom-overlay__bar">
            <button
              type="button"
              className="btn btn--ghost"
              onClick={() => setScale((s) => Math.max(1, s - 0.5))}
              aria-label="Uzaklaştır"
            >
              −
            </button>
            <button
              type="button"
              className="btn btn--ghost"
              onClick={() => setScale((s) => Math.min(4, s + 0.5))}
              aria-label="Yakınlaştır"
            >
              +
            </button>
            <button type="button" className="btn btn--ghost" onClick={reset}>
              Sıfırla
            </button>
            <button
              type="button"
              className="btn"
              onClick={() => setOpen(false)}
              data-testid="zoom-close"
            >
              Kapat ✕
            </button>
          </div>
        </div>
      )}
    </>
  );
}
