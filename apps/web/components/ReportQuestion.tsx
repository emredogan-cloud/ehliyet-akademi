'use client';

import { useState } from 'react';

const KINDS: Array<{ value: string; label: string }> = [
  { value: 'wrong-answer', label: 'Yanlış cevap' },
  { value: 'unclear', label: 'Belirsiz ifade' },
  { value: 'typo', label: 'Yazım hatası' },
  { value: 'suggestion', label: 'Öneri' },
  { value: 'other', label: 'Diğer' },
];

/**
 * QIP Faz 6 · Part 13 — kullanıcı soru bildirimi. Herhangi bir soru görünümüne gömülebilir.
 * Oturum varsa kullanıcı sunucuda iliştirilir; anonim de gönderilebilir.
 */
export function ReportQuestion({ questionId }: { questionId: string }) {
  const [open, setOpen] = useState(false);
  const [kind, setKind] = useState('wrong-answer');
  const [message, setMessage] = useState('');
  const [state, setState] = useState<'idle' | 'sending' | 'done' | 'error'>('idle');

  async function submit() {
    setState('sending');
    try {
      const r = await fetch('/api/qip/report', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ questionId, kind, message }),
      });
      setState(r.ok ? 'done' : 'error');
    } catch {
      setState('error');
    }
  }

  if (state === 'done') {
    return (
      <span className="muted" style={{ fontSize: '0.78rem' }} data-testid="report-thanks">
        ✓ Bildirimin alındı, teşekkürler.
      </span>
    );
  }

  return (
    <span>
      {!open ? (
        <button
          className="ui-btn ui-btn--ghost ui-btn--sm"
          onClick={() => setOpen(true)}
          data-testid="report-open"
          style={{ fontSize: '0.76rem' }}
        >
          ⚠ Bildir
        </button>
      ) : (
        <span style={{ display: 'inline-flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
          <select
            value={kind}
            onChange={(e) => setKind(e.target.value)}
            aria-label="Bildirim türü"
            data-testid="report-kind"
            style={{ fontSize: '0.78rem' }}
          >
            {KINDS.map((k) => (
              <option key={k.value} value={k.value}>
                {k.label}
              </option>
            ))}
          </select>
          <input
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Kısa açıklama (opsiyonel)"
            aria-label="Açıklama"
            data-testid="report-message"
            style={{ fontSize: '0.78rem' }}
          />
          <button
            className="ui-btn ui-btn--primary ui-btn--sm"
            onClick={submit}
            disabled={state === 'sending'}
            data-testid="report-submit"
          >
            Gönder
          </button>
          {state === 'error' && (
            <span className="muted" style={{ color: 'var(--accent-red)', fontSize: '0.76rem' }}>
              Gönderilemedi
            </span>
          )}
        </span>
      )}
    </span>
  );
}
