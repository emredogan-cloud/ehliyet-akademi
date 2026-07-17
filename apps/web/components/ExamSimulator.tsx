'use client';

/**
 * e-Sınav Simülatörü (ROADMAP Faz 13 · Program 3.1 görsel yenileme, ref 015/016/018/019)
 * — gerçek format: 50 soru · 45 dk · baraj 35.
 * Resmî MEB sınavı DEĞİLDİR; gerçek sınav formatında denemedir (dürüst etiket).
 * Sınav mantığı (kota, kurulum, süre, puanlama) DEĞİŞMEDİ — yalnız sunum yenilendi.
 */
import { useEffect, useMemo, useRef, useState } from 'react';
import { SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { statsFromAnswers } from '@ea/srs-engine';
import { buildExam, scoreExam, type BuiltExam, type ExamResult } from '../lib/exam';
import {
  appendAnswers,
  touchStreak,
  incrementExamsFinished,
  loadAnswers,
  loadCounters,
} from '../lib/progress';
import { canStartFreeExam, consumeFreeExam, loadEntitlements } from '../lib/payments';
import { hasCapability } from '../lib/products';
import { track } from '../lib/analytics';
import { Icon } from './ui/icons';
import { QuizLayout, QuizPanel, DonutStat, InfoRow } from './ui/quiz';

function fmt(sec: number): string {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

/** Konu performans etiketi (salt sunum). */
function ratingOf(pct: number): { label: string; color: string } {
  if (pct >= 85) return { label: 'Çok İyi', color: 'var(--accent-green)' };
  if (pct >= 70) return { label: 'İyi', color: 'var(--primary)' };
  if (pct >= 50) return { label: 'Orta', color: 'var(--accent-amber)' };
  return { label: 'Zayıf', color: 'var(--accent-red)' };
}

/** Geçmiş (tüm cevaplar) üzerinden ders dağılımı — ray için. */
function useSubjectBars() {
  const [bars, setBars] = useState<Array<{ label: string; pct: number }>>([]);
  useEffect(() => {
    const { subjects } = statsFromAnswers(loadAnswers());
    setBars(
      THEORY_SUBJECTS.map((s) => {
        const st = subjects.find((x) => x.subject === s);
        return { label: SUBJECT_LABEL[s], pct: st ? Math.round(st.mastery * 100) : 0 };
      })
    );
  }, []);
  return bars;
}

const TIPS = [
  'Düzenli deneme çözmek sınav başarınızı artırır.',
  'Yanlış yaptığınız soruları tekrar çalışın.',
  'Süre yönetimine dikkat ederek pratik yapın.',
  'Zorlandığın konulara tekrar çalış.',
];

export function ExamSimulator() {
  const [exam, setExam] = useState<BuiltExam | null>(null);
  const [answers, setAnswers] = useState<Array<number | null>>([]);
  const [i, setI] = useState(0);
  const [left, setLeft] = useState(0);
  const [result, setResult] = useState<ExamResult | null>(null);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);

  const [blocked, setBlocked] = useState(false);
  const [pastExams, setPastExams] = useState(0);
  const subjectBars = useSubjectBars();

  useEffect(() => {
    setPastExams(loadCounters().examsFinished);
  }, [result]);

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
    incrementExamsFinished();
    track({
      name: 'exam_finished',
      props: { correct: r.correct, total: r.total, passed: r.passed },
    });
  }

  /* Ortak ray blokları */
  const tipsPanel = (
    <QuizPanel title="Sınav İpuçları" icon="target">
      <ul className="exam-tips">
        {TIPS.map((t) => (
          <li key={t}>
            <span className="exam-tips__check" aria-hidden>
              <Icon name="check-circle" size={15} />
            </span>
            {t}
          </li>
        ))}
      </ul>
    </QuizPanel>
  );

  const distPanel = (
    <QuizPanel title="Konu Dağılımın" icon="layers">
      <div style={{ display: 'grid', gap: 10 }}>
        {subjectBars.map((b) => (
          <div key={b.label}>
            <div className="exam-bar-row">
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
  );

  /* ── Intro (ref 015) ── */
  if (!exam) {
    const main = (
      <>
        <div className="ui-card exam-intro" data-testid="exam-intro">
          <span className="ui-iconbadge ui-iconbadge--lg" aria-hidden>
            <Icon name="timer" size={28} />
          </span>
          <div className="exam-intro__body">
            <h2 className="exam-intro__title">Gerçek formatta deneme</h2>
            <div className="exam-intro__meta">
              <span className="ui-tag">50 soru</span>
              <span className="ui-tag">45 dakika</span>
              <span className="ui-tag">Geçmek için 35 doğru</span>
            </div>
            <p className="muted exam-intro__note">
              Dağılım gerçek e-Sınav gibidir: Trafik 23 · İlk Yardım 12 · Motor 9 · Adab 6. Süre
              bitince otomatik teslim edilir.
            </p>
          </div>
          <button
            className="ui-btn ui-btn--primary ui-btn--lg"
            onClick={start}
            data-testid="exam-start"
          >
            Denemeyi başlat →
          </button>
        </div>
        {blocked && (
          <div className="explain" role="status" style={{ marginTop: 14 }} data-testid="exam-quota">
            Bugünkü ücretsiz denemeni kullandın. <strong>Sınırsız deneme</strong> için tek-seferlik{' '}
            <a href="/fiyatlandirma">Simülatör Paketi</a>ne göz at — abonelik yok, bir kez öde.
          </div>
        )}
        <div className="ui-card quiz-panel" style={{ marginTop: 'var(--sp-4)' }}>
          <h3 className="quiz-panel__title">
            <span className="quiz-panel__ic" aria-hidden>
              <Icon name="clipboard" size={17} />
            </span>
            Son denemelerim
          </h3>
          {pastExams > 0 ? (
            <p className="muted" style={{ margin: '10px 0 0', fontSize: 'var(--fs-sm)' }}>
              Şimdiye dek <strong style={{ color: 'var(--text)' }}>{pastExams} deneme</strong>{' '}
              tamamladın. Ders bazlı gelişimini <a href="/ilerleme">İlerleme sayfasından</a> takip
              edebilirsin.
            </p>
          ) : (
            <p className="muted" style={{ margin: '10px 0 0', fontSize: 'var(--fs-sm)' }}>
              Henüz deneme çözmedin. İlk denemen sonrası sonuçların burada görünecek.
            </p>
          )}
        </div>
      </>
    );
    const aside = (
      <>
        {distPanel}
        {tipsPanel}
      </>
    );
    return <QuizLayout main={main} aside={aside} />;
  }

  /* ── Sonuç (ref 018/019) ── */
  if (result) {
    const wrong = answers.filter(
      (a, k) => a !== null && a !== exam.questions[k]?.answerIndex
    ).length;
    const empty = result.total - result.correct - wrong;
    const usedSec = Math.max(0, exam.durationSeconds - left);
    const okPct = result.total ? Math.round((result.correct / result.total) * 100) : 0;

    const main = (
      <div data-testid="exam-result">
        <div
          className={`ui-card exam-hero ${result.passed ? 'exam-hero--win' : 'exam-hero--fail'}`}
        >
          <div className="exam-hero__medal" aria-hidden>
            {result.passed ? <Icon name="trophy" size={44} /> : <Icon name="ban" size={44} />}
          </div>
          <div className="exam-hero__ribbon">{result.passed ? 'TEBRİKLER!' : 'SONUÇ'}</div>
          <h2 className="exam-hero__title">
            {result.passed
              ? 'Deneme Sınavını Başarıyla Geçtin!'
              : `${result.correct}/${result.total}`}
          </h2>
          <p className="exam-hero__verdict">
            <strong data-testid="exam-verdict">{result.passed ? 'GEÇTİN' : 'KALDIN'}</strong> ·
            baraj {exam.passCorrect} doğru
          </p>
          <p className="muted exam-hero__msg">
            {result.passed
              ? 'Gerçek sınava hazırsın! Yine de yanlış yaptığın konuları SRS pratiğiyle pekiştir.'
              : 'Üzülme — yanlışların çalışma alanına dönüştü. Zayıf derslere odaklan, tekrar dene.'}
          </p>
        </div>

        <div className="exam-stats">
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Başarı Oranın</span>
            <strong className="exam-stat__value">%{okPct}</strong>
            <span className="muted exam-stat__sub">
              {result.correct} doğru / {result.total} soru
            </span>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Doğru</span>
            <strong className="exam-stat__value" style={{ color: 'var(--accent-green)' }}>
              {result.correct}
            </strong>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Yanlış</span>
            <strong className="exam-stat__value" style={{ color: 'var(--accent-red)' }}>
              {wrong}
            </strong>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Boş</span>
            <strong className="exam-stat__value">{empty}</strong>
          </div>
          <div className="ui-card exam-stat">
            <span className="exam-stat__label">Toplam Süre</span>
            <strong className="exam-stat__value">
              <Icon name="timer" size={18} /> {fmt(usedSec)}
            </strong>
            <span className="muted exam-stat__sub">/ {fmt(exam.durationSeconds)}</span>
          </div>
        </div>

        <div
          className={`callout ${result.passed ? 'callout--success' : 'callout--warn'}`}
          role="note"
        >
          <span className="callout__icon" aria-hidden>
            <Icon name={result.passed ? 'shield' : 'target'} size={20} />
          </span>
          <div className="callout__body">
            <strong className="callout__title">
              {result.passed ? 'Harika bir performans sergiledin!' : 'Gelişim Önerisi'}
            </strong>
            <div className="callout__text">
              {result.passed
                ? 'Zayıf olduğun konulara odaklanarak başarını daha da artırabilirsin.'
                : 'En çok zorlandığın konulara odaklanman başarıyı artıracaktır. Yanlış yaptığın soruları çalışma planından tekrar et.'}
            </div>
          </div>
        </div>

        <h2 className="section-title">Ders bazlı sonuç</h2>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '200px' }}>
          {result.perSubject.map((s) => {
            const pct = s.total ? Math.round((s.correct / s.total) * 100) : 0;
            const rating = ratingOf(pct);
            return (
              <div className="ui-card exam-subject" key={s.subject}>
                <strong className="exam-subject__name">
                  {SUBJECT_LABEL[s.subject as keyof typeof SUBJECT_LABEL] ?? s.subject}
                </strong>
                <DonutStat pct={pct} center={`%${pct}`} size={88} />
                <span className="muted">
                  {s.correct} / {s.total} doğru
                </span>
                <span className="ui-badge exam-subject__rating" style={{ color: rating.color }}>
                  {rating.label}
                </span>
              </div>
            );
          })}
        </div>

        <div className="exam-actions">
          <button className="ui-btn ui-btn--primary ui-btn--md" onClick={start}>
            <Icon name="timer" size={18} /> Yeni deneme
          </button>
          <a className="ui-btn ui-btn--ghost ui-btn--md" href="/calis">
            <Icon name="brain" size={18} /> Yanlışlara çalış (SRS)
          </a>
          <a className="ui-btn ui-btn--ghost ui-btn--md" href="/ilerleme">
            <Icon name="trending" size={18} /> Sınav geçmişim
          </a>
        </div>
      </div>
    );

    const aside = (
      <>
        <QuizPanel title="Genel İstatistikler" icon="trending">
          <DonutStat
            pct={okPct}
            center={`%${okPct}`}
            sub="Başarı Oranı"
            rows={[
              { color: 'var(--accent-green)', label: 'Doğru', value: result.correct },
              { color: 'var(--accent-red)', label: 'Yanlış', value: wrong },
              { color: 'var(--text-3)', label: 'Boş', value: empty },
            ]}
          />
        </QuizPanel>
        <QuizPanel title="Sınav Bilgileri" icon="clipboard">
          <InfoRow icon="clipboard" label="Sınav Türü" value="Genel Deneme" />
          <InfoRow icon="layers" label="Soru Sayısı" value={result.total} />
          <InfoRow icon="timer" label="Süre" value={fmt(usedSec)} />
          <InfoRow icon="check-circle" label="Baraj" value={`${exam.passCorrect} doğru`} />
        </QuizPanel>
        {tipsPanel}
      </>
    );
    return <QuizLayout main={main} aside={aside} />;
  }

  /* ── Sınav anı (ref 016) ── */
  const q = exam.questions[i]!;
  const progressPct = Math.round((answeredCount / exam.questions.length) * 100);

  const main = (
    <div data-testid="exam-running">
      <div className="ui-card exam-timerbar">
        <div className="exam-timerbar__time">
          <Icon name="timer" size={20} />
          <div>
            <strong data-testid="exam-timer" aria-live="off">
              {fmt(left)}
            </strong>
            <span className="muted exam-timerbar__cap">Kalan Süre</span>
          </div>
        </div>
        <div className="exam-timerbar__mid">
          <span className="exam-timerbar__count">
            Soru{' '}
            <strong>
              {i + 1}/{exam.questions.length}
            </strong>
          </span>
          <div className="ui-progress">
            <span className="ui-progress__fill" style={{ width: `${progressPct}%` }} />
          </div>
          <span className="muted exam-timerbar__pct">%{progressPct} cevaplandı</span>
        </div>
        <div className="exam-timerbar__right">
          <span className="muted exam-timerbar__cap">Cevaplanan</span>
          <strong>
            {answeredCount} / {exam.questions.length}
          </strong>
        </div>
        {!exam.fullBlueprint && <span className="ui-badge">kısaltılmış deneme</span>}
        <button
          className="ui-btn ui-btn--soft exam-finish"
          onClick={finish}
          data-testid="exam-finish"
        >
          Sınavı bitir
        </button>
      </div>

      <div className="ui-card quiz-card" style={{ marginTop: 'var(--sp-4)' }}>
        <p
          className="muted"
          style={{ margin: '0 0 6px', color: 'var(--primary)', fontWeight: 700 }}
        >
          {SUBJECT_LABEL[q.subject]}
        </p>
        <h2 style={{ fontSize: '1.2rem', margin: '0 0 16px' }}>{q.stem}</h2>
        <div role="group" aria-label="Seçenekler">
          {q.options.map((opt, idx) => (
            <button
              key={idx}
              className={`opt${answers[i] === idx ? ' opt--picked' : ''}`}
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

        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 14 }}>
          <button
            className="ui-btn ui-btn--ghost ui-btn--md"
            onClick={() => setI(Math.max(0, i - 1))}
            disabled={i === 0}
          >
            ← Önceki
          </button>
          <button
            className="ui-btn ui-btn--primary ui-btn--md"
            style={{ marginLeft: 'auto' }}
            onClick={() => setI(Math.min(exam.questions.length - 1, i + 1))}
            disabled={i === exam.questions.length - 1}
            data-testid="e-next"
          >
            Sonraki →
          </button>
        </div>
      </div>

      <div
        className="ui-card quiz-panel"
        style={{ marginTop: 'var(--sp-4)' }}
        aria-label="Soru haritası"
      >
        <div className="qnav__grid">
          {exam.questions.map((_, k) => (
            <button
              key={k}
              onClick={() => setI(k)}
              className={`qnav__dot qnav__dot--btn ${
                k === i ? 'qnav__dot--current' : answers[k] !== null ? 'qnav__dot--correct' : ''
              }`}
              aria-label={`Soru ${k + 1}${answers[k] !== null ? ' (cevaplandı)' : ''}`}
            >
              {k + 1}
            </button>
          ))}
        </div>
        <div className="qnav__legend" aria-hidden>
          <span className="qnav__leg">
            <span className="qnav__mini qnav__dot--correct" /> Cevaplandı
          </span>
          <span className="qnav__leg">
            <span className="qnav__mini qnav__dot--current" /> Mevcut
          </span>
          <span className="qnav__leg">
            <span className="qnav__mini" /> Boş
          </span>
        </div>
      </div>
    </div>
  );

  const aside = (
    <>
      <QuizPanel title="Sınav Bilgileri" icon="clipboard">
        <InfoRow icon="clipboard" label="Soru Sayısı" value={exam.questions.length} />
        <InfoRow icon="timer" label="Süre" value={fmt(exam.durationSeconds)} />
        <InfoRow icon="check-circle" label="Baraj" value={`${exam.passCorrect} doğru`} />
      </QuizPanel>
      {distPanel}
      {tipsPanel}
    </>
  );

  return <QuizLayout main={main} aside={aside} />;
}
