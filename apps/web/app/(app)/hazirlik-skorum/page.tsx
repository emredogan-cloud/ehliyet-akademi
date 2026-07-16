'use client';

import { useEffect, useState } from 'react';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { loadReadiness, type StoredReadiness } from '@/lib/storage';
import { PageHeader } from '@/components/ui/layout';

const LIGHT_LABEL: Record<string, string> = {
  yesil: 'Yeşil — hazır',
  sari: 'Sarı — gelişiyor',
  kirmizi: 'Kırmızı — çalışmalı',
};

export default function HazirlikSkorumPage() {
  const [r, setR] = useState<StoredReadiness | null>(null);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    setR(loadReadiness());
    setLoaded(true);
  }, []);

  return (
    <>
      <PageHeader title="Hazırlık Skorum" emoji="🚦" />
      {!loaded ? (
        <p className="muted">Yükleniyor…</p>
      ) : !r ? (
        <div className="card" data-testid="no-readiness">
          <p>Henüz bir hazırlık skorun yok.</p>
          <a className="btn" href="/tani">
            Tanı denemesine başla →
          </a>
        </div>
      ) : (
        <div data-testid="readiness-view">
          <div className="card" style={{ textAlign: 'center' }}>
            <p className="muted">Son hazırlık skorun</p>
            <div className="readiness-score" style={{ color: 'var(--primary)' }}>
              {r.overall}%
            </div>
            <p>
              <span className={`light light--${r.light}`} aria-hidden />{' '}
              <strong>{LIGHT_LABEL[r.light]}</strong> · Tahmini geçme olasılığı:{' '}
              {Math.round(r.predictedPassProbability * 100)}%
            </p>
            <p className="muted">
              {r.correct}/{r.answered} doğru · {new Date(r.at).toLocaleString('tr-TR')}
            </p>
          </div>

          <h2 className="section-title">Ders bazlı durum</h2>
          <div className="grid">
            {r.perSubject.map((s) => (
              <div className="card" key={s.subject}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span className={`light light--${s.light}`} aria-hidden />
                  <strong>{SUBJECT_LABEL[s.subject]}</strong>
                </div>
                <p className="muted" style={{ margin: '6px 0 0' }}>
                  Ustalık: {Math.round(s.mastery * 100)}%
                </p>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 20, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            <a className="btn" href="/tani">
              Yeniden ölç
            </a>
            <a className="btn btn--ghost" href="/dersler">
              Derslere çalış
            </a>
          </div>
        </div>
      )}
    </>
  );
}
