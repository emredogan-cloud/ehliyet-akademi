'use client';

/**
 * Ders içi etkileşim (Sprint 3): aktif hatırlama kartları (çevir) + alıştırma soruları
 * (anında geri bildirim + KANITA DAYALI açıklama) + AI Koç giriş noktası.
 */
import { useState } from 'react';
import type { Question, ReviewCard } from '@ea/content-schema';

function mdBold(s: string): string {
  const esc = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return esc.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
}

function FlipCard({ card }: { card: ReviewCard }) {
  const [flipped, setFlipped] = useState(false);
  return (
    <button
      type="button"
      className={`flip-card ${flipped ? 'flip-card--on' : ''}`}
      onClick={() => setFlipped((v) => !v)}
      aria-pressed={flipped}
      data-testid="review-card"
    >
      <span className="flip-card__inner">
        <span className="flip-card__face flip-card__front">{card.front}</span>
        <span className="flip-card__face flip-card__back">{card.back}</span>
      </span>
    </button>
  );
}

function PracticeQuestion({ q }: { q: Question }) {
  const [chosen, setChosen] = useState<number | null>(null);
  const answered = chosen !== null;
  return (
    <div className="card practice-q" data-testid="practice-q">
      <p style={{ fontWeight: 600, margin: '0 0 10px' }}>{q.stem}</p>
      <div style={{ display: 'grid', gap: 8 }}>
        {q.options.map((opt, i) => {
          const isCorrect = i === q.answerIndex;
          const cls = !answered
            ? 'opt'
            : isCorrect
              ? 'opt opt--correct'
              : i === chosen
                ? 'opt opt--wrong'
                : 'opt';
          return (
            <button
              key={i}
              className={cls}
              onClick={() => !answered && setChosen(i)}
              disabled={answered}
              data-testid="practice-opt"
            >
              {opt}
            </button>
          );
        })}
      </div>
      {answered && (
        <div className="practice-explain" data-testid="practice-explain">
          <p style={{ margin: '10px 0 6px', fontWeight: 700 }}>
            {chosen === q.answerIndex ? '✅ Doğru' : '❌ Yanlış'} — doğru cevap:{' '}
            {q.options[q.answerIndex]}
          </p>
          <p className="prose" dangerouslySetInnerHTML={{ __html: mdBold(q.explanation) }} />
          {(q.whyWrong?.length ?? 0) > 0 && (
            <ul className="muted" style={{ margin: '6px 0 0', fontSize: '0.88rem' }}>
              {q.whyWrong!.map((w, k) => (
                <li key={k}>{w}</li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

export function LessonPractice({
  reviewCards,
  practice,
  lessonTitle,
}: {
  reviewCards: ReviewCard[];
  practice: Question[];
  lessonTitle: string;
}) {
  return (
    <div>
      {reviewCards.length > 0 && (
        <>
          <h2 className="section-title">Tekrar kartları</h2>
          <p className="muted" style={{ marginTop: 0 }}>
            Karta dokun, cevabı gör. Aktif hatırlama kalıcılığı artırır.
          </p>
          <div className="flip-grid">
            {reviewCards.map((c, k) => (
              <FlipCard key={k} card={c} />
            ))}
          </div>
        </>
      )}

      {practice.length > 0 && (
        <>
          <h2 className="section-title">Alıştırma soruları</h2>
          <div style={{ display: 'grid', gap: 12 }}>
            {practice.map((q) => (
              <PracticeQuestion key={q.id} q={q} />
            ))}
          </div>
        </>
      )}

      <div
        className="card"
        style={{
          marginTop: 18,
          background: 'var(--primary-050)',
          borderColor: 'var(--primary-100)',
        }}
      >
        <strong>🤖 Takıldığın yer mi var?</strong>
        <p className="muted" style={{ margin: '6px 0 10px' }}>
          AI Koç bu dersin içeriğinden yanıtlar; ayrıca sana özel çalışma planı çıkarır.
        </p>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <a
            className="btn btn--sm"
            href={`/ai-koc?soru=${encodeURIComponent(lessonTitle + ' konusunu özetle')}`}
          >
            Bu dersi AI Koç'a sor
          </a>
          <a className="btn btn--ghost btn--sm" href="/calisma-plani">
            Çalışma planım
          </a>
        </div>
      </div>
    </div>
  );
}
