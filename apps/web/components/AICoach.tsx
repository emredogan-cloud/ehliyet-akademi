'use client';

/** AI Koç (Faz 22) — grounded mock: yanıtlar yalnız platform içeriğinden türetilir. */
import { useState } from 'react';
import { getAIProvider, type AIMessage } from '@/lib/ai';
import { track } from '@/lib/analytics';

/** Çok hafif markdown: **kalın** + [link](url). Girdi kendi ürettiğimiz metindir. */
function mdLite(s: string): string {
  const esc = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return esc
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\[(.+?)\]\((\/[^)]+)\)/g, '<a href="$2">$1</a>')
    .replace(/\n/g, '<br/>');
}

const SUGGESTIONS = [
  'DUR levhasında ne yapılır?',
  'Hararet ikazı yanarsa ne yapmalıyım?',
  'Kalp masajı dakikada kaç bası?',
  'Rampada geri kaymamak için ne yapılır?',
];

export function AICoach() {
  const [messages, setMessages] = useState<AIMessage[]>([]);
  const [input, setInput] = useState('');
  const [busy, setBusy] = useState(false);

  async function send(text: string) {
    const q = text.trim();
    if (!q || busy) return;
    setMessages((m) => [...m, { role: 'user', text: q }]);
    setInput('');
    setBusy(true);
    const answer = await getAIProvider().ask(q);
    track({
      name: 'ai_question_asked',
      props: { grounded: !answer.includes('eşleşme bulamadım') },
    });
    setMessages((m) => [...m, { role: 'assistant', text: answer }]);
    setBusy(false);
  }

  return (
    <div>
      <div className="explain" role="note" style={{ maxWidth: 720 }}>
        🤖 <strong>Demo mod:</strong> AI Koç yanıtlarını yalnız Ehliyet Akademi içeriğinden (dersler
        + soru bankası) türetir — tahmin/halüsinasyon üretmez.{' '}
        <em>AI hata yapabilir; resmî kural için MEB/MTSK esastır.</em>
      </div>

      <div className="chat" data-testid="chat" aria-live="polite">
        {messages.length === 0 && (
          <div className="card">
            <p className="muted" style={{ marginTop: 0 }}>
              Bir konu sor — örnekler:
            </p>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {SUGGESTIONS.map((s) => (
                <button
                  key={s}
                  className="btn btn--ghost"
                  onClick={() => send(s)}
                  data-testid="suggestion"
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
        )}
        {messages.map((m, k) => (
          <div
            key={k}
            className={`chat__msg chat__msg--${m.role === 'user' ? 'user' : 'ai'}`}
            data-testid={m.role === 'user' ? 'msg-user' : 'msg-ai'}
            dangerouslySetInnerHTML={{ __html: mdLite(m.text) }}
          />
        ))}
        {busy && (
          <div className="chat__msg chat__msg--ai skeleton" style={{ width: 180, height: 40 }} />
        )}
      </div>

      <form
        className="chat__form"
        onSubmit={(e) => {
          e.preventDefault();
          void send(input);
        }}
      >
        <input
          className="chat__input"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Sorunu yaz… (örn. yaya geçidinde öncelik kimde?)"
          aria-label="AI koça soru"
          data-testid="chat-input"
        />
        <button className="btn" disabled={busy || !input.trim()} data-testid="chat-send">
          Sor
        </button>
      </form>
    </div>
  );
}
