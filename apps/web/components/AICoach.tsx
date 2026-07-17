'use client';

/**
 * AI Koç (Faz 22 · Sprint 3) — grounded ÖĞRENME ASİSTANI.
 * İki yetenek: (1) içerik Q&A (yalnız dersler + soru bankasından); (2) kişisel rehberlik
 * (çalışma planı, zayıf konular, kişisel tekrar) — kullanıcının KENDİ verisinden türetilir.
 * Tahmin/halüsinasyon yoktur.
 */
import { useEffect, useState } from 'react';
import { getAIProvider, type AIMessage } from '@/lib/ai';
import { matchVisuals, type VisualMatches } from '@/lib/visual-match';
import { TrafficSign as SignSvg } from '@/components/signs/TrafficSign';
import { AssetImage } from '@/components/ui/AssetImage';
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
  type WeakTopic,
  type StudyStep,
} from '@/lib/study';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { Icon } from '@/components/ui/icons';
import { QuizLayout, QuizPanel, DonutStat } from '@/components/ui/quiz';

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

type CoachMessage = AIMessage & { visuals?: VisualMatches };

export function AICoach() {
  const [messages, setMessages] = useState<CoachMessage[]>([]);
  const [input, setInput] = useState('');
  const [busy, setBusy] = useState(false);
  // Ray verileri (salt görüntü — kullanıcının kendi geçmişinden).
  const [rail, setRail] = useState<{
    answered: number;
    correct: number;
    weak: WeakTopic[];
    steps: StudyStep[];
  }>({ answered: 0, correct: 0, weak: [], steps: [] });

  // Ders sayfasından gelen ?soru= derin bağlantısını giriş kutusuna doldur (SSR-güvenli).
  useEffect(() => {
    const soru = new URLSearchParams(window.location.search).get('soru');
    if (soru) setInput(soru);
    const answers = loadAnswers();
    setRail({
      answered: answers.length,
      correct: answers.filter((a) => a.correct).length,
      weak: weakTopics(answers, { minAnswered: 2, limit: 4 }),
      steps: buildStudyPlan(answers, loadCards(), Date.now()).steps.slice(0, 4),
    });
  }, []);

  function push(role: AIMessage['role'], text: string, visuals?: VisualMatches) {
    setMessages((m) => [...m, { role, text, visuals }]);
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
    // Faz 5: yanıta grounded görsel kart iliştir (yalnız kendi kataloglarımızdan).
    const visuals = grounded ? matchVisuals(`${q} ${answer}`) : undefined;
    push('assistant', answer, visuals);
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

  const main = (
    <div>
      <div className="ui-card ui-card--accent hero-banner coach-hero" role="note">
        <span className="coach-hero__bot" aria-hidden>
          🤖
        </span>
        <div className="hero-banner__body">
          <div className="hero-banner__title">Merhaba! 👋</div>
          <div className="hero-banner__text">
            Ehliyet Akademi içerikleriyle güçlendirilmiş AI koçun burada. Dersler, soru bankası ve
            senin çalışma verinden yararlanarak sana özel, güvenilir ve güncel cevaplar veririm —
            tahmin/halüsinasyon üretmem.{' '}
            <em>AI hata yapabilir; resmî kural için MEB/MTSK esastır.</em>
          </div>
          <span className="ui-tag ui-tag--accent coach-hero__src">
            <Icon name="shield" size={14} /> Kaynağım: Ehliyet Akademi (MEB uyumlu içerikler)
          </span>
        </div>
      </div>

      <div
        className="coach-actions"
        style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '14px 0' }}
      >
        {ACTIONS.map((a) => (
          <button
            key={a.id}
            className="ui-chip"
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
          <div className="ui-card quiz-card">
            <p style={{ marginTop: 0, fontWeight: 700 }}>Örnek sorulara göz at 👇</p>
            <div className="coach-samples">
              {SUGGESTIONS.map((s) => (
                <button
                  key={s}
                  className="coach-sample"
                  onClick={() => send(s)}
                  data-testid="suggestion"
                >
                  <span className="coach-sample__ic" aria-hidden>
                    <Icon name="target" size={16} />
                  </span>
                  {s}
                </button>
              ))}
            </div>
            <p className="muted" style={{ margin: '12px 0 0', fontSize: 'var(--fs-xs)' }}>
              ✨ Bunlar sadece örnek. İstediğin her şeyi sorabilirsin!
            </p>
          </div>
        )}
        {messages.map((m, k) => (
          <div key={k}>
            <div
              className={`chat__msg chat__msg--${m.role === 'user' ? 'user' : 'ai'}`}
              data-testid={m.role === 'user' ? 'msg-user' : 'msg-ai'}
              dangerouslySetInnerHTML={{ __html: mdLite(m.text) }}
            />
            {m.visuals && (m.visuals.signs.length > 0 || m.visuals.parts.length > 0) && (
              <div className="chat__visuals" data-testid="ai-visuals">
                {m.visuals.signs.map((sg) => (
                  <a key={sg.id} className="chat__visual" href="/isaretler" title={sg.meaning}>
                    <SignSvg
                      shape={sg.shape}
                      glyph={sg.glyph}
                      glyphText={sg.glyphText}
                      label={sg.name}
                      size={56}
                    />
                    <span>{sg.name}</span>
                  </a>
                ))}
                {m.visuals.parts.map((pt) => (
                  <a key={pt.id} className="chat__visual" href="/arac" title={pt.desc}>
                    {pt.photo && (
                      <span className="chat__visual-photo">
                        <AssetImage assetId={pt.photo} caption={false} />
                      </span>
                    )}
                    <span>{pt.name}</span>
                  </a>
                ))}
              </div>
            )}
          </div>
        ))}
        {busy && (
          <div className="chat__msg chat__msg--ai skeleton" style={{ width: 180, height: 40 }} />
        )}
      </div>

      <form
        className="chat__form coach-form"
        onSubmit={(e) => {
          e.preventDefault();
          void send(input);
        }}
      >
        <input
          className="ui-input"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Sorunu yaz… (örn. yaya geçidinde öncelik kimde?)"
          aria-label="AI koça soru"
          data-testid="chat-input"
        />
        <button
          className="ui-btn ui-btn--primary ui-btn--md"
          disabled={busy || !input.trim()}
          data-testid="chat-send"
        >
          <Icon name="login" size={16} /> Sor
        </button>
      </form>
      <p className="muted coach-lock">
        <Icon name="lock" size={13} /> Yanıtlar, yalnızca Ehliyet Akademi içeriklerine dayanır ve
        tahmin/halüsinasyon üretmez.
      </p>
    </div>
  );

  const okPct = rail.answered ? Math.round((rail.correct / rail.answered) * 100) : 0;
  const aside = (
    <>
      <QuizPanel title="Bugünkü Genel Özetin" icon="trending">
        <DonutStat
          pct={okPct}
          center={`%${okPct}`}
          sub="Doğru Oranı"
          rows={[
            { color: 'var(--accent-green)', label: 'Doğru', value: rail.correct },
            { color: 'var(--accent-red)', label: 'Yanlış', value: rail.answered - rail.correct },
            { color: 'var(--text-3)', label: 'Çözülen soru', value: rail.answered },
          ]}
        />
      </QuizPanel>
      <QuizPanel
        title="Zayıf Konuların"
        icon="target"
        action={
          <a className="section__link" href="/calisma-plani">
            Detaylara git →
          </a>
        }
      >
        {rail.weak.length === 0 ? (
          <p className="muted" style={{ margin: 0, fontSize: 'var(--fs-sm)' }}>
            Henüz yeterli veri yok — birkaç alıştırma çöz, zayıf konuların burada görünsün.
          </p>
        ) : (
          <div style={{ display: 'grid', gap: 10 }}>
            {rail.weak.map((w) => {
              const pct = Math.round(w.mastery * 100);
              const color =
                pct < 50
                  ? 'var(--accent-red)'
                  : pct < 70
                    ? 'var(--accent-amber)'
                    : 'var(--accent-green)';
              return (
                <div key={w.topic}>
                  <div className="exam-bar-row">
                    <span>
                      {SUBJECT_LABEL[w.subject]} · {w.topic}
                    </span>
                    <span className="muted">%{pct}</span>
                  </div>
                  <div className="ui-progress">
                    <span
                      className="ui-progress__fill"
                      style={{ width: `${pct}%`, background: color }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </QuizPanel>
      <QuizPanel title="Önerilen Çalışma Planı" icon="calendar">
        {rail.steps.length === 0 ? (
          <p className="muted" style={{ margin: 0, fontSize: 'var(--fs-sm)' }}>
            Plan için önce biraz veri gerekiyor — tanı denemesiyle başla.
          </p>
        ) : (
          <ul className="exam-tips">
            {rail.steps.map((s) => (
              <li key={s.title}>
                <span className="exam-tips__check" aria-hidden>
                  <Icon name="check-circle" size={15} />
                </span>
                <a href={s.href}>{s.title}</a>
              </li>
            ))}
          </ul>
        )}
        <a
          className="ui-btn ui-btn--primary ui-btn--sm ui-btn--full"
          href="/calisma-plani"
          style={{ marginTop: 12 }}
        >
          Planı gör +
        </a>
      </QuizPanel>
    </>
  );

  return <QuizLayout main={main} aside={aside} />;
}
