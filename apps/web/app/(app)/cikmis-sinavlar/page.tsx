'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface Session {
  id: string;
  label: string;
  monthLabel: string;
}
interface YearGroup {
  year: number;
  sessions: Session[];
}

export default function CikmisSinavlarPage() {
  const [years, setYears] = useState<YearGroup[] | null>(null);
  const [label, setLabel] = useState('');
  const [err, setErr] = useState('');

  useEffect(() => {
    void fetch('/api/qip/historical')
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { years: YearGroup[]; label: string }) => {
        setYears(d.years);
        setLabel(d.label);
      })
      .catch(() => setErr('Sınav arşivi yüklenemedi.'));
  }, []);

  return (
    <div>
      <PageHeader
        title="Çıkmış Sınav Formatları"
        emoji="📚"
        subtitle="Gerçek e-Sınav oturum tarihlerine göre düzenlenmiş, MEB formatında hazırlanmış ÖZGÜN deneme sınavları. Resmî sınav kâğıdı değildir."
      />

      <div className="explain" role="note" data-testid="historical-disclaimer">
        Buradaki sınavlar{' '}
        <strong>{label || 'MEB formatında hazırlanmış özgün deneme sınavı'}</strong>
        dır; gerçek çıkmış soruların kopyası <strong>değildir</strong>. Her sınav, o oturumun
        tarihine göre bankamızın özgün sorularından dengeli biçimde üretilir.
      </div>

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {!years ? (
        <div className="card" aria-busy="true">
          <div className="skeleton" style={{ height: 40 }} />
        </div>
      ) : (
        <div data-testid="historical-years">
          {years.map((y) => (
            <div key={y.year} style={{ marginTop: 18 }} data-testid={`historical-year-${y.year}`}>
              <h2 className="section-title">{y.year}</h2>
              <div
                style={{
                  display: 'grid',
                  gap: 10,
                  gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
                }}
              >
                {y.sessions.map((s) => (
                  <a
                    key={s.id}
                    href={`/cikmis-sinavlar/${s.id}`}
                    className="card"
                    style={{ margin: 0, textDecoration: 'none' }}
                    data-testid={`historical-session-${s.id}`}
                  >
                    <strong>{s.label}</strong>
                    <div className="muted" style={{ fontSize: '0.8rem', marginTop: 4 }}>
                      {s.monthLabel} · 50 soru · özgün deneme
                    </div>
                  </a>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
