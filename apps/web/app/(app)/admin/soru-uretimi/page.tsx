'use client';

import { useState } from 'react';
import { PageHeader } from '@/components/ui/layout';

interface GenItem {
  id: string;
  stem: string;
  options: string[];
  answerIndex: number;
  explanation: string;
  image: string | null;
  review: string;
  ok: boolean;
  issues: string[];
  score: number;
}

export default function AdminGeneratePage() {
  const [items, setItems] = useState<GenItem[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState('');
  const [aiOn, setAiOn] = useState<boolean | null>(null);

  async function generateVisual() {
    setLoading(true);
    setErr('');
    try {
      const r = await fetch('/api/admin/qip/generate', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ mode: 'visual', limit: 12 }),
      });
      if (!r.ok) throw new Error(String(r.status));
      const d = (await r.json()) as { generated: GenItem[]; aiConfigured: boolean };
      setItems(d.generated);
      setAiOn(d.aiConfigured);
    } catch {
      setErr('Üretim başarısız (admin/editör gerekli).');
    } finally {
      setLoading(false);
    }
  }

  const passed = items?.filter((i) => i.ok).length ?? 0;

  return (
    <div>
      <PageHeader
        title="Soru Üretimi"
        emoji="✨"
        subtitle="Görsel işaret soruları (deterministik) ve AI kavram varyantları — hepsi taslak, AI İnceleyici kapısından geçer. Otomatik yayımlanmaz."
      />

      <div className="card">
        <p className="muted" style={{ marginTop: 0, fontSize: '0.9rem' }}>
          Görsel sorular, doğrulanmış trafik işareti kataloğundan üretilir ve otomatik olarak AI
          İnceleyici’den (dilbilgisi, tek doğru cevap, yineleme, alan) geçirilir. AI kavram varyant
          üretimi için sunucuda <code>ANTHROPIC_API_KEY</code> gerekir.
        </p>
        <button
          className="ui-btn ui-btn--primary ui-btn--sm"
          onClick={generateVisual}
          disabled={loading}
          data-testid="gen-visual"
        >
          {loading ? 'Üretiliyor…' : 'Görsel soru üret (12)'}
        </button>
        {aiOn !== null && (
          <span className="muted" style={{ marginLeft: 12, fontSize: '0.82rem' }}>
            AI varyant üretimi: {aiOn ? 'etkin' : 'devre dışı (anahtar yok)'}
          </span>
        )}
      </div>

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {items && (
        <div data-testid="gen-results">
          <p className="muted" style={{ fontSize: '0.85rem' }}>
            {items.length} soru üretildi · {passed} tanesi incelemeden geçti
          </p>
          <div style={{ display: 'grid', gap: 10 }}>
            {items.map((it) => (
              <div
                key={it.id}
                className="card"
                style={{
                  margin: 0,
                  borderLeft: `4px solid ${it.ok ? 'var(--accent-green)' : 'var(--accent-red)'}`,
                }}
                data-testid="gen-item"
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span
                    className="badge"
                    style={{ color: it.ok ? 'var(--accent-green)' : 'var(--accent-red)' }}
                  >
                    {it.ok ? '✓ geçti' : '✕ elendi'}
                  </span>
                  <strong style={{ flex: 1 }}>{it.stem}</strong>
                  {it.image && (
                    <span className="muted" style={{ fontSize: '0.78rem' }}>
                      🖼 {it.image}
                    </span>
                  )}
                  <span className="muted" style={{ fontSize: '0.78rem' }}>
                    skor {it.score}
                  </span>
                </div>
                <ol style={{ margin: '8px 0 0 20px', fontSize: '0.86rem' }}>
                  {it.options.map((o, i) => (
                    <li key={i} style={{ fontWeight: i === it.answerIndex ? 700 : 400 }}>
                      {o} {i === it.answerIndex ? '✓' : ''}
                    </li>
                  ))}
                </ol>
                {it.issues.length > 0 && (
                  <p
                    className="muted"
                    style={{ margin: '6px 0 0', fontSize: '0.8rem', color: 'var(--accent-red)' }}
                  >
                    {it.issues.join(' · ')}
                  </p>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
