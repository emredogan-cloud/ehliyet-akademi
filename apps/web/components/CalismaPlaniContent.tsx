'use client';

/**
 * Kişisel Çalışma Planı (Sprint 3 · Program 3.1 görsel dili — referans 023/024):
 * "Bugünün odağı" bandı · adım kartları · gelişime açık konular; sağ ray: ders
 * ustalığı radarı + yaklaşan görevler. Salt sunum — plan mantığına dokunmaz;
 * kullanıcının cevap geçmişi + SRS kartlarından üretilen veriler aynen kullanılır.
 */
import { useEffect, useState, type CSSProperties } from 'react';
import { SUBJECT_LABEL, THEORY_SUBJECTS } from '@ea/content-schema';
import { statsFromAnswers } from '@ea/srs-engine';
import { loadAnswers, loadCards } from '@/lib/progress';
import { MasteryRadar, type RadarDatum } from '@/components/MasteryRadar';
import { PageHeader, Section, Grid } from '@/components/ui/layout';
import { Card, Button, IconBadge, ProgressBar, type Accent } from '@/components/ui/primitives';
import { QuizLayout, QuizPanel } from '@/components/ui/quiz';
import { Tag, HeroBanner } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';
import {
  buildStudyPlan,
  weakTopics,
  stepKindLabel,
  type StudyPlan,
  type StepKind,
  type WeakTopic,
} from '@/lib/study';

/** Adım türü → ikon + aksan (eski pill renk dili korunur: ders mavi, alıştırma teal, tekrar amber). */
const KIND_META: Record<StepKind, { icon: IconName; accent: Accent }> = {
  lesson: { icon: 'book', accent: 'blue' },
  practice: { icon: 'car', accent: 'teal' },
  review: { icon: 'brain', accent: 'amber' },
  exam: { icon: 'clipboard', accent: 'purple' },
};

/** Ders → ikon + aksan (panel/e-sınav ile aynı eşleme). */
const SUBJECT_META: Record<string, { icon: IconName; accent: Accent }> = {
  trafik: { icon: 'trafficlight', accent: 'teal' },
  ilkyardim: { icon: 'firstaid', accent: 'red' },
  motor: { icon: 'car', accent: 'purple' },
  adab: { icon: 'road', accent: 'blue' },
};

