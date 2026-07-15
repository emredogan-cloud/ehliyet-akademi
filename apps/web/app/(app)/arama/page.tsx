'use client';

/** Arama (Faz 28 hafif sürüm): dersler + soru bankası üzerinde anlık istemci araması.
 *  Ölçekte Meilisearch/Typesense adaptörüne geçilir (ENV_SETUP_GUIDE). */
import { useMemo, useState } from 'react';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { allQuestions } from '@ea/question-bank';
import { LESSONS } from '@/content/lessons';

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

export default function AramaPage() {
  const [q, setQ] = useState('');

  const results = useMemo(() => {
    const nq = norm(q.trim());
    if (nq.length < 2) return { lessons: [], questions: [] };
    const lessons = LESSONS.filter((l) =>
      norm(
        l.title + ' ' + l.summary + ' ' + l.sections.map((s) => s.heading + ' ' + s.body).join(' ')
      ).includes(nq)
    ).slice(0, 8);
    const questions = allQuestions()
      .filter((x) => norm(x.stem + ' ' + x.topic + ' ' + x.explanation).includes(nq))
      .slice(0, 10);
    return { lessons, questions };
  }, [q]);

  const empty = q.trim().length >= 2 && !results.lessons.length && !results.questions.length;

  return (
    <>
      <h1 style={{ margin: '6px 0 4px' }}>Arama</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Ders ve soru bankasında anında ara.
      </p>
      <input
        className="chat__input"
        style={{ width: '100%', maxWidth: 560 }}
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="örn. hız sınırı, kalp masajı, DUR levhası…"
        aria-label="Arama"
        data-testid="search-input"
        autoFocus
      />

      {empty && (
        <div className="card" style={{ marginTop: 16 }} data-testid="search-empty">
          <p style={{ margin: 0 }}>"{q}" için sonuç yok. Farklı bir kelime dene.</p>
        </div>
      )}

      {results.lessons.length > 0 && (
        <>
          <h2 className="section-title">Dersler</h2>
          <div className="grid" data-testid="search-lessons">
            {results.lessons.map((l) => (
              <a key={l.id} className="card card--link" href={`/dersler/${l.slug}`}>
                <span className="badge">{SUBJECT_LABEL[l.subject]}</span>
                <h3 style={{ margin: '8px 0 4px' }}>{l.title}</h3>
                <p className="muted" style={{ margin: 0 }}>
                  {l.summary}
                </p>
              </a>
            ))}
          </div>
        </>
      )}

      {results.questions.length > 0 && (
        <>
          <h2 className="section-title">Sorular</h2>
          <div style={{ display: 'grid', gap: 10 }} data-testid="search-questions">
            {results.questions.map((x) => (
              <div key={x.id} className="card">
                <span className="badge">
                  {SUBJECT_LABEL[x.subject]} · {x.topic}
                </span>
                <p style={{ margin: '8px 0 4px', fontWeight: 600 }}>{x.stem}</p>
                <p className="muted" style={{ margin: 0, fontSize: '0.9rem' }}>
                  Cevap: {x.options[x.answerIndex]}
                </p>
              </div>
            ))}
          </div>
        </>
      )}
    </>
  );
}
