'use client';

/**
 * e-Sınav Simülatörü (ROADMAP Faz 13) — gerçek format: 50 soru · 45 dk · baraj 35.
 * Resmî MEB sınavı DEĞİLDİR; gerçek sınav formatında denemedir (dürüst etiket).
 */
import { useEffect, useMemo, useRef, useState } from 'react';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { buildExam, scoreExam, type BuiltExam, type ExamResult } from '../lib/exam';
import { appendAnswers, touchStreak } from '../lib/progress';
import { canStartFreeExam, consumeFreeExam, loadEntitlements } from '../lib/payments';
import { hasCapability } from '../lib/products';

function fmt(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

export function ExamSimulator() {
  const [exam, setExam] = useState<BuiltExam | null>(null);
  const [answers, setAnswers] = useState<Array<number | null>>([]);
  const [i, setI] = useState(0);
  const [left, setLeft] = useState(0);
  const [result, setResult] = useState<ExamResult | null>(null);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);

  const [blocked, setBlocked] = useState(false);

  function start() {
    // Ücretsiz kademe: günde 1 deneme. Paket (sınırsız-deneme yeteneği) → sınırsız. (Faz 16)
    const unlimited = hasCapability(loadEntitlements(), 'sinirsiz-deneme');
    if (!unlimited && !canStartFreeExam()) {
      // Kota dolu: intro görünümüne dön ki kota/paket mesajı görünsün.
      setExam(null);
      setResult(null);
      setBlocked(true);
      return;
    }
    if (!unlimited) consumeFreeExam();
    setBlocked(false);
    const e = buildExam();
    setExam(e);
    setAnswers(new Array(e.questions.length).fill(null));
    setI(0);
    setResult(null);
    setLeft(e.durationSeconds);
  }

  // Geri sayım
  useEffect(() => {
    if (!exam || result) return;
    timer.current = setInterval(() => {
      setLeft((l) => {
        if (l <= 1) {
          if (timer.current) clearInterval(timer.current);
          return 0;
        }
        return l - 1;
      });
    }, 1000);
    return () => {
      if (timer.current) clearInterval(timer.current);
    };
  }, [exam, result]);

  // Süre bitti → otomatik teslim. (Bilinçli dar bağımlılık: yalnız `left` değişince
  // kontrol edilir; finish referansı her render'da tazedir ve exam/result'ı içeride okur.)
  useEffect(() => {
    if (exam && !result && left === 0) finish();
  }, [left]);

  const answeredCount = useMemo(() => answers.filter((a) => a !== null).length, [answers]);

  function finish() {
    if (!exam) return;
    if (timer.current) clearInterval(timer.current);
    const r = scoreExam(exam.questions, answers, exam.passCorrect);
    setResult(r);
    // SRS/istatistik geçmişine yaz + seri
    appendAnswers(
      exam.questions.map((q, k) => ({
        questionId: q.id,
        subject: q.subject,
        topic: q.topic,
        correct: answers[k] === q.answerIndex,
        at: Date.now(),
      }))
    );
    touchStreak();
  }

  if (!exam) {
    return (
      <div className="card" style={{ textAlign: 'center' }} data-testid="exam-intro">
        <h2>Gerçek formatta deneme</h2>
        <p className="muted">
          50 soru · 45 dakika · geçmek için 35 doğru. Dağılım gerçek e-Sınav gibidir: Trafik 23 ·
          İlk Yardım 12 · Motor 9 · Adab 6. Süre bitince otomatik teslim edilir.
        </p>
        <button className="btn" onClick={start} data-testid="exam-start">
          Denemeyi başlat →
        </button>
        {blocked && (
          <div className="explain" role="status" style={{ marginTop: 14 }} data-testid="exam-quota">
            Bugünkü ücretsiz denemeni kullandın. <strong>Sınırsız deneme</strong> için tek-seferlik{' '}
            <a href="/fiyatlandirma">Simülatör Paketi</a>ne göz at — abonelik yok, bir kez öde.
          </div>
        )}
      </div>
    );
  }

  if (result) {
    return (
      <div data-testid="exam-result">
        <div className="card" style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '2.6rem' }}>{result.passed ? '✅' : '🚫'}</div>
          <div
            className="readiness-score"
            style={{ color: result.passed ? 'var(--green)' : 'var(--red)' }}
          >
            {result.correct}/{result.total}
          </div>
          <p>
            <strong data-testid="exam-verdict">{result.passed ? 'GEÇTİN' : 'KALDIN'}</strong> ·
            baraj {exam.passCorrect} doğru
          </p>
          <p className="muted">
            {result.passed
              ? 'Tebrikler! Yine de yanlış yaptığın konuları SRS pratiğiyle pekiştir.'
              : 'Üzülme — yanlışların çalışma planına eklendi. Zayıf derslere odaklan, tekrar dene.'}
          </p>
        </div>
        <h2 className="section-title">Ders bazlı sonuç</h2>
        <div className="grid">
          {result.perSubject.map((s) => (
            <div className="card" key={s.subject}>
              <strong>{SUBJECT_LABEL[s.subject as keyof typeof SUBJECT_LABEL] ?? s.subject}</strong>
              <p className="muted" style={{ margin: '6px 0 0' }}>
                {s.correct}/{s.total} doğru
              </p>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 18, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn" onClick={start}>
            Yeni deneme
          </button>
          <a className="btn btn--ghost" href="/calis">
            Yanlışlara çalış (SRS)
          </a>
        </div>
      </div>
    );
  }

  const q = exam.questions[i]!;
  return (
    <div data-testid="exam-running">
      <div
        className="card"
        style={{
          display: 'flex',
          gap: 12,
          alignItems: 'center',
          flexWrap: 'wrap',
          position: 'sticky',
          top: 66,
          zIndex: 10,
        }}
      >
        <strong data-testid="exam-timer" aria-live="off">
          ⏱ {fmt(left)}
        </strong>
        <span className="muted">
          Soru {i + 1}/{exam.questions.length} · cevaplanan {answeredCount}
        </span>
        {!exam.fullBlueprint && <span className="badge">kısaltılmış deneme</span>}
        <button
          className="btn"
          style={{ marginLeft: 'auto' }}
          onClick={finish}
          data-testid="exam-finish"
        >
          Sınavı bitir
        </button>
      </div>

      <p className="muted" style={{ marginTop: 14 }}>
        {SUBJECT_LABEL[q.subject]}
      </p>
      <h2 style={{ fontSize: '1.2rem', margin: '6px 0 16px' }}>{q.stem}</h2>
      <div role="group" aria-label="Seçenekler">
        {q.options.map((opt, idx) => (
          <button
            key={idx}
            className="opt"
            style={
              answers[i] === idx
                ? { borderColor: 'var(--primary)', background: 'var(--primary-050)' }
                : undefined
            }
            onClick={() => {
              const next = answers.slice();
              next[i] = idx;
              setAnswers(next);
            }}
            data-testid="e-option"
            aria-pressed={answers[i] === idx}
          >
            <span className="opt__key">{String.fromCharCode(65 + idx)}</span>
            <span>{opt}</span>
          </button>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', margin: '14px 0' }}>
        <button
          className="btn btn--ghost"
          onClick={() => setI(Math.max(0, i - 1))}
          disabled={i === 0}
        >
          ← Önceki
        </button>
        <button
          className="btn"
          onClick={() => setI(Math.min(exam.questions.length - 1, i + 1))}
          disabled={i === exam.questions.length - 1}
          data-testid="e-next"
        >
          Sonraki →
        </button>
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(36px, 1fr))',
          gap: 6,
        }}
        aria-label="Soru haritası"
      >
        {exam.questions.map((_, k) => (
          <button
            key={k}
            onClick={() => setI(k)}
            className="opt__key"
            style={{
              height: 32,
              cursor: 'pointer',
              border:
                k === i
                  ? '2px solid var(--primary)'
                  : answers[k] !== null
                    ? '1.5px solid var(--green)'
                    : '1.5px solid var(--border)',
              background:
                answers[k] !== null
                  ? 'color-mix(in srgb, var(--green) 14%, var(--surface))'
                  : 'var(--surface)',
              borderRadius: 8,
            }}
            aria-label={`Soru ${k + 1}${answers[k] !== null ? ' (cevaplandı)' : ''}`}
          >
            {k + 1}
          </button>
        ))}
      </div>
    </div>
  );
}
