'use client';

/**
 * SRS pratik döngüsü (ROADMAP Faz 9): vadesi gelen kartlar + zayıf konular +
 * yeni sorulardan adaptif seçim; her cevap SM-2 ile yeniden planlanır.
 */
import { useEffect, useMemo, useState } from 'react';
import type { Question } from '@ea/content-schema';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { newCard, review, isDue, selectNext, statsFromAnswers, toGrade } from '@ea/srs-engine';
import {
  loadCards,
  saveCards,
  loadAnswers,
  appendAnswers,
  touchStreak,
  loadStreak,
} from '../lib/progress';
import { track } from '../lib/analytics';

const SESSION_SIZE = 10;

export function Practice({ pool }: { pool: Question[] }) {
  const [queue, setQueue] = useState<Question[]>([]);
  const [i, setI] = useState(0);
  const [chosen, setChosen] = useState<number | null>(null);
  const [correctCount, setCorrectCount] = useState(0);
  const [dueCount, setDueCount] = useState(0);
  const [streak, setStreak] = useState(0);
  const [done, setDone] = useState(false);
  const [ready, setReady] = useState(false);

  // Oturum kuyruğunu kur (yalnız istemcide — localStorage).
  useEffect(() => {
    const cards = loadCards();
    const answers = loadAnswers();
    const { topicMastery } = statsFromAnswers(answers);
    const now = Date.now();
    setDueCount([...cards.values()].filter((c) => isDue(c, now)).length);
    setStreak(loadStreak().current);
    const ids = selectNext(
      pool.map((q) => ({ id: q.id, subject: q.subject, topic: q.topic })),
      cards,
      topicMastery,
      now,
      SESSION_SIZE
    );
    const byId = new Map(pool.map((q) => [q.id, q]));
    setQueue(ids.map((id) => byId.get(id)!).filter(Boolean));
    setReady(true);
  }, [pool]);

  const q = queue[i];
  const pct = useMemo(() => (queue.length ? Math.round((i / queue.length) * 100) : 0), [i, queue]);

  function choose(idx: number) {
    if (chosen !== null || !q) return;
    setChosen(idx);
    const correct = idx === q.answerIndex;
    if (correct) setCorrectCount((c) => c + 1);

    // SRS güncelle + geçmişe yaz + seriyi işle
    const cards = loadCards();
    const card = cards.get(q.id) ?? newCard(q.id, Date.now());
    cards.set(q.id, review(card, toGrade(correct ? 'good' : 'again'), Date.now()));
    saveCards(cards);
    appendAnswers([
      { questionId: q.id, subject: q.subject, topic: q.topic, correct, at: Date.now() },
    ]);
    const s = touchStreak();
    setStreak(s.current);
  }

  function next() {
    if (i + 1 < queue.length) {
      setI(i + 1);
      setChosen(null);
    } else {
      track({
        name: 'practice_session_completed',
        props: { correct: correctCount, total: queue.length, streak },
      });
      setDone(true);
    }
  }

  if (!ready) return <p className="muted">Hazırlanıyor…</p>;

  if (!queue.length) {
    return (
      <div className="card" data-testid="practice-empty">
        <p>Şu an çalışılacak soru bulunamadı.</p>
        <a className="btn" href="/tani">
          Tanı denemesiyle başla
        </a>
      </div>
    );
  }

  if (done) {
    return (
      <div className="card" style={{ textAlign: 'center' }} data-testid="practice-done">
        <h2>Oturum tamamlandı 🎉</h2>
        <p>
          {correctCount}/{queue.length} doğru · Seri: <strong>{streak} gün</strong> 🔥
        </p>
        <p className="muted">
          Yanlışların aralıklı tekrar (SRS) planına eklendi — tam unutacağın sırada yeniden
          soracağız.
        </p>
        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', flexWrap: 'wrap' }}>
          <button className="btn" onClick={() => window.location.reload()}>
            Yeni oturum
          </button>
          <a className="btn btn--ghost" href="/hazirlik-skorum">
            Hazırlık skorum
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="quiz" data-testid="practice">
      <p className="muted">
        🔥 Seri: {streak} gün · Vadesi gelen kart: {dueCount} · Soru {i + 1}/{queue.length}
      </p>
      <div className="progress" aria-hidden>
        <span style={{ width: `${pct}%` }} />
      </div>
      <p className="muted" aria-live="polite">
        {SUBJECT_LABEL[q!.subject]} · {q!.topic}
      </p>
      <h2 style={{ fontSize: '1.2rem', margin: '10px 0 16px' }}>{q!.stem}</h2>
      <div role="group" aria-label="Seçenekler">
        {q!.options.map((opt, idx) => {
          let cls = 'opt';
          if (chosen !== null) {
            if (idx === q!.answerIndex) cls += ' correct';
            else if (idx === chosen) cls += ' wrong';
          }
          return (
            <button
              key={idx}
              className={cls}
              onClick={() => choose(idx)}
              disabled={chosen !== null}
              data-testid="p-option"
            >
              <span className="opt__key">{String.fromCharCode(65 + idx)}</span>
              <span>{opt}</span>
            </button>
          );
        })}
      </div>
      {chosen !== null && (
        <>
          <div className="explain" role="status">
            <strong>{chosen === q!.answerIndex ? 'Doğru! ' : 'Yanlış. '}</strong>
            {q!.explanation}
          </div>
          <button className="btn" onClick={next} data-testid="p-next">
            {i + 1 < queue.length ? 'Sonraki →' : 'Oturumu bitir'}
          </button>
        </>
      )}
    </div>
  );
}
