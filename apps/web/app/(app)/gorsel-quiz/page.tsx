'use client';

/**
 * Görsel Quiz (Program 2 · Faz 5) — "Bu işaret/bileşen nedir?"
 * Havuz: özgün SVG işaretler + premium bileşen fotoğrafları. Yanlışlar yerel "zayıflar"
 * destesine düşer; zayıf tekrar modunda iki kez doğru bilinene dek tekrar sorulur.
 */
import { useEffect, useMemo, useState } from 'react';
import { TrafficSign as SignSvg } from '@/components/signs/TrafficSign';
import { AssetImage } from '@/components/ui/AssetImage';
import { signById } from '@/content/signs';
import { buildRound, quizPool, type VisualQuizRound } from '@/lib/visual-quiz';
import { PageHeader } from '@/components/ui/layout';

const KEY = 'ea:visualQuiz:v1';

interface WeakItem {
  kind: 'sign' | 'part';
  id: string;
  /** Üst üste doğru sayısı — 2 olunca desteden çıkar. */
  streak: number;
}

function loadWeak(): WeakItem[] {
  if (typeof localStorage === 'undefined') return [];
  try {
    return JSON.parse(localStorage.getItem(KEY) ?? '[]') as WeakItem[];
  } catch {
    return [];
  }
}
function saveWeak(items: WeakItem[]) {
  localStorage.setItem(KEY, JSON.stringify(items));
}

export default function GorselQuizPage() {
  const [mode, setMode] = useState<'mixed' | 'weak'>('mixed');
  const [round, setRound] = useState<VisualQuizRound | null>(null);
  const [picked, setPicked] = useState<number | null>(null);
  const [score, setScore] = useState({ ok: 0, total: 0 });
  const [weak, setWeak] = useState<WeakItem[]>([]);
  const poolSize = useMemo(() => quizPool().length, []);

  useEffect(() => {
    setWeak(loadWeak());
    setRound(buildRound());
  }, []);

  function next(m = mode) {
    setPicked(null);
    if (m === 'weak') {
      const w = loadWeak();
      setWeak(w);
      if (w.length === 0) {
        setMode('mixed');
        setRound(buildRound());
        return;
      }
      const item = w[Math.floor(Math.random() * w.length)]!;
      setRound(buildRound(Math.random, { kind: item.kind, id: item.id }));
    } else {
      setRound(buildRound());
    }
  }

  function answer(i: number) {
    if (!round || picked !== null) return;
    setPicked(i);
    const correct = i === round.answerIndex;
    setScore((s) => ({ ok: s.ok + (correct ? 1 : 0), total: s.total + 1 }));
    const itemKey = { kind: round.kind, id: round.itemId };
    const w = loadWeak();
    const idx = w.findIndex((x) => x.kind === itemKey.kind && x.id === itemKey.id);
    if (!correct) {
      if (idx === -1) w.push({ ...itemKey, streak: 0 });
      else w[idx]!.streak = 0;
    } else if (idx !== -1) {
      w[idx]!.streak += 1;
      if (w[idx]!.streak >= 2) w.splice(idx, 1);
    }
    saveWeak(w);
    setWeak(w);
  }

  if (!round) return null;
  const sign = round.kind === 'sign' ? signById(round.itemId) : undefined;

  return (
    <div data-testid="gorsel-quiz" style={{ maxWidth: 640, margin: '0 auto' }}>
      <PageHeader
        title="Görsel Quiz"
        emoji="📸"
        subtitle={
          <>
            {poolSize} görselden rastgele: işareti/bileşeni gör, adını bil. Yanlışların "zayıflar"
            destene düşer; iki kez doğru bilince çıkar.
          </>
        }
      />

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '12px 0' }}>
        <button
          type="button"
          className={`chip${mode === 'mixed' ? ' chip--on' : ''}`}
          onClick={() => {
            setMode('mixed');
            next('mixed');
          }}
        >
          Karışık
        </button>
        <button
          type="button"
          className={`chip${mode === 'weak' ? ' chip--on' : ''}`}
          data-testid="vq-mode-weak"
          disabled={weak.length === 0}
          onClick={() => {
            setMode('weak');
            next('weak');
          }}
        >
          🔁 Zayıfları tekrar ({weak.length})
        </button>
        <span
          className="muted"
          style={{ marginLeft: 'auto', fontSize: '0.9rem' }}
          data-testid="vq-score"
        >
          Skor: {score.ok}/{score.total}
        </span>
      </div>

      <div className="card" style={{ textAlign: 'center' }} data-testid="vq-stage">
        <span className="badge">{round.groupLabel}</span>
        <div style={{ display: 'grid', placeItems: 'center', margin: '14px 0' }}>
          {sign ? (
            <SignSvg
              shape={sign.shape}
              glyph={sign.glyph}
              glyphText={sign.glyphText}
              label="Quiz görseli"
              size={150}
            />
          ) : (
            <div style={{ maxWidth: 380, width: '100%' }}>
              <AssetImage assetId={round.assetId ?? round.itemId} caption={false} />
            </div>
          )}
        </div>
        <p style={{ margin: '0 0 12px', fontWeight: 600 }}>{round.prompt}</p>
        <div style={{ display: 'grid', gap: 8 }}>
          {round.options.map((o, i) => {
            let cls = 'btn btn--ghost';
            if (picked !== null) {
              if (i === round.answerIndex) cls = 'btn';
              else if (i === picked) cls = 'btn btn--ghost vq-wrong';
            }
            return (
              <button
                key={i}
                type="button"
                className={cls}
                data-testid="vq-option"
                onClick={() => answer(i)}
                style={{ justifyContent: 'flex-start' }}
              >
                {o}
              </button>
            );
          })}
        </div>
        {picked !== null && (
          <div style={{ marginTop: 14 }} data-testid="vq-feedback">
            <p style={{ margin: 0, fontWeight: 700 }}>
              {picked === round.answerIndex ? '✅ Doğru!' : '❌ Yanlış — zayıflar destene eklendi.'}
            </p>
            <p className="muted" style={{ margin: '6px 0 0', fontSize: '0.9rem' }}>
              {round.explanation}
            </p>
            <button
              type="button"
              className="btn"
              style={{ marginTop: 12 }}
              data-testid="vq-next"
              onClick={() => next()}
            >
              Sonraki →
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
