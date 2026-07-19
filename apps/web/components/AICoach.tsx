'use client';

/**
 * AI Koç (Faz 22 · Sprint 3) — grounded ÖĞRENME ASİSTANI.
 * İki yetenek: (1) içerik Q&A (yalnız dersler + soru bankasından); (2) kişisel rehberlik
 * (çalışma planı, zayıf konular, kişisel tekrar) — kullanıcının KENDİ verisinden türetilir.
 * Tahmin/halüsinasyon yoktur.
 */
import { useEffect, useRef, useState } from 'react';
import type { AIMessage } from '@/lib/ai';
import { matchVisuals, type VisualMatches } from '@/lib/visual-match';
import { TrafficSign as SignSvg } from '@/components/signs/TrafficSign';
import { AssetImage } from '@/components/ui/AssetImage';
import { track } from '@/lib/analytics';
import { loadAnswers, loadCards } from '@/lib/progress';
import {
  loadEntitlements,
  canAskFreeAI,
  consumeFreeAI,
  remainingFreeAI,
  FREE_AI_DAILY,
} from '@/lib/payments';
import { hasCapability } from '@/lib/products';
// lib/study soru bankasını (1534) çeker → tembel import ile ilk yükten çıkarılır (LCP perf).
import type { WeakTopic, StudyStep } from '@/lib/study';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { Icon } from '@/components/ui/icons';
import { QuizLayout, QuizPanel, DonutStat } from '@/components/ui/quiz';

/**
 * Çok hafif markdown: **kalın**, [link](/url), # başlık, - madde, --- ayraç.
 * Girdi kendi ürettiğimiz/model yanıtı metindir; önce HTML kaçışı yapılır.
 * (Gerçek model (Anthropic) yanıtları başlık/madde kullanır — LCP genişletmesi.)
 */
