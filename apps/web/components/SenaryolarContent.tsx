'use client';

import './senaryolar.css';

/**
 * Senaryolar (Program 2 · Faz 8) — mekân üzerinde karar anları: seç, sonucu gör, öğren.
 * Kart-ızgara hizalaması ref 013. Tüm veri gerçek SCENARIOS'tan; sayı/konu uydurulmaz.
 */
import { useMemo, useState } from 'react';
import { SUBJECT_LABEL, type Subject } from '@ea/content-schema';
import { SCENARIOS } from '@/content/scenarios';
import { lessonBySlug } from '@/content/lessons';
import { ScenarioRunner } from '@/components/scenario/ScenarioRunner';
import { SceneCanvas } from '@/components/scenario/SceneCanvas';
import { PageHeader } from '@/components/ui/layout';
import { Icon, type IconName } from '@/components/ui/icons';

const PAGE_SIZE = 6;

// Üretilmiş kuşbakışı kapaklar (ref 013-A) — id eşleşirse SVG önizleme yerine kullanılır.
const COVER: Record<string, string> = {
  'sagdan-gelen': '/assets/art/intersection-topdown.webp',
  'donel-kavsak': '/assets/art/roundabout-topdown.webp',
};

// Konu (ders subject) → rozet ikonu + vurgu rengi. Yalnız veriden; kategori uydurulmaz.
const SUBJECT_META: Record<Subject, { icon: IconName; color: string }> = {
  trafik: { icon: 'sign', color: 'var(--accent-teal)' },
  ilkyardim: { icon: 'firstaid', color: 'var(--accent-red)' },
  motor: { icon: 'tools', color: 'var(--accent-amber)' },
  adab: { icon: 'shield', color: 'var(--accent-purple)' },
  pratik: { icon: 'road', color: 'var(--accent-blue)' },
};
const DEFAULT_META: { icon: IconName; color: string } = { icon: 'map', color: 'var(--text-2)' };

const norm = (v: string) => v.toLocaleLowerCase('tr');

