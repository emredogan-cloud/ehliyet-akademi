'use client';

import { useMemo, useState } from 'react';
import type { Question } from '@ea/content-schema';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { computeReadiness, statsFromAnswers, type Readiness } from '@ea/srs-engine';
import { saveReadiness, type StoredReadiness } from '../lib/storage';
import { track } from '../lib/analytics';

type Answer = { q: Question; chosen: number; correct: boolean };

const LIGHT_LABEL: Record<string, string> = {
  yesil: 'Yeşil — hazır',
  sari: 'Sarı — gelişiyor',
  kirmizi: 'Kırmızı — çalışmalı',
};

export function Diagnostic({ questions }: { questions: Question[] }) {
  const [i, setI] = useState(0);
  const [chosen, setChosen] = useState<number | null>(null);
  const [answers, setAnswers] = useState<Answer[]>([]);
  const [done, setDone] = useState(false);

  const total = questions.length;
  const q = questions[i];

  const readiness: Readiness | null = useMemo(() => {
    if (!done) return null;
    const { subjects } = statsFromAnswers(
      answers.map((a) => ({ subject: a.q.subject, topic: a.q.topic, correct: a.correct }))
    );
    return computeReadiness(subjects);
  }, [done, answers]);

  if (!q && !done) {
    return <p className="muted">Tanı için soru bulunamadı.</p>;
  }

  function choose(idx: number) {
    if (chosen !== null || !q) return;
    setChosen(idx);
  }

  function next() {
    if (chosen === null || !q) return;
    const rec: Answer = { q, chosen, correct: chosen === q.answerIndex };
    const nextAnswers = [...answers, rec];
    setAnswers(nextAnswers);
    setChosen(null);
    if (i + 1 < total) {
      setI(i + 1);
    } else {
      const { subjects } = statsFromAnswers(
        nextAnswers.map((a) => ({ subject: a.q.subject, topic: a.q.topic, correct: a.correct }))
      );
      const r = computeReadiness(subjects);
      const stored: StoredReadiness = {
        overall: r.overall,
        light: r.light,
        predictedPassProbability: r.predictedPassProbability,
        perSubject: r.perSubject,
        answered: nextAnswers.length,
        correct: nextAnswers.filter((a) => a.correct).length,
        at: Date.now(),
      };
      saveReadiness(stored);
      track({
        name: 'diagnostic_completed',
        props: { correct: stored.correct, total: stored.answered, overall: r.overall },
      });
      setDone(true);
    }
  }

  function restart() {
    setI(0);
    setChosen(null);
    setAnswers([]);
    setDone(false);
  }

  if (done && readiness) {
    return (
      <div className="quiz" data-testid="diagnostic-result">
        <div className="card" style={{ textAlign: 'center' }}>
          <p className="muted">Hazırlık skorun</p>
          <div className="readiness-score" style={{ color: 'var(--primary)' }}>
            {readiness.overall}%
          </div>
          <p>
            <span className={`light light--${readiness.light}`} aria-hidden />{' '}
            <strong data-testid="readiness-light">{LIGHT_LABEL[readiness.light]}</strong> · Tahmini
            geçme olasılığı: {Math.round(readiness.predictedPassProbability * 100)}%
          </p>
          <p className="muted">{readiness.message}</p>
        </div>

        <h2 className="section-title">Ders bazlı durum</h2>
        <div className="grid">
          {readiness.perSubject.map((s) => (
            <div className="card" key={s.subject}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span className={`light light--${s.light}`} aria-hidden />
                <strong>{SUBJECT_LABEL[s.subject]}</strong>
              </div>
              <p className="muted" style={{ margin: '6px 0 0' }}>
                Ustalık: {Math.round(s.mastery * 100)}%
              </p>
            </div>
          ))}
        </div>

        <div style={{ display: 'flex', gap: 10, marginTop: 20, flexWrap: 'wrap' }}>
          <button className="btn" onClick={restart}>
            Tekrar dene
          </button>
          <a className="btn btn--ghost" href="/dersler">
            Zayıf konulara çalış
          </a>
          <a className="btn btn--ghost" href="/hazirlik-skorum">
            Hazırlık skorumu gör
          </a>
        </div>
      </div>
    );
  }

  if (!q) return null; // güvenlik: tüm sorular bitti ama done henüz set edilmediyse
  const pct = Math.round((i / total) * 100);
  return (
    <div className="quiz" data-testid="diagnostic">
      <div className="progress" aria-hidden>
        <span style={{ width: `${pct}%` }} />
      </div>
      <p className="muted" aria-live="polite">
        Soru {i + 1} / {total} · {SUBJECT_LABEL[q.subject]}
      </p>
      <h2 style={{ fontSize: '1.25rem', margin: '10px 0 18px' }}>{q.stem}</h2>

      <div role="group" aria-label="Seçenekler">
        {q.options.map((opt, idx) => {
          let cls = 'opt';
          if (chosen !== null) {
            if (idx === q.answerIndex) cls += ' correct';
            else if (idx === chosen) cls += ' wrong';
          }
          return (
            <button
              key={idx}
              className={cls}
              onClick={() => choose(idx)}
              disabled={chosen !== null}
              data-testid="option"
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
            <strong>{chosen === q.answerIndex ? 'Doğru! ' : 'Yanlış. '}</strong>
            {q.explanation}
          </div>
          <button className="btn" onClick={next} data-testid="next">
            {i + 1 < total ? 'Sonraki soru →' : 'Hazırlık skorumu gör'}
          </button>
        </>
      )}
    </div>
  );
}
