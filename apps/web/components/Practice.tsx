'use client';

/**
 * SRS pratik döngüsü (ROADMAP Faz 9): vadesi gelen kartlar + zayıf konular +
 * yeni sorulardan adaptif seçim; her cevap SM-2 ile yeniden planlanır.
 */
import { useEffect, useMemo, useState } from 'react';
import type { Question } from '@ea/content-schema';
import { SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
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
import { QuizLayout, QuizPanel, DonutStat, QuizNav, HintCard, type QuizNavState } from './ui/quiz';

const SESSION_SIZE = 10;

export function Practice() {
  const [queue, setQueue] = useState<Question[]>([]);
  const [i, setI] = useState(0);
  const [chosen, setChosen] = useState<number | null>(null);
  const [correctCount, setCorrectCount] = useState(0);
  const [dueCount, setDueCount] = useState(0);
  const [streak, setStreak] = useState(0);
  const [done, setDone] = useState(false);
  const [ready, setReady] = useState(false);
  // Salt görüntü: oturum içi soru sonuçları (ray navigasyonu) + genel konu dağılımı.
  const [results, setResults] = useState<boolean[]>([]);
  const [subjectBars, setSubjectBars] = useState<Array<{ label: string; pct: number }>>([]);

  // Oturum kuyruğunu kur (yalnız istemcide — localStorage).
  useEffect(() => {
    let alive = true;
    const cards = loadCards();
    const answers = loadAnswers();
    const { topicMastery, subjects } = statsFromAnswers(answers);
    const now = Date.now();
    setDueCount([...cards.values()].filter((c) => isDue(c, now)).length);
    setStreak(loadStreak().current);
    setSubjectBars(
      THEORY_SUBJECTS.map((s) => {
        const st = subjects.find((x) => x.subject === s);
        return { label: SUBJECT_LABEL[s], pct: st ? Math.round(st.mastery * 100) : 0 };
      })
    );
    // Soru bankası (1534) tembel yüklenir → önceden props ile sayfaya gömülüyordu (~340 KB gzip
    // ilk yük); artık istemcide async yüklenir, sayfa payload'ı düşer (PERF).
    void import('@ea/question-bank').then(({ allQuestions }) => {
      if (!alive) return;
      const pool = allQuestions().filter((qq) => qq.subject !== 'pratik');
      const ids = selectNext(
        pool.map((qq) => ({ id: qq.id, subject: qq.subject, topic: qq.topic })),
        cards,
        topicMastery,
        now,
        SESSION_SIZE
      );
      const byId = new Map(pool.map((qq) => [qq.id, qq]));
      setQueue(ids.map((id) => byId.get(id)!).filter(Boolean));
      setReady(true);
    });
    return () => {
      alive = false;
    };
  }, []);

  const q = queue[i];
  const pct = useMemo(() => (queue.length ? Math.round((i / queue.length) * 100) : 0), [i, queue]);

  function choose(idx: number) {
    if (chosen !== null || !q) return;
    setChosen(idx);
    const correct = idx === q.answerIndex;
    if (correct) setCorrectCount((c) => c + 1);
    setResults((r) => [...r, correct]);

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

  const navStates: QuizNavState[] = queue.map((_, k) => {
    if (k < results.length) return results[k] ? 'correct' : 'wrong';
    if (k === i) return 'current';
    return 'todo';
  });

  const main = (
    <div className="quiz" data-testid="practice">
      <div className="ui-card ui-card--accent hero-banner quiz-streak">
        <span className="quiz-streak__flame" aria-hidden>
          🔥
        </span>
        <div className="hero-banner__body">
          <div className="quiz-streak__text">
            Seri: <strong>{streak} gün</strong> · Vadesi gelen kart: <strong>{dueCount}</strong> ·
            Soru{' '}
            <strong>
              {i + 1}/{queue.length}
            </strong>
          </div>
          <div className="progress" aria-hidden style={{ marginTop: 8 }}>
            <span style={{ width: `${pct}%` }} />
          </div>
        </div>
      </div>

      <div className="ui-card quiz-card" style={{ marginTop: 'var(--sp-4)' }}>
        <p className="muted" aria-live="polite" style={{ marginTop: 0 }}>
          <span style={{ color: 'var(--primary)', fontWeight: 700 }}>
            {SUBJECT_LABEL[q!.subject]}
          </span>{' '}
          · {q!.topic}
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
    </div>
  );

  const aside = (
    <>
      <QuizPanel title="Soru Navigasyonu" icon="target">
        <QuizNav states={navStates} />
      </QuizPanel>
      <QuizPanel title="İlerleme" icon="trending">
        <DonutStat
          pct={queue.length ? Math.round((results.length / queue.length) * 100) : 0}
          center={`%${queue.length ? Math.round((results.length / queue.length) * 100) : 0}`}
          sub="Tamamlandı"
          rows={[
            { color: 'var(--accent-green)', label: 'Doğru', value: correctCount },
            { color: 'var(--accent-red)', label: 'Yanlış', value: results.length - correctCount },
            { color: 'var(--text-3)', label: 'Toplam', value: queue.length },
          ]}
        />
      </QuizPanel>
      <QuizPanel title="Konu Dağılımı" icon="layers">
        <div style={{ display: 'grid', gap: 10 }}>
          {subjectBars.map((b) => (
            <div key={b.label}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontSize: 'var(--fs-sm)',
                  marginBottom: 4,
                }}
              >
                <span>{b.label}</span>
                <span className="muted">%{b.pct}</span>
              </div>
              <div className="ui-progress">
                <span className="ui-progress__fill" style={{ width: `${b.pct}%` }} />
              </div>
            </div>
          ))}
        </div>
      </QuizPanel>
      <HintCard>
        Yanlışların aralıklı tekrar (SRS) planına eklenir — tam unutacağın sırada yeniden sorulur.
      </HintCard>
    </>
  );

  return <QuizLayout main={main} aside={aside} />;
}