export function SenaryolarContent() {
  const [active, setActive] = useState<string | null>(null);
  const [konu, setKonu] = useState<'all' | Subject>('all');
  const [sort, setSort] = useState<'default' | 'az' | 'za'>('default');
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);

  // Gerçek senaryo verisi + türetilmiş konu etiketi (SCENARIOS = tek doğru kaynak).
  const items = useMemo(
    () =>
      SCENARIOS.map((s) => {
        const first = s.steps.find((st) => st.id === s.start)!;
        const lesson = s.relatedLessonSlug ? lessonBySlug(s.relatedLessonSlug) : undefined;
        return {
          scenario: s,
          first,
          subject: lesson?.subject,
          subjectLabel: lesson ? SUBJECT_LABEL[lesson.subject] : undefined,
        };
      }),
    []
  );

  // Konu filtresi seçenekleri — yalnız veride bulunan subject'ler.
  const subjectOptions = useMemo(() => {
    const seen = new Map<Subject, string>();
    for (const it of items) if (it.subject) seen.set(it.subject, it.subjectLabel!);
    return [...seen.entries()];
  }, [items]);

  // Özet dağılımı — mock "tamamlanan" yerine GERÇEK konu dağılımı (toplama eşittir).
  const breakdown = useMemo(() => {
    const byKey = new Map<string, { label: string; color: string; n: number }>();
    for (const it of items) {
      if (!it.subject) continue;
      const meta = SUBJECT_META[it.subject];
      const row = byKey.get(it.subject) ?? { label: it.subjectLabel!, color: meta.color, n: 0 };
      row.n += 1;
      byKey.set(it.subject, row);
    }
    const rows = [...byKey.entries()].map(([key, v]) => ({ key, ...v }));
    const categorized = rows.reduce((a, r) => a + r.n, 0);
    const other = items.length - categorized;
    if (other > 0) rows.push({ key: 'diger', label: 'Diğer', color: 'var(--text-3)', n: other });
    return rows;
  }, [items]);

  const filtered = useMemo(() => {
    const t = norm(query.trim());
    let list = items.filter((it) => {
      if (konu !== 'all' && it.subject !== konu) return false;
      if (t && !norm(it.scenario.title).includes(t) && !norm(it.scenario.description).includes(t))
        return false;
      return true;
    });
    if (sort === 'az')
      list = [...list].sort((a, b) => a.scenario.title.localeCompare(b.scenario.title, 'tr'));
    if (sort === 'za')
      list = [...list].sort((a, b) => b.scenario.title.localeCompare(a.scenario.title, 'tr'));
    return list;
  }, [items, konu, sort, query]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const current = Math.min(page, totalPages);
  const paged = filtered.slice((current - 1) * PAGE_SIZE, current * PAGE_SIZE);

  // ScenarioRunner etkileşimi birebir korunur: karttan başlat → aynı runner açılır.
  if (active) {
    return (
      <div className="sc-runner-wrap" data-testid="senaryolar">
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
            Gerçek trafikte karşılaşabileceğin durumları öğren, doğru karar verme becerini geliştir.
            Her senaryo farklı bir trafik durumunu ele alır.
          </>
        }
        actions={
          <div className="sc-summary">
            <div className="sc-summary__lead">
              <span className="sc-summary__badge" aria-hidden>
                <Icon name="gauge" size={24} />
              </span>
              <span>
                <span className="sc-summary__label">Toplam Senaryo</span>
                <strong className="sc-summary__count">{SCENARIOS.length}</strong>
              </span>
            </div>
            {breakdown.length > 0 && (
              <div className="sc-summary__list">
                {breakdown.map((r) => (
                  <span key={r.key} className="sc-summary__row">
                    <span
                      className="sc-summary__dot"
                      style={{ ['--dot' as string]: r.color }}
                      aria-hidden
                    />
                    {r.label}
                    <span className="sc-summary__rowval">{r.n}</span>
                  </span>
                ))}
              </div>
            )}
          </div>
        }
      />

      <div className="sc-filters">
        <label className="sc-field">
          <select
            aria-label="Konuya göre filtrele"
            value={konu}
            onChange={(e) => {
              setKonu(e.target.value as 'all' | Subject);
              setPage(1);
            }}
          >
            <option value="all">Konu: Tümü</option>
            {subjectOptions.map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
          <span className="sc-field__chev" aria-hidden>
            <Icon name="chevron-down" size={16} />
          </span>
        </label>

        <label className="sc-field">
          <select
            aria-label="Sıralama"
            value={sort}
            onChange={(e) => {
              setSort(e.target.value as 'default' | 'az' | 'za');
              setPage(1);
            }}
          >
            <option value="default">Sırala: Varsayılan</option>
            <option value="az">Sırala: A → Z</option>
            <option value="za">Sırala: Z → A</option>
          </select>
          <span className="sc-field__chev" aria-hidden>
            <Icon name="chevron-down" size={16} />
          </span>
        </label>

        <div className="sc-search">
          <span className="sc-search__icon" aria-hidden>
            <Icon name="search" size={17} />
          </span>
          <input
            type="search"
            placeholder="Senaryolarda ara…"
            value={query}
            aria-label="Senaryolarda ara"
            onChange={(e) => {
              setQuery(e.target.value);
              setPage(1);
            }}
          />
        </div>
      </div>

      {paged.length === 0 ? (
        <div className="sc-empty">
          <p style={{ margin: 0 }}>Aramanla eşleşen senaryo bulunamadı.</p>
          <button
            type="button"
            className="sc-empty__btn"
            onClick={() => {
              setKonu('all');
              setSort('default');
              setQuery('');
              setPage(1);
            }}
          >
            Filtreleri temizle
          </button>
        </div>
      ) : (
        <div className="sc-grid">
          {paged.map(({ scenario: s, first, subject, subjectLabel }) => {
            const meta = subject ? SUBJECT_META[subject] : DEFAULT_META;
            return (
              <button
                key={s.id}
                type="button"
                className="sc-card"
                onClick={() => setActive(s.id)}
                data-testid="scenario-card"
              >
                <div className="sc-card__preview">
                  {COVER[s.id] ? (
                    <img src={COVER[s.id]} alt="" className="sc-card__cover" aria-hidden />
                  ) : (
                    <SceneCanvas scene={first.scene} label={s.title} />
                  )}
                  <span
                    className="sc-card__badge"
                    style={{ ['--badge' as string]: meta.color }}
                    aria-hidden
                  >
                    <Icon name={meta.icon} size={18} />
                  </span>
                </div>
                <div className="sc-card__body">
                  <h3 className="sc-card__title">{s.title}</h3>
                  <p className="sc-card__desc">{s.description}</p>
                  {subjectLabel && (
                    <span className="sc-card__chip" style={{ ['--chip' as string]: meta.color }}>
                      <Icon name={meta.icon} size={13} />
                      {subjectLabel}
                    </span>
                  )}
                  <span className="sc-card__start">
                    Senaryoyu başlat
                    <Icon name="chevron-right" size={15} />
                  </span>
                </div>
              </button>
            );
          })}
        </div>
      )}

      {totalPages > 1 && (
        <nav className="sc-pagination" aria-label="Sayfalar">
          <button
            type="button"
            className="sc-page-arrow"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={current === 1}
            aria-label="Önceki sayfa"
          >
            <Icon name="chevron-right" size={16} style={{ transform: 'scaleX(-1)' }} />
          </button>
          {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
            <button
              key={p}
              type="button"
              className={`sc-page${p === current ? ' sc-page--active' : ''}`}
              onClick={() => setPage(p)}
              aria-current={p === current ? 'page' : undefined}
            >
              {p}
            </button>
          ))}
          <button
            type="button"
            className="sc-page-arrow"
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={current === totalPages}
            aria-label="Sonraki sayfa"
          >
            <Icon name="chevron-right" size={16} />
          </button>
        </nav>
      )}
    </div>
  );
}