export function CalismaPlaniContent() {
  const [plan, setPlan] = useState<StudyPlan | null>(null);
  const [weak, setWeak] = useState<WeakTopic[]>([]);
  const [radar, setRadar] = useState<RadarDatum[]>([]);

  useEffect(() => {
    const answers = loadAnswers();
    const cards = loadCards();
    const now = Date.now();
    setPlan(buildStudyPlan(answers, cards, now));
    setWeak(weakTopics(answers, { minAnswered: 2, limit: 6 }));
    const { subjects } = statsFromAnswers(answers);
    const byS = new Map(subjects.map((s) => [s.subject, s.mastery]));
    setRadar(THEORY_SUBJECTS.map((subject) => ({ subject, mastery: byS.get(subject) ?? 0 })));
  }, []);

  if (!plan) {
    return (
      <>
        <PageHeader
          title="Çalışma Planım"
          emoji="📋"
          subtitle="Cevaplarına ve tekrar kartlarına göre uyarlanan sıralı plan — sen çalıştıkça güncellenir."
        />
        <Grid preset="cards" aria-busy="true" aria-label="Yükleniyor">
          {[1, 2, 3].map((k) => (
            <Card key={k}>
              <div className="skeleton" style={{ width: '60%', height: 20 }} />
              <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 10 }} />
            </Card>
          ))}
        </Grid>
      </>
    );
  }

  const main = (
    <>
      <HeroBanner
        accent="teal"
        title="Bugünün odağı"
        text={
          <>
            <p style={{ margin: 0 }}>{plan.summary}</p>
            {plan.dueCount > 0 && (
              <p
                style={{
                  margin: 'var(--sp-2) 0 0',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-2)',
                }}
              >
                <span aria-hidden style={{ color: 'var(--accent-amber)', display: 'inline-flex' }}>
                  <Icon name="flame" size={15} />
                </span>
                {plan.dueCount} kartın tekrar zamanı geldi.
              </p>
            )}
          </>
        }
        art={
          /* 3D görsel varlığı beklemede — yer tutucu ikon rozetleri. */
          <span style={{ display: 'flex', gap: 'var(--sp-2)' }}>
            <IconBadge accent="teal" size="lg">
              <Icon name="calendar" size={26} />
            </IconBadge>
            <IconBadge accent="green" size="lg">
              <Icon name="target" size={26} />
            </IconBadge>
          </span>
        }
      />

      <Section title="Adımlar">
        <ol
          className="plan-steps"
          data-testid="plan-steps"
          style={{ margin: 0, gap: 'var(--sp-3)' }}
        >
          {plan.steps.map((s, i) => {
            const meta = KIND_META[s.kind];
            return (
              <Card
                as="li"
                key={i}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-4)',
                  flexWrap: 'wrap',
                }}
              >
                <IconBadge accent={meta.accent} size="md">
                  <Icon name={meta.icon} size={20} />
                </IconBadge>
                <div style={{ flex: 1, minWidth: 220 }}>
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 'var(--sp-2)',
                      flexWrap: 'wrap',
                    }}
                  >
                    <Tag accent={meta.accent}>{stepKindLabel(s.kind)}</Tag>
                    <strong>{s.title}</strong>
                  </div>
                  <p className="muted" style={{ margin: '4px 0 0', fontSize: 'var(--fs-sm)' }}>
                    {s.detail}
                  </p>
                </div>
                <Button variant="primary" size="sm" href={s.href} aria-label={`${s.title} — başla`}>
                  Başla
                </Button>
              </Card>
            );
          })}
        </ol>
      </Section>

      {weak.length > 0 && (
        <Section title="En çok gelişime açık konular">
          <Grid min="220px">
            {weak.map((w) => {
              const meta = SUBJECT_META[w.subject] ?? {
                icon: 'book' as IconName,
                accent: 'teal' as Accent,
              };
              const pct = Math.round(w.mastery * 100);
              return (
                <Card key={w.topic}>
                  <Tag accent={meta.accent}>{SUBJECT_LABEL[w.subject]}</Tag>
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 'var(--sp-3)',
                      margin: 'var(--sp-3) 0 var(--sp-2)',
                    }}
                  >
                    <IconBadge accent={meta.accent} size="md">
                      <Icon name={meta.icon} size={20} />
                    </IconBadge>
                    <h3
                      style={{ margin: 0, fontSize: 'var(--fs-md)', textTransform: 'capitalize' }}
                    >
                      {w.topic}
                    </h3>
                  </div>
                  <p
                    className="muted"
                    style={{ margin: '0 0 var(--sp-2)', fontSize: 'var(--fs-sm)' }}
                  >
                    Ustalık %{pct} · {w.answered} deneme
                  </p>
                  <ProgressBar value={pct} label={`${w.topic} ustalık`} />
                  {w.lessonSlug && (
                    <a
                      className="ui-btn ui-btn--ghost ui-btn--sm"
                      href={`/dersler/${w.lessonSlug}`}
                      style={{ marginTop: 'var(--sp-3)' }}
                    >
                      {w.lessonTitle}
                      <Icon name="chevron-right" size={14} />
                    </a>
                  )}
                </Card>
              );
            })}
          </Grid>
        </Section>
      )}

      <div
        style={{
          marginTop: 'var(--sp-5)',
          display: 'flex',
          gap: 'var(--sp-3)',
          flexWrap: 'wrap',
        }}
      >
        <Button variant="primary" href="/calis">
          Akıllı çalışmaya başla
          <Icon name="chevron-right" size={16} />
        </Button>
        <Button variant="ghost" href="/ai-koc">
          <Icon name="bot" size={16} />
          AI Koç&apos;a sor
        </Button>
      </div>
      <p className="muted" style={{ marginTop: 'var(--sp-4)', fontSize: 'var(--fs-xs)' }}>
        Bu plan senin çalışma verinden üretilir; resmî kural için MEB/MTSK kaynakları esastır.
      </p>
    </>
  );

  const aside = (
    <>
      <QuizPanel
        title="Ders ustalığı"
        icon="layers"
        action={
          <a className="section__link" href="/ilerleme">
            Detayları gör ›
          </a>
        }
      >
        <MasteryRadar data={radar} />
        <div
          aria-hidden
          style={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            gap: 'var(--sp-2)',
            marginTop: 'var(--sp-2)',
            fontSize: 'var(--fs-xs)',
            color: 'var(--text-2)',
          }}
        >
          <span
            style={{
              width: 8,
              height: 8,
              borderRadius: '50%',
              background: 'var(--primary)',
              display: 'inline-block',
            }}
          />
          Senin ustalığın
        </div>
      </QuizPanel>

      <QuizPanel title="Yaklaşan görevler" icon="calendar">
        {plan.steps.slice(0, 3).map((s, i) => {
          const meta = KIND_META[s.kind];
          return (
            <a
              key={i}
              href={s.href}
              style={
                {
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--sp-3)',
                  padding: 'var(--sp-2) 0',
                  color: 'inherit',
                  textDecoration: 'none',
                  borderTop: i > 0 ? '1px solid var(--border)' : undefined,
                } as CSSProperties
              }
            >
              <IconBadge accent={meta.accent} size="sm">
                <Icon name={meta.icon} size={16} />
              </IconBadge>
              <span style={{ flex: 1, minWidth: 0, fontSize: 'var(--fs-sm)', fontWeight: 600 }}>
                {s.title}
              </span>
              <span aria-hidden style={{ color: 'var(--text-3)', display: 'inline-flex' }}>
                <Icon name="chevron-right" size={16} />
              </span>
            </a>
          );
        })}
      </QuizPanel>
    </>
  );

  return (
    <>
      <PageHeader
        title="Çalışma Planım"
        emoji="📋"
        subtitle="Cevaplarına ve tekrar kartlarına göre uyarlanan sıralı plan — sen çalıştıkça güncellenir."
      />
      <div data-testid="study-plan">
        <QuizLayout main={main} aside={aside} />
      </div>
    </>
  );
}