function mdLite(s: string): string {
  const esc = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const lines = esc.split('\n').map((line) => {
    const t = line.trim();
    if (/^-{3,}$/.test(t)) return '<span class="chat__hr"></span>';
    const h = t.match(/^#{1,4}\s+(.*)$/);
    if (h) return `<strong class="chat__h">${h[1]}</strong>`;
    const li = t.match(/^[-*]\s+(.*)$/);
    if (li) return `<span class="chat__li">• ${li[1]}</span>`;
    const num = t.match(/^(\d+)[.)]\s+(.*)$/);
    if (num) return `<span class="chat__li">${num[1]}. ${num[2]}</span>`;
    return line;
  });
  return (
    lines
      .join('\n')
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      // _italik_ (ör. yasal uyarı satırı) — alt çizgi içermeyen kısa aralık; kelime içi bozmaz.
      .replace(/_([^_\n]+)_/g, '<em>$1</em>')
      // GÜVENLİK (L2): href yalnız güvenli URL karakterleri — tırnak/boşluk yok → attribute injection önlenir.
      .replace(/\[(.+?)\]\((\/[^)"'\s]+)\)/g, '<a href="$2">$1</a>')
      .replace(/\n/g, '<br/>')
  );
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

type CoachMessage = AIMessage & { visuals?: VisualMatches; at?: number };

/** localStorage sohbet kalıcılığı: son CHAT_CAP mesaj saklanır (reload/gezinme dayanıklı). */
const CHAT_KEY = 'ea:chat:v1';
const CHAT_CAP = 40;

/** Ücretsiz hak dolduğunda gösterilen premium yönlendirmesi (send + regenerate paylaşır). */
const UPSELL = `Bugünkü ücretsiz AI Koç hakkını kullandın (günde ${FREE_AI_DAILY} soru). **Sınırsız AI Koç** ve tüm premium içerik için:\n\n[Komple B paketine göz at →](/fiyatlandirma)\n\n_Yarın ücretsiz hakkın yenilenir._`;

/** Mesaj zaman damgasını HH:MM olarak biçimler (tr-TR). */
function fmtTime(at?: number): string {
  if (!at) return '';
  try {
    return new Date(at).toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
  } catch {
    return '';
  }
}

/* Küçük satır-ikonları (Icon setinde karşılığı yok → self-contained inline SVG). */
const IconCopy = (
  <svg
    className="chat-act__ic"
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden
  >
    <rect x="9" y="9" width="11" height="11" rx="2" />
    <path d="M5 15V5a2 2 0 0 1 2-2h8" />
  </svg>
);
const IconRegen = (
  <svg
    className="chat-act__ic"
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden
  >
    <path d="M21 12a9 9 0 1 1-2.64-6.36" />
    <path d="M21 3v6h-6" />
  </svg>
);
const IconTrash = (
  <svg
    className="chat-act__ic"
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden
  >
    <path d="M3 6h18" />
    <path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
    <path d="M6 6v14a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V6" />
  </svg>
);

export function AICoach() {
  const [messages, setMessages] = useState<CoachMessage[]>([]);
  const [input, setInput] = useState('');
  const [busy, setBusy] = useState(false);
  // Ücretsiz AI hakkı göstergesi (premium ise null → sınırsız).
  const [aiLeft, setAiLeft] = useState<number | null>(null);
  // Kopyalandı geri bildirimi için son kopyalanan mesajın indeksi.
  const [copiedIdx, setCopiedIdx] = useState<number | null>(null);

  // Otomatik kaydırma: sohbet sonundaki çapa + kullanıcı en altta mı (yoksa yukarı kaydırıyor mu).
  const endRef = useRef<HTMLDivElement | null>(null);
  const stickRef = useRef(true);
  // İlk persist çalıştırmasını atla (restore'un yazdığını ezmesin).
  const persistRef = useRef(false);

  // Ders sayfasından gelen ?soru= derin bağlantısını giriş kutusuna doldur (SSR-güvenli).
  // Ayrıca localStorage'daki sohbeti geri yükle (reload/gezinme sonrası devam).
  // (Ray verileri ayrı <CoachRail/> bileşenindedir — tembel bank yüklemesi giriş kutusunu
  //  yeniden render edip sıfırlamasın diye ayrıştırıldı; LCP kararlılık düzeltmesi.)
  useEffect(() => {
    const soru = new URLSearchParams(window.location.search).get('soru');
    if (soru) setInput(soru);
    const premium = hasCapability(loadEntitlements(), 'ai-sinirsiz');
    setAiLeft(premium ? null : remainingFreeAI());
    try {
      const raw = localStorage.getItem(CHAT_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as CoachMessage[];
        if (Array.isArray(parsed) && parsed.length > 0) setMessages(parsed.slice(-CHAT_CAP));
      }
    } catch {
      /* bozuk/erişilemez depolama → boş başla */
    }
  }, []);

  // Sohbeti localStorage'a yaz (son CHAT_CAP mesaj). İlk çalıştırma atlanır → restore ezilmez.
  useEffect(() => {
    if (!persistRef.current) {
      persistRef.current = true;
      return;
    }
    try {
      localStorage.setItem(CHAT_KEY, JSON.stringify(messages.slice(-CHAT_CAP)));
    } catch {
      /* kota/erişim hatası sessiz geçilir */
    }
  }, [messages]);

  // Kullanıcı en altta mı? IntersectionObserver çapayı izler → kaydırma kabıyla uyumlu (window ya da div).
  useEffect(() => {
    const el = endRef.current;
    if (!el || typeof IntersectionObserver === 'undefined') return;
    const io = new IntersectionObserver(
      (entries) => {
        stickRef.current = entries[0]?.isIntersecting ?? true;
      },
      { rootMargin: '0px 0px 120px 0px' }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  // Yeni mesaj/typing geldiğinde en alta yumuşak kaydır — ama kullanıcı yukarıdaysa zorlama.
  // Boş sohbette (ilk yük) kaydırma yok → sayfa aşağı çekilmez.
  useEffect(() => {
    if (messages.length === 0 && !busy) return;
    if (!stickRef.current) return;
    endRef.current?.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }, [messages, busy]);

  function push(role: AIMessage['role'], text: string, visuals?: VisualMatches) {
    setMessages((m) => [...m, { role, text, visuals, at: Date.now() }]);
  }

  async function copyMsg(text: string, idx: number) {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedIdx(idx);
      setTimeout(() => setCopiedIdx((c) => (c === idx ? null : c)), 1600);
    } catch {
      /* pano izni yok → sessiz geç */
    }
  }

  function clearChat() {
    setMessages([]);
    setCopiedIdx(null);
    try {
      localStorage.removeItem(CHAT_KEY);
    } catch {
      /* yoksay */
    }
  }

  /** Ortak AI cevap yolu: sunucu grounded AI → hata olursa yerel grounded mock; asistan mesajı iter. */
  async function runAI(q: string) {
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
      // Soru bankası (1534 soru) yalnız bu fallback anında tembel yüklenir — ilk yük hafif kalır (LCP perf).
      const { getAIProvider } = await import('@/lib/ai');
      answer = await getAIProvider().ask(q);
      grounded = !answer.includes('eşleşme bulamadım');
    }
    track({ name: 'ai_question_asked', props: { grounded } });
    // Faz 5: yanıta grounded görsel kart iliştir (yalnız kendi kataloglarımızdan).
    const visuals = grounded ? matchVisuals(`${q} ${answer}`) : undefined;
    push('assistant', answer, visuals);
  }

  async function send(text: string) {
    const q = text.trim();
    if (!q || busy) return;
    // PREMIUM STRATEJİSİ (P10): ücretsiz kademe günde FREE_AI_DAILY soru; premium sınırsız.
    const premium = hasCapability(loadEntitlements(), 'ai-sinirsiz');
    if (!premium && !canAskFreeAI()) {
      push('user', q);
      setInput('');
      push('assistant', UPSELL);
      return;
    }
    push('user', q);
    setInput('');
    setBusy(true);
    if (!premium) consumeFreeAI();
    setAiLeft(remainingFreeAI());
    await runAI(q);
    setBusy(false);
  }

  /** Son asistan yanıtını, önceki kullanıcı sorusunu aynı yol üzerinden yeniden çalıştırarak tazeler. */
  async function regenerate() {
    if (busy) return;
    // Son kullanıcı sorusu (son asistan mesajından önceki).
    let q: string | null = null;
    for (let i = messages.length - 1; i >= 0; i--) {
      const msg = messages[i];
      if (msg && msg.role === 'user') {
        q = msg.text;
        break;
      }
    }
    if (!q) return;
    // Kota mantığı korunur: yeniden oluşturma da bir ücretsiz hak tüketir.
    const premium = hasCapability(loadEntitlements(), 'ai-sinirsiz');
    if (!premium && !canAskFreeAI()) {
      push('assistant', UPSELL);
      return;
    }
    // Eski son asistan yanıtını kaldır (yeni yanıt yerine geçer — kullanıcı mesajı çoğaltılmaz).
    setMessages((m) => (m[m.length - 1]?.role === 'assistant' ? m.slice(0, -1) : m));
    setBusy(true);
    if (!premium) consumeFreeAI();
    setAiLeft(remainingFreeAI());
    await runAI(q);
    setBusy(false);
  }

  /** Kişisel rehberlik: kullanıcının kendi verisinden grounded mesaj üretir (bank tembel yüklenir). */
  async function coach(action: Action) {
    if (busy) return;
    const answers = loadAnswers();
    const cards = loadCards();
    const now = Date.now();
    const study = await import('@/lib/study');
    let userLabel = '';
    let reply = '';
    if (action === 'plan') {
      userLabel = 'Bugün ne çalışmalıyım?';
      reply = study.formatStudyPlan(study.buildStudyPlan(answers, cards, now));
    } else if (action === 'weak') {
      userLabel = 'Zayıf konularım neler?';
      reply = study.formatWeakTopics(study.weakTopics(answers, { minAnswered: 2, limit: 6 }));
    } else if (action === 'readiness') {
      userLabel = 'Sınav hazırlığım nasıl?';
      reply = study.formatReadinessAnalysis(study.examReadinessAnalysis(answers));
    } else {
      userLabel = 'Bana kişisel bir tekrar seti hazırla.';
      const ids = study.personalizedReview(answers, cards, now, 10);
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
          {/* Üretilmiş maskot (ASSET A4 / 020-A) */}
          <img src="/assets/art/robot-wave.webp" alt="" className="coach-hero__img" />
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

      {messages.length > 0 && (
        <div className="chat-toolbar">
          <button
            type="button"
            className="chat-clear"
            onClick={clearChat}
            disabled={busy}
            data-testid="chat-clear"
          >
            {IconTrash} Sohbeti temizle
          </button>
        </div>
      )}

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
        {messages.map((m, k) => {
          const isUser = m.role === 'user';
          const isLastAssistant = !isUser && k === messages.length - 1;
          return (
            <div key={k} className={`chat-row chat-row--${isUser ? 'user' : 'ai'}`}>
              <div
                className={`chat__msg chat__msg--${isUser ? 'user' : 'ai'}`}
                data-testid={isUser ? 'msg-user' : 'msg-ai'}
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
              <div className="chat-meta">
                {!isUser && (
                  <button
                    type="button"
                    className="chat-act"
                    onClick={() => void copyMsg(m.text, k)}
                    aria-label="Mesajı kopyala"
                  >
                    {IconCopy}
                    {copiedIdx === k ? 'Kopyalandı' : 'Kopyala'}
                  </button>
                )}
                {isLastAssistant && (
                  <button
                    type="button"
                    className="chat-act"
                    onClick={() => void regenerate()}
                    disabled={busy}
                    aria-label="Yanıtı yeniden oluştur"
                  >
                    {IconRegen}
                    Yeniden oluştur
                  </button>
                )}
                {m.at ? (
                  <time className="chat-time" dateTime={new Date(m.at).toISOString()}>
                    {fmtTime(m.at)}
                  </time>
                ) : null}
              </div>
            </div>
          );
        })}
        {busy && (
          <div className="chat-row chat-row--ai">
            <div
              className="chat__msg chat__msg--ai chat-typing"
              role="status"
              aria-label="AI koç yazıyor"
            >
              <span className="chat-typing__dot" />
              <span className="chat-typing__dot" />
              <span className="chat-typing__dot" />
            </div>
          </div>
        )}
        <div ref={endRef} className="chat-end" aria-hidden />
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
      <p className="muted coach-lock" style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        <span>
          <Icon name="lock" size={13} /> Yanıtlar, yalnızca Ehliyet Akademi içeriklerine dayanır ve
          tahmin/halüsinasyon üretmez.
        </span>
        {aiLeft !== null && (
          <span data-testid="ai-quota" style={{ marginLeft: 'auto', fontWeight: 600 }}>
            {aiLeft > 0 ? (
              <>
                Bugün {aiLeft}/{FREE_AI_DAILY} ücretsiz soru ·{' '}
                <a href="/fiyatlandirma">sınırsız için premium</a>
              </>
            ) : (
              <a href="/fiyatlandirma">Ücretsiz hakkın doldu — sınırsız AI için premium →</a>
            )}
          </span>
        )}
      </p>
    </div>
  );

  return <QuizLayout main={main} aside={<CoachRail />} />;
}

/**
 * Sağ ray (salt görüntü) — kullanıcının kendi geçmişinden. Kendi state'i olan AYRI bileşen:
 * soru bankasını (1534) çeken tembel `lib/study` importunun geç gelen setState'i yalnız burayı
 * yeniden render eder; AICoach'un giriş kutusuna dokunmaz (fill+click yarışını önler — LCP).
 */
function CoachRail() {
  const [rail, setRail] = useState<{
    answered: number;
    correct: number;
    weak: WeakTopic[];
    steps: StudyStep[];
  }>({ answered: 0, correct: 0, weak: [], steps: [] });

  useEffect(() => {
    const answers = loadAnswers();
    setRail((r) => ({
      ...r,
      answered: answers.length,
      correct: answers.filter((a) => a.correct).length,
    }));
    // Zayıf konu + plan hesapları soru bankasını gerektirir → tembel yüklenir (ilk yük hafif).
    void import('@/lib/study').then(({ weakTopics, buildStudyPlan }) => {
      setRail((r) => ({
        ...r,
        weak: weakTopics(answers, { minAnswered: 2, limit: 4 }),
        steps: buildStudyPlan(answers, loadCards(), Date.now()).steps.slice(0, 4),
      }));
    });
  }, []);

  const okPct = rail.answered ? Math.round((rail.correct / rail.answered) * 100) : 0;
  return (
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
}
