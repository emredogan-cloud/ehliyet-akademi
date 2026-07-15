'use client';

/**
 * Trafik İşaretleri Galerisi (Program 1 · Görsel Dönüşüm) — özgün SVG işaret sistemi.
 * Kategori filtresi + arama + flip-kart öğrenme modu (ön: görsel, arka: anlam).
 */
import { useMemo, useState } from 'react';
import {
  SIGNS,
  filterSigns,
  CATEGORY_LABEL,
  signsByCategory,
  type SignCategory,
  type TrafficSign,
} from '@/content/signs';
import { TrafficSign as SignSvg } from '@/components/signs/TrafficSign';
import { EmptyState } from '@/components/ui/EmptyState';

const CATS: Array<SignCategory | 'all'> = [
  'all',
  'tehlike',
  'yasak',
  'mecburiyet',
  'oncelik',
  'bilgi',
  'park',
  'otoyol',
  'gecici',
];

function SignFlipCard({ sign }: { sign: TrafficSign }) {
  const [flipped, setFlipped] = useState(false);
  return (
    <button
      type="button"
      className={`sign-card ${flipped ? 'sign-card--on' : ''}`}
      onClick={() => setFlipped((v) => !v)}
      aria-pressed={flipped}
      data-testid="sign-card"
    >
      <span className="sign-card__inner">
        <span className="sign-card__face sign-card__front">
          <SignSvg
            shape={sign.shape}
            glyph={sign.glyph}
            glyphText={sign.glyphText}
            label={sign.name}
            size={92}
          />
          <span className="sign-card__name">{sign.name}</span>
          <span className={`imp imp--${sign.examImportance.replace(/\s+/g, '-')}`}>
            {sign.examImportance === 'çok yüksek'
              ? '★★★'
              : sign.examImportance === 'yüksek'
                ? '★★'
                : '★'}
          </span>
        </span>
        <span className="sign-card__face sign-card__back">
          <strong style={{ fontSize: '0.9rem' }}>{sign.name}</strong>
          <span style={{ fontSize: '0.82rem' }}>{sign.meaning}</span>
          <span style={{ fontSize: '0.76rem', color: 'var(--text-3)' }}>💡 {sign.memoryTip}</span>
          {sign.relatedLessonSlug && (
            <span
              style={{ fontSize: '0.76rem', color: 'var(--primary)' }}
              onClick={(e) => {
                e.stopPropagation();
                window.location.href = `/dersler/${sign.relatedLessonSlug}`;
              }}
            >
              İlgili ders →
            </span>
          )}
        </span>
      </span>
    </button>
  );
}

export default function IsaretlerPage() {
  const [q, setQ] = useState('');
  const [cat, setCat] = useState<SignCategory | 'all'>('all');
  const counts = useMemo(() => signsByCategory(), []);
  const list = useMemo(() => filterSigns(q, cat), [q, cat]);

  return (
    <>
      <h1 style={{ margin: '6px 0 4px' }}>Trafik İşaretleri</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        {SIGNS.length} özgün işaret. Karta dokun → anlamını gör. Kategoriye göre süz veya ara.
      </p>

      <div className="toolbar" style={{ marginTop: 12 }}>
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="İşaret ara… (örn. hız, viraj, dur, park)"
          aria-label="İşaret ara"
          data-testid="sign-search"
          style={{ minWidth: 240, flex: 1 }}
        />
      </div>

      <div className="chip-row" role="tablist" aria-label="Kategori">
        {CATS.map((c) => (
          <button
            key={c}
            className={`chip ${cat === c ? 'chip--on' : ''}`}
            onClick={() => setCat(c)}
            data-testid={`cat-${c}`}
            role="tab"
            aria-selected={cat === c}
          >
            {c === 'all' ? `Tümü (${SIGNS.length})` : `${CATEGORY_LABEL[c]} (${counts[c] ?? 0})`}
          </button>
        ))}
      </div>

      {list.length === 0 ? (
        <EmptyState
          testId="signs-empty"
          icon="🔎"
          title={`"${q}" için işaret bulunamadı`}
          hint="Farklı bir kelimeyle ara ya da bir kategori seç. Örneğin: hız, viraj, dur, park."
        />
      ) : (
        <div className="sign-grid" data-testid="signs-gallery">
          {list.map((s) => (
            <SignFlipCard key={s.id} sign={s} />
          ))}
        </div>
      )}
    </>
  );
}
