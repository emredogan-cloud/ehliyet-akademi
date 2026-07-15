import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { BADGE_LABEL, SUBJECT_LABEL, type Question } from '@ea/content-schema';
import { questionById } from '@ea/question-bank';
import { LESSONS, lessonBySlug } from '@/content/lessons';
import { LessonFigure } from '@/components/LessonFigure';
import { LessonPractice } from '@/components/LessonPractice';
import { LessonJsonLd } from '@/components/JsonLd';
import { PremiumBadge } from '@/components/PremiumBadge';
import { PremiumLessonGate } from '@/components/PremiumLessonGate';
import { LessonViewTracker } from '@/components/LessonViewTracker';
import { Callout } from '@/components/ui/Callout';
import { CompareTable } from '@/components/ui/CompareTable';
import type { ReactNode } from 'react';

export function generateStaticParams() {
  return LESSONS.map((l) => ({ slug: l.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const lesson = lessonBySlug(slug);
  if (!lesson) return { title: 'Ders bulunamadı' };
  return { title: lesson.title, description: lesson.summary };
}

/** İki kolonlu bilgi kutusu. */
function InfoCard({ title, color, items }: { title: string; color: string; items: string[] }) {
  if (items.length === 0) return null;
  return (
    <div
      className="card"
      style={{ marginTop: 14, background: `color-mix(in srgb, ${color} 8%, var(--surface))` }}
    >
      <strong style={{ color }}>{title}</strong>
      <ul className="prose" style={{ margin: '8px 0 0' }}>
        {items.map((t, k) => (
          <li key={k}>{t}</li>
        ))}
      </ul>
    </div>
  );
}

export default async function LessonPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const lesson = lessonBySlug(slug);
  if (!lesson) notFound();

  const practice: Question[] = lesson.practiceQuestionIds
    .map((id) => questionById(id))
    .filter((q): q is Question => Boolean(q));

  return (
    <article style={{ maxWidth: 760, margin: '0 auto' }}>
      <LessonJsonLd lesson={lesson} />
      <LessonViewTracker slug={lesson.slug} premium={lesson.premium} />
      <p className="muted" style={{ marginBottom: 4 }}>
        {SUBJECT_LABEL[lesson.subject]} · {lesson.minutes} dk okuma
      </p>
      <h1
        style={{
          margin: '0 0 10px',
          display: 'flex',
          gap: 10,
          alignItems: 'center',
          flexWrap: 'wrap',
        }}
      >
        {lesson.title}
        {lesson.premium && <PremiumBadge />}
      </h1>
      <p
        style={{
          fontSize: '1.1rem',
          color: 'var(--text-2)',
          borderLeft: '3px solid var(--primary)',
          paddingLeft: 16,
        }}
      >
        {lesson.summary}
      </p>

      <div
        className="card"
        style={{ background: 'var(--primary-050)', borderColor: 'var(--primary-100)' }}
      >
        <strong>Kazanımlar</strong>
        <ul className="prose" style={{ margin: '8px 0 0' }}>
          {lesson.objectives.map((o, k) => (
            <li key={k}>{o}</li>
          ))}
        </ul>
      </div>

      <LessonFigure figureId={lesson.figureId} lessonId={lesson.id} />

      {(() => {
        const deep: ReactNode = (
          <>
            {lesson.sections.map((sec, k) => (
              <section key={k} style={{ margin: '26px 0' }}>
                <h2
                  style={{
                    fontSize: '1.2rem',
                    display: 'flex',
                    gap: 10,
                    alignItems: 'center',
                    flexWrap: 'wrap',
                  }}
                >
                  {sec.heading}
                  {sec.badge && <span className="badge">{BADGE_LABEL[sec.badge]}</span>}
                </h2>
                <p className="prose" dangerouslySetInnerHTML={{ __html: mdBold(sec.body) }} />
                {sec.compare && <CompareTable {...sec.compare} />}
                {sec.callout && <Callout {...sec.callout} />}
              </section>
            ))}

            {lesson.keyTakeaways.length > 0 && (
              <div className="card" style={{ borderColor: 'var(--primary-100)' }}>
                <strong>🧭 Özet — aklında kalsın</strong>
                <ul className="prose" style={{ margin: '8px 0 0' }}>
                  {lesson.keyTakeaways.map((t, k) => (
                    <li key={k}>{t}</li>
                  ))}
                </ul>
              </div>
            )}

            {lesson.mistakes.length > 0 && (
              <div
                className="card"
                style={{
                  marginTop: 14,
                  background: 'color-mix(in srgb, var(--red) 8%, var(--surface))',
                }}
              >
                <strong style={{ color: 'var(--red)' }}>Sık Yapılan Hatalar</strong>
                <ul className="prose" style={{ margin: '8px 0 0' }}>
                  {lesson.mistakes.map((m, k) => (
                    <li key={k}>
                      <strong>{m.text}</strong>{' '}
                      <span dangerouslySetInnerHTML={{ __html: 'Çözüm: ' + mdBold(m.fix) }} />
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <InfoCard title="🧠 Hafıza Teknikleri" color="var(--blue)" items={lesson.memoryTips} />
            <InfoCard
              title="🎯 Sınav Stratejisi"
              color="var(--primary)"
              items={lesson.examStrategy}
            />
            <InfoCard title="💡 Sınav İpuçları" color="var(--green)" items={lesson.tips} />

            <LessonPractice
              reviewCards={lesson.reviewCards}
              practice={practice}
              lessonTitle={lesson.title}
            />
          </>
        );
        return lesson.premium ? (
          <PremiumLessonGate slug={lesson.slug}>{deep}</PremiumLessonGate>
        ) : (
          deep
        );
      })()}

      <div style={{ marginTop: 26, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <a className="btn" href="/calis">
          Akıllı çalışmayla pekiştir
        </a>
        {lesson.subject === 'trafik' && (
          <a className="btn btn--ghost" href="/isaretler">
            🚸 İşaret galerisi
          </a>
        )}
        {(lesson.subject === 'motor' || lesson.subject === 'pratik') && (
          <a className="btn btn--ghost" href="/arac">
            🚙 Araç tanıma
          </a>
        )}
        <a className="btn btn--ghost" href="/dersler">
          Tüm dersler
        </a>
      </div>

      {lesson.references.length > 0 && (
        <p className="muted" style={{ marginTop: 24, fontSize: '0.82rem' }}>
          Kaynaklar: {lesson.references.join(' · ')}
        </p>
      )}
    </article>
  );
}

/** Basit **kalın** işaretlemesini <strong>'a çevirir (içerik markdown-hafif). */
function mdBold(s: string): string {
  const escaped = s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return escaped.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
}
