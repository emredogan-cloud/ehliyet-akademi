'use client';

/**
 * Trafik İşaretleri Galerisi içeriği (client). Sunucu sarmalayıcı `app/(app)/isaretler/page.tsx`
 * metadata + CollectionJsonLd sağlar. SEO: her kart artık gerçek `<a href>` ile detay sayfasına
 * bağlanır (önceden `window.location.href` idi → tarayıcılar 121 detay sayfasını göremiyordu).
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
import { PageHeader } from '@/components/ui/layout';
import { Chip } from '@/components/ui/primitives';
import { Icon } from '@/components/ui/icons';

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
  const toggle = () => setFlipped((v) => !v);
  return (
    // role=button (div) → içindeki gerçek <a> geçerli HTML olur; aria-pressed + flip korunur.
    <div
      role="button"
      tabIndex={0}
      className={`sign-card ${flipped ? 'sign-card--on' : ''}`}
      onClick={toggle}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          toggle();
        }
      }}
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
          <a
            href={`/isaretler/${sign.id}`}
            className="sign-card__detail"
            style={{
              fontSize: '0.76rem',
              color: 'var(--primary)',
              fontWeight: 700,
              textDecoration: 'none',
            }}
            data-testid="sign-detail-link"
            onClick={(e) => e.stopPropagation()}
          >
            Detay sayfası →
          </a>
        </span>
      </span>
    </div>
  );
}

export function IsaretlerContent() {
  const [q, setQ] = useState('');
  const [cat, setCat] = useState<SignCategory | 'all'>('all');
  const counts = useMemo(() => signsByCategory(), []);
  const list = useMemo(() => filterSigns(q, cat), [q, cat]);

  return (
    <>
      <PageHeader
        title="Trafik İşaretleri"
        emoji="🚸"
        subtitle={`${SIGNS.length} özgün işaret. Karta dokun → anlamını gör. Kategoriye göre süz veya ara.`}
        actions={
          /* Üretilmiş başlık dekoru (ASSET A8) */
          <img
            src="/assets/ui/signs-hero.webp"
            alt=""
            className="page-decor"
            aria-hidden
            loading="lazy"
          />
        }
      />

      <div className="search-box">
        <span className="search-box__icon" aria-hidden>
          <Icon name="search" size={20} />
        </span>
        <input
          className="ui-input search-box__input"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="İşaret ara… (örn. hız, viraj, dur, park)"
          aria-label="İşaret ara"
          data-testid="sign-search"
        />
      </div>

      <div className="chip-row" role="group" aria-label="Kategori">
        {CATS.map((c) => (
          <Chip key={c} active={cat === c} onClick={() => setCat(c)} data-testid={`cat-${c}`}>
            {c === 'all' ? `Tümü (${SIGNS.length})` : `${CATEGORY_LABEL[c]} (${counts[c] ?? 0})`}
          </Chip>
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
