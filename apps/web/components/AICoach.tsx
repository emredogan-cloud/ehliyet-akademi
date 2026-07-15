'use client';

/**
 * AI Koç (Faz 22 · Sprint 3) — grounded ÖĞRENME ASİSTANI.
 * İki yetenek: (1) içerik Q&A (yalnız dersler + soru bankasından); (2) kişisel rehberlik
 * (çalışma planı, zayıf konular, kişisel tekrar) — kullanıcının KENDİ verisinden türetilir.
 * Tahmin/halüsinasyon yoktur.
 */
import { useEffect, useState } from 'react';
import { getAIProvider, type AIMessage } from '@/lib/ai';
import { track } from '@/lib/analytics';
import { loadAnswers, loadCards } from '@/lib/progress';
import {
  buildStudyPlan,
  formatStudyPlan,
  weakTopics,
  formatWeakTopics,
  personalizedReview,
  examReadinessAnalysis,
  formatReadinessAnalysis,
} from '@/lib/study';

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

type Action = 'plan' | 'weak' | 'review' | 'readiness';
const ACTIONS: Array<{ id: Action; label: string }> = [
  { id: 'plan', label: '📋 Ne çalışmalıyım?' },
  { id: 'weak', label: '🎯 Zayıf konularım' },
  { id: 'review', label: '🔁 Kişisel tekrar hazırla' },
  { id: 'readiness', label: '📊 Sınav hazırlığım nasıl?' },
];

export function AICoach() {
  const [messages, setMessages] = useState<AIMessage[]>([]);
  const [input, setInput] = useState('');
  const [busy, setBusy] = useState(false);

  // Ders sayfasından gelen ?soru= derin bağlantısını giriş kutusuna doldur (SSR-güvenli).
  useEffect(() => {
    const soru = new URLSearchParams(window.location.search).get('soru');
    if (soru) setInput(soru);
  }, []);

  function push(role: AIMessage['role'], text: string) {
    setMessages((m) => [...m, { role, text }]);
  }

  async function send(text: string) {
    const q = text.trim();
    if (!q || busy) return;
    push('user', q);
    setInput('');
    setBusy(true);
    let answer = '';
    let grounded = true;
    try {
      // Sunucu grounded AI (model soyutlaması + halüsinasyon kapısı + fallback).
      const res = await fetch('/api/ai/ask', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ question: q }),
      });
      if (!res.ok) throw new Error('http');
      const d = (await res.json()) as { answer: string; grounded: boolean };
      answer = d.answer;
      grounded = d.grounded;
    } catch {
      // Çevrimdışı/sunucu hatası → yerel grounded mock (asla kırılmaz).
      answer = await getAIProvider().ask(q);
      grounded = !answer.includes('eşleşme bulamadım');
    }
    track({ name: 'ai_question_asked', props: { grounded } });
    push('assistant', answer);
    setBusy(false);
  }

  /** Kişisel rehberlik: kullanıcının kendi verisinden grounded mesaj üretir. */
  function coach(action: Action) {
    if (busy) return;
    const answers = loadAnswers();
    const cards = loadCards();
    const now = Date.now();
    let userLabel = '';
    let reply = '';
    if (action === 'plan') {
      userLabel = 'Bugün ne çalışmalıyım?';
      reply = formatStudyPlan(buildStudyPlan(answers, cards, now));
    } else if (action === 'weak') {
      userLabel = 'Zayıf konularım neler?';
      reply = formatWeakTopics(weakTopics(answers, { minAnswered: 2, limit: 6 }));
    } else if (action === 'readiness') {
      userLabel = 'Sınav hazırlığım nasıl?';
      reply = formatReadinessAnalysis(examReadinessAnalysis(answers));
    } else {
      userLabel = 'Bana kişisel bir tekrar seti hazırla.';
      const ids = personalizedReview(answers, cards, now, 10);
      reply =
        ids.length > 0
          ? `Sana özel **${ids.length} soruluk** tekrar seti hazır: vadesi gelen kartların ve en zayıf konuların önceliklendirildi.\n\n[Kişisel tekrarı başlat](/calis?mod=tekrar)\n\n_Set, cevap geçmişin ve SRS kartlarından üretildi._`
          : 'Tekrar seti için yeterli veri yok. Önce birkaç alıştırma çöz; sonra vadesi gelen kartlarını ve zayıf konularını önceliklendirerek sana özel set hazırlarım.';
    }
    track({ name: 'ai_question_asked', props: { grounded: true, action } });
    push('user', userLabel);
    push('assistant', reply);
  }

  return (
    <div>
      <div className="explain" role="note" style={{ maxWidth: 720 }}>
        🤖 <strong>Öğrenme asistanı:</strong> yanıtlar yalnız Ehliyet Akademi içeriğinden (dersler +
        soru bankası) ve <strong>senin çalışma verinden</strong> türetilir — tahmin/halüsinasyon
        üretmez. <em>AI hata yapabilir; resmî kural için MEB/MTSK esastır.</em>
      </div>

      <div
        className="coach-actions"
        style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '12px 0' }}
      >
        {ACTIONS.map((a) => (
          <button
            key={a.id}
            className="btn btn--ghost"
            onClick={() => coach(a.id)}
            disabled={busy}
            data-testid={`coach-action-${a.id}`}
          >
            {a.label}
          </button>
        ))}
      </div>

      <div className="chat" data-testid="chat" aria-live="polite">
        {messages.length === 0 && (
          <div className="card">
            <p className="muted" style={{ marginTop: 0 }}>
              Bir konu sor — ya da yukarıdan kişisel rehberlik iste. Örnek sorular:
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
