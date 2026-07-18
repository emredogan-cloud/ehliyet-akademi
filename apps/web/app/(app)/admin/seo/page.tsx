'use client';

import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface Check {
  id: string;
  label: string;
  status: 'ok' | 'warn' | 'fail';
  detail: string;
  count?: number;
  sample?: string[];
}
interface Audit {
  score: number;
  totals: Record<string, number>;
  checks: Check[];
}

const STATUS_META: Record<Check['status'], { icon: string; color: string; label: string }> = {
  ok: { icon: '✓', color: 'var(--accent-green)', label: 'Geçti' },
  warn: { icon: '!', color: 'var(--accent-amber)', label: 'Uyarı' },
  fail: { icon: '✕', color: 'var(--accent-red)', label: 'Sorun' },
};

const TOTAL_LABEL: Record<string, string> = {
  indexableUrls: 'İndekslenebilir URL',
  staticRoutes: 'Statik rota',
  signPages: 'İşaret sayfası',
  vehiclePages: 'Araç sayfası',
  lessonPages: 'Ders sayfası',
  sitemapUrls: 'Sitemap URL',
  schemaTypes: 'Schema türü',
  images: 'Görsel (manifest)',
};

export default function AdminSeoPage() {
  const [audit, setAudit] = useState<Audit | null>(null);
  const [err, setErr] = useState('');
  const [keyLoc, setKeyLoc] = useState('');
  const [pinging, setPinging] = useState(false);
  const [pingMsg, setPingMsg] = useState('');

  useEffect(() => {
    void fetch('/api/admin/seo', { credentials: 'same-origin' })
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: { audit: Audit; indexNow: { keyLocation: string } }) => {
        setAudit(d.audit);
        setKeyLoc(d.indexNow.keyLocation);
      })
      .catch(() => setErr('SEO denetimi yüklenemedi (admin/editor gerekli).'));
  }, []);

  async function pingIndexNow() {
    setPinging(true);
    setPingMsg('');
    try {
      const r = await fetch('/api/admin/seo', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({}),
      });
      const d = (await r.json()) as { submitted?: number; ok?: boolean; status?: number };
      setPingMsg(
        d.ok
          ? `${d.submitted} URL IndexNow'a gönderildi (HTTP ${d.status}).`
          : `Gönderim başarısız (HTTP ${d.status ?? 0}). Üretim ortamında ve doğrulanmış anahtarla çalışır.`
      );
    } catch {
      setPingMsg('Gönderim sırasında ağ hatası.');
    } finally {
      setPinging(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="SEO Panosu"
        emoji="🔍"
        subtitle="Canlı teknik SEO denetimi: metadata, kanonik, yapısal veri, görsel ve sitemap sağlığı."
      />

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {!audit ? (
        <div className="card" aria-busy="true">
          <div className="skeleton" style={{ height: 40 }} />
        </div>
      ) : (
        <>
          <div
            className="card"
            style={{ display: 'flex', alignItems: 'center', gap: 20, flexWrap: 'wrap' }}
          >
            <div style={{ textAlign: 'center' }}>
              <div
                style={{
                  fontSize: '2.6rem',
                  fontWeight: 800,
                  color:
                    audit.score >= 90
                      ? 'var(--accent-green)'
                      : audit.score >= 70
                        ? 'var(--accent-amber)'
                        : 'var(--accent-red)',
                }}
              >
                {audit.score}
              </div>
              <div className="muted" style={{ fontSize: '0.8rem' }}>
                SEO Skoru
              </div>
            </div>
            <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap', flex: 1 }}>
              {Object.entries(audit.totals).map(([k, v]) => (
                <div key={k}>
                  <div style={{ fontSize: '1.3rem', fontWeight: 700 }}>{v}</div>
                  <div className="muted" style={{ fontSize: '0.76rem' }}>
                    {TOTAL_LABEL[k] ?? k}
                  </div>
                </div>
              ))}
            </div>
          </div>

          <h2 className="section-title" style={{ marginTop: 22 }}>
            Denetim kontrolleri
          </h2>
          <div style={{ display: 'grid', gap: 10 }}>
            {audit.checks.map((c) => {
              const m = STATUS_META[c.status];
              return (
                <div
                  key={c.id}
                  className="card"
                  style={{ margin: 0, borderLeft: `4px solid ${m.color}` }}
                  data-testid={`seo-check-${c.id}`}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span
                      aria-hidden
                      style={{
                        color: m.color,
                        fontWeight: 800,
                        fontSize: '1.05rem',
                        minWidth: 18,
                      }}
                    >
                      {m.icon}
                    </span>
                    <strong style={{ flex: 1 }}>{c.label}</strong>
                    <span className="badge" style={{ color: m.color }}>
                      {m.label}
                    </span>
                  </div>
                  <p className="muted" style={{ margin: '6px 0 0 28px', fontSize: '0.88rem' }}>
                    {c.detail}
                  </p>
                  {c.sample && c.sample.length > 0 && (
                    <p
                      className="muted"
                      style={{ margin: '4px 0 0 28px', fontSize: '0.8rem', opacity: 0.8 }}
                    >
                      Örnek: {c.sample.join(', ')}
                    </p>
                  )}
                </div>
              );
            })}
          </div>

          <h2 className="section-title" style={{ marginTop: 22 }}>
            IndexNow
          </h2>
          <div className="card">
            <p className="muted" style={{ marginTop: 0, fontSize: '0.88rem' }}>
              Anahtar dosyası:{' '}
              <a href={keyLoc} target="_blank" rel="noopener noreferrer">
                {keyLoc}
              </a>
            </p>
            <button
              className="ui-btn ui-btn--primary ui-btn--sm"
              onClick={pingIndexNow}
              disabled={pinging}
              data-testid="indexnow-ping"
            >
              {pinging ? 'Gönderiliyor…' : 'Çekirdek URL’leri IndexNow’a gönder'}
            </button>
            {pingMsg && (
              <p
                className="muted"
                role="status"
                style={{ margin: '10px 0 0', fontSize: '0.85rem' }}
              >
                {pingMsg}
              </p>
            )}
          </div>
        </>
      )}
    </div>
  );
}
