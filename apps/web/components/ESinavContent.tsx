'use client';

/**
 * Teorik e-Sınav merkezi (Program 3.1 — referans 010):
 * ders kartları (gerçek ustalık ilerlemesi) · CTA satırı · "kendini test et" bandı ·
 * özellik şeridi · MEB notu; sağ ray: sınav istatistikleri, deneme sayısı, önerilen
 * çalışma, sınav hakkı. Tüm veriler kullanıcının kendi geçmişinden (dürüst).
 */
import { useEffect, useState } from 'react';
import { EXAM_BLUEPRINT, SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { statsFromAnswers } from '@ea/srs-engine';
import { loadAnswers, loadCounters } from '@/lib/progress';
import { loadEntitlements, canStartFreeExam } from '@/lib/payments';
import { hasCapability } from '@/lib/products';
import { weakTopics } from '@/lib/study';
import { Icon, type IconName } from '@/components/ui/icons';
import { QuizLayout, QuizPanel, DonutStat, InfoRow } from '@/components/ui/quiz';
import { Callout } from '@/components/ui/patterns';
import type { Accent } from '@/components/ui/primitives';

const SUBJECT_META: Record<string, { icon: IconName; accent: Accent }> = {
  trafik: { icon: 'trafficlight', accent: 'teal' },
  ilkyardim: { icon: 'firstaid', accent: 'amber' },
  motor: { icon: 'car', accent: 'purple' },
  adab: { icon: 'road', accent: 'blue' },
};

const FEATURES: Array<{ icon: IconName; accent: Accent; title: string; desc: string }> = [
  {
    icon: 'target',
    accent: 'red',
    title: 'Gerçek sınav formatı',
    desc: `${EXAM_BLUEPRINT.totalQuestions} soru · ${EXAM_BLUEPRINT.durationMinutes} dakika`,
  },
  { icon: 'check-circle', accent: 'green', title: 'Güncel içerik', desc: 'MEB müfredatına uygun' },
  { icon: 'trending', accent: 'blue', title: 'Anında sonuç', desc: 'Doğru, yanlış ve net' },
  { icon: 'gauge', accent: 'amber', title: 'Eksiklerini gör', desc: 'Konu konu analiz' },
];

export function ESinavContent({ counts }: { counts: Record<string, number> }) {
  const [mastery, setMastery] = useState<Record<string, number>>({});
  const [answered, setAnswered] = useState(0);
  const [correct, setCorrect] = useState(0);
  const [exams, setExams] = useState(0);
  const [weakest, setWeakest] = useState<string | null>(null);
  const [unlimited, setUnlimited] = useState(false);
  const [freeLeft, setFreeLeft] = useState(true);

  useEffect(() => {
    const answers = loadAnswers();
    const { subjects } = statsFromAnswers(answers);
    const m: Record<string, number> = {};
    for (const s of subjects) m[s.subject] = Math.round(s.mastery * 100);
    setMastery(m);
    setAnswered(answers.length);
    setCorrect(answers.filter((a) => a.correct).length);
    setExams(loadCounters().examsFinished);
    const weak = weakTopics(answers, { limit: 1 });
    setWeakest(weak.length && weak[0] ? SUBJECT_LABEL[weak[0].subject] : null);
    setUnlimited(hasCapability(loadEntitlements(), 'sinirsiz-deneme'));
    setFreeLeft(canStartFreeExam());
  }, []);

  const okPct = answered ? Math.round((correct / answered) * 100) : 0;

  const main = (
    <>
      <div className="grid-auto" style={{ ['--grid-min' as string]: '215px' }}>
        {THEORY_SUBJECTS.map((s) => {
          const meta = SUBJECT_META[s] ?? { icon: 'book' as IconName, accent: 'teal' as Accent };
          const pct = mastery[s] ?? 0;
          return (
            <div className="ui-card esx-subject" key={s}>
              <span
                className="ui-iconbadge ui-iconbadge--md"
                style={{ ['--ib-accent' as string]: `var(--accent-${meta.accent})` }}
                aria-hidden
              >
                <Icon name={meta.icon} size={22} />
              </span>
              <span className="ui-badge esx-subject__count">
                {EXAM_BLUEPRINT.distribution[s]} soru
              </span>
              <h3 className="esx-subject__title">{SUBJECT_LABEL[s]}</h3>
              <p className="muted esx-subject__meta">Bankada {counts[s] ?? 0} özgün soru hazır.</p>
              <div className="esx-subject__prog">
                <span className="muted">%{pct} ustalık</span>
                <div className="ui-progress">
                  <span className="ui-progress__fill" style={{ width: `${pct}%` }} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="esx-cta">
        <a className="ui-btn ui-btn--primary ui-btn--md" href="/tani">
          Tanı denemesiyle başla →
        </a>
        <a className="ui-btn ui-btn--ghost ui-btn--md" href="/deneme-sinavi">
          Deneme sınavlarına git ↗
        </a>
      </div>

      <div className="ui-card ui-card--accent hero-banner esx-banner">
        <span className="banner-art" aria-hidden>
          {/* 3D pano+kronometre illüstrasyonu (ref 010-B) */}
          <img src="/assets/art/checklist-timer.webp" alt="" />
        </span>
        <div className="hero-banner__body">
          <div className="hero-banner__title">Deneme sınavı ile kendini test et</div>
          <div className="hero-banner__text">
            Gerçek sınavda karşına çıkabilecek {EXAM_BLUEPRINT.totalQuestions} soru ile kendini
            dene. Süreli ve puanlı denemelerle eksiklerini belirle.
          </div>
          <div className="esx-banner__actions">
            <a className="ui-btn ui-btn--primary ui-btn--sm" href="/deneme-sinavi">
              Deneme sınavı başlat →
            </a>
            <a className="ui-btn ui-btn--ghost ui-btn--sm" href="/ilerleme">
              <Icon name="trending" size={16} /> Geçmiş sonuçlarım
            </a>
          </div>
        </div>
      </div>

      <div className="ui-card esx-strip">
        {FEATURES.map((f) => (
          <div className="esx-strip__item" key={f.title}>
            <span
              className="fact-tile__icon"
              style={{ ['--fact-accent' as string]: `var(--accent-${f.accent})` }}
              aria-hidden
            >
              <Icon name={f.icon} size={18} />
            </span>
            <span>
              <strong className="esx-strip__title">{f.title}</strong>
              <span className="esx-strip__desc muted">{f.desc}</span>
            </span>
          </div>
        ))}
      </div>

      <Callout tone="info" title="Sorular MEB tarafından belirlenen müfredata uygundur.">
        Her sınavda sorular karışık gelir. Ezberden değil, anlamaya dayalı öğrenmenizi destekler. Bu
        bir <em>resmî MEB sınavı değildir</em>; gerçek sınav formatında denemedir.
      </Callout>
    </>
  );

  const aside = (
    <>
      <QuizPanel title="Sınav İstatistiklerin" icon="trending">
        <DonutStat
          pct={okPct}
          center={`%${okPct}`}
          sub="Doğru Oranı"
          rows={[
            { color: 'var(--accent-green)', label: 'Doğru', value: correct },
            { color: 'var(--accent-red)', label: 'Yanlış', value: answered - correct },
            { color: 'var(--text-3)', label: 'Toplam soru', value: answered },
          ]}
        />
      </QuizPanel>
      <QuizPanel title="Deneme Geçmişin" icon="clipboard">
        {exams > 0 ? (
          <>
            <InfoRow icon="timer" label="Tamamlanan deneme" value={exams} />
            <a
              className="ui-btn ui-btn--ghost ui-btn--sm"
              href="/ilerleme"
              style={{ marginTop: 8 }}
            >
              Sonuç detayını görüntüle →
            </a>
          </>
        ) : (
          <p className="muted" style={{ margin: 0, fontSize: 'var(--fs-sm)' }}>
            Henüz deneme çözmedin — ilk denemenle buradan takip edebilirsin.
          </p>
        )}
      </QuizPanel>
      <QuizPanel title="Önerilen Çalışma" icon="trending">
        <p className="muted" style={{ margin: '0 0 10px', fontSize: 'var(--fs-sm)' }}>
          {weakest ? (
            <>
              <strong style={{ color: 'var(--text)' }}>{weakest}</strong> konusuna daha fazla
              çalışmalısın.
            </>
          ) : (
            'Önce bir tanı denemesi çöz — sana özel öneri çıkaralım.'
          )}
        </p>
        <a className="ui-btn ui-btn--primary ui-btn--sm" href={weakest ? '/calis' : '/tani'}>
          Çalışmaya başla →
        </a>
      </QuizPanel>
      <QuizPanel title="Sınav Hakkın" icon="check-circle">
        <InfoRow
          icon="timer"
          label={unlimited ? 'Sınırsız' : 'Ücretsiz kademe'}
          value={unlimited ? '∞' : freeLeft ? 'Bugün 1 hak' : 'Bugünlük doldu'}
        />
        <p className="muted" style={{ margin: '6px 0 0', fontSize: 'var(--fs-xs)' }}>
          {unlimited
            ? 'Dilediğin kadar sınava girebilirsin.'
            : 'Paketle sınırsız denemeye geçebilirsin.'}
        </p>
      </QuizPanel>
    </>
  );

  return <QuizLayout main={main} aside={aside} />;
}
