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
import { QuizLayout, QuizPanel, DonutStat, InfoRow, HintCard } from '@/components/ui/quiz';

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

export function GorselQuizContent() {
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
  const okPct = score.total ? Math.round((score.ok / score.total) * 100) : 0;

  const main = (
    <div data-testid="gorsel-quiz">
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '0 0 14px' }}>
        <button
          type="button"
          className={`ui-chip${mode === 'mixed' ? ' ui-chip--active' : ''}`}
          onClick={() => {
            setMode('mixed');
            next('mixed');
          }}
        >
          Karışık
        </button>
        <button
          type="button"
          className={`ui-chip${mode === 'weak' ? ' ui-chip--active' : ''}`}
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
          style={{ marginLeft: 'auto', fontSize: '0.9rem', alignSelf: 'center' }}
          data-testid="vq-score"
        >
          Skor: {score.ok}/{score.total}
        </span>
      </div>

      <div className="ui-card quiz-card" style={{ textAlign: 'center' }} data-testid="vq-stage">
        <span className="ui-badge">{round.groupLabel}</span>
        <div style={{ display: 'grid', placeItems: 'center', margin: '14px 0' }}>
          {sign ? (
            <SignSvg
              shape={sign.shape}
              glyph={sign.glyph}
              glyphText={sign.glyphText}
              label="Quiz görseli"
              size={170}
            />
          ) : (
            <div style={{ maxWidth: 380, width: '100%' }}>
              <AssetImage assetId={round.assetId ?? round.itemId} caption={false} />
            </div>
          )}
        </div>
        <p style={{ margin: '0 0 14px', fontWeight: 700, fontSize: '1.1rem' }}>{round.prompt}</p>
        <div role="group" aria-label="Seçenekler" style={{ textAlign: 'left' }}>
          {round.options.map((o, i) => {
            let cls = 'opt';
            if (picked !== null) {
              if (i === round.answerIndex) cls += ' correct';
              else if (i === picked) cls += ' wrong';
            }
            return (
              <button
                key={i}
                type="button"
                className={cls}
                data-testid="vq-option"
                onClick={() => answer(i)}
                disabled={picked !== null}
              >
                <span className="opt__key">{String.fromCharCode(65 + i)}</span>
                <span>{o}</span>
              </button>
            );
          })}
        </div>
        {picked !== null && (
          <div style={{ marginTop: 14, textAlign: 'left' }} data-testid="vq-feedback">
            <div className="explain" role="status">
              <strong>
                {picked === round.answerIndex ? 'Doğru! ' : 'Yanlış — zayıflar destene eklendi. '}
              </strong>
              {round.explanation}
            </div>
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

  const aside = (
    <>
      <QuizPanel title="İlerleme" icon="trending">
        <DonutStat
          pct={okPct}
          center={`%${okPct}`}
          sub="Doğru Oranı"
          rows={[
            { color: 'var(--accent-green)', label: 'Doğru', value: score.ok },
            { color: 'var(--accent-red)', label: 'Yanlış', value: score.total - score.ok },
            { color: 'var(--text-3)', label: 'Toplam', value: score.total },
          ]}
        />
      </QuizPanel>
      <QuizPanel title="Konu Bilgisi" icon="layers">
        <InfoRow icon="sign" label="Kategori" value={round.groupLabel} />
        <InfoRow icon="image" label="Havuz" value={`${poolSize} görsel`} />
        <InfoRow icon="flame" label="Zayıflar destesi" value={`${weak.length} görsel`} />
      </QuizPanel>
      <HintCard>
        {picked !== null && sign?.memoryTip
          ? sign.memoryTip
          : 'Görseli dikkatle incele: şekil ve renk, işaretin ailesini (tehlike/yasak/bilgi) ele verir.'}
      </HintCard>
    </>
  );

  return (
    <>
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
      <QuizLayout main={main} aside={aside} />
    </>
  );
}
