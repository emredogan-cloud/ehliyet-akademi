'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { PageHeader } from '@/components/ui/layout';
import { ReportQuestion } from '@/components/ReportQuestion';

interface Q {
  id: string;
  subject: string;
  stem: string;
  options: string[];
  answerIndex: number;
  explanation: string;
}
interface Exam {
  session: { label: string };
  label: string;
  bySubject: Record<string, number>;
  questions: Q[];
}

const SUBJECT_TR: Record<string, string> = {
  trafik: 'Trafik',
  ilkyardim: 'İlk Yardım',
  motor: 'Araç Tekniği',
  adab: 'Trafik Adabı',
  pratik: 'Direksiyon',
};

export default function HistoricalExamPage() {
  const params = useParams<{ id: string }>();
  const [exam, setExam] = useState<Exam | null>(null);
  const [err, setErr] = useState('');
  const [reveal, setReveal] = useState(false);

  useEffect(() => {
    if (!params?.id) return;
    void fetch(`/api/qip/historical/${params.id}`)
      .then((r) => (r.ok ? r.json() : Promise.reject(r.status)))
      .then((d: Exam) => setExam(d))
      .catch(() => setErr('Sınav bulunamadı.'));
  }, [params?.id]);

  return (
    <div>
      <PageHeader
        title={exam ? exam.session.label : 'Deneme Sınavı'}
        emoji="📝"
        subtitle={exam?.label ?? 'MEB formatında hazırlanmış özgün deneme sınavı'}
      />

      <div className="explain" role="note" data-testid="historical-exam-disclaimer">
        Bu sınav <strong>MEB formatında hazırlanmış özgün deneme sınavıdır</strong>; gerçek çıkmış
        soruların kopyası değildir. Sorular bankamızın özgün içeriğinden, o tarihe göre
        üretilmiştir.
      </div>

      {err && (
        <div className="explain" role="alert">
          {err}
        </div>
      )}

      {!exam ? (
        <div className="card" aria-busy="true">
          <div className="skeleton" style={{ height: 40 }} />
        </div>
      ) : (
        <div data-testid="historical-exam">
          <div
            className="card"
            style={{ display: 'flex', gap: 18, flexWrap: 'wrap', alignItems: 'center' }}
          >
            <div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{exam.questions.length}</div>
              <div className="muted" style={{ fontSize: '0.78rem' }}>
                soru
              </div>
            </div>
            {Object.entries(exam.bySubject).map(([s, n]) => (
              <div key={s}>
                <div style={{ fontSize: '1.1rem', fontWeight: 700 }}>{n}</div>
                <div className="muted" style={{ fontSize: '0.72rem' }}>
                  {SUBJECT_TR[s] ?? s}
                </div>
              </div>
            ))}
            <button
              className="ui-btn ui-btn--primary ui-btn--sm"
              style={{ marginLeft: 'auto' }}
              onClick={() => setReveal((v) => !v)}
              data-testid="historical-reveal"
            >
              {reveal ? 'Cevapları gizle' : 'Cevapları göster'}
            </button>
          </div>

          <div style={{ display: 'grid', gap: 10, marginTop: 14 }}>
            {exam.questions.map((q, i) => (
              <div
                key={q.id}
                className="card"
                style={{ margin: 0 }}
                data-testid="historical-question"
              >
                <div style={{ display: 'flex', gap: 8, alignItems: 'baseline' }}>
                  <strong style={{ minWidth: 28 }}>{i + 1}.</strong>
                  <span style={{ flex: 1 }}>{q.stem}</span>
                  <span className="badge">{SUBJECT_TR[q.subject] ?? q.subject}</span>
                </div>
                <ol style={{ margin: '8px 0 0 26px', fontSize: '0.9rem' }}>
                  {q.options.map((o, oi) => (
                    <li
                      key={oi}
                      style={{
                        fontWeight: reveal && oi === q.answerIndex ? 700 : 400,
                        color: reveal && oi === q.answerIndex ? 'var(--accent-green)' : undefined,
                      }}
                    >
                      {o} {reveal && oi === q.answerIndex ? '✓' : ''}
                    </li>
                  ))}
                </ol>
                {reveal && (
                  <p className="muted" style={{ margin: '8px 0 0 26px', fontSize: '0.85rem' }}>
                    {q.explanation}
                  </p>
                )}
                <div style={{ marginLeft: 26, marginTop: 6 }}>
                  <ReportQuestion questionId={q.id} />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
