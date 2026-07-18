import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { BADGE_LABEL, SUBJECT_LABEL, type Question } from '@ea/content-schema';
import { questionById } from '@ea/question-bank';
import { LESSONS, lessonBySlug } from '@/content/lessons';
import { LessonFigure } from '@/components/LessonFigure';
import { LessonPractice } from '@/components/LessonPractice';
import { LessonJsonLd } from '@/components/JsonLd';
import { buildMetadata } from '@/lib/seo/metadata';
import { PremiumBadge } from '@/components/PremiumBadge';
import { PremiumLessonGate } from '@/components/PremiumLessonGate';
import { LessonViewTracker } from '@/components/LessonViewTracker';
import { Callout } from '@/components/ui/Callout';
import { CompareTable } from '@/components/ui/CompareTable';
import { LessonPhotos } from '@/components/LessonPhotos';

import { LessonInteractive } from '@/components/media/LessonInteractive';
import { LessonAnimations } from '@/components/anim/LessonAnimations';
import { Breadcrumb, DetailLayout, PrevNext } from '@/components/ui/patterns';
import { QuizPanel, InfoRow } from '@/components/ui/quiz';
import { Icon } from '@/components/ui/icons';
import type { ReactNode } from 'react';

// Yalnız kataloğdaki dersler geçerli; bilinmeyen slug → gerçek 404 (soft-404 önlenir).
export const dynamicParams = false;

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
  if (!lesson) return { title: 'Ders bulunamadı', robots: { index: false, follow: false } };
  return buildMetadata({
    title: lesson.title,
    description: lesson.summary,
    path: `/dersler/${lesson.slug}`,
    type: 'article',
    keywords: [lesson.title, 'ehliyet dersi', SUBJECT_LABEL[lesson.subject], 'B sınıfı ehliyet'],
  });
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

/** Ders-özel kazanım sahneleri (ref 030-A) — üretilmiş görseller, slug ile eşlenir. */
const KAZANIM_ART: Record<string, string> = {
  'sollama-serit': '/assets/art/overtake-scene.webp',
};

export default async function LessonPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const lesson = lessonBySlug(slug);
  if (!lesson) notFound();

  const practice: Question[] = lesson.practiceQuestionIds
    .map((id) => questionById(id))
    .filter((q): q is Question => Boolean(q));

  // Önceki/sonraki ders (ref 030 alt navigasyon) — aynı sıralı katalogdan.
  const sorted = [...LESSONS].sort((a, b) => a.no - b.no);
  const idx = sorted.findIndex((l) => l.slug === lesson.slug);
  const prevLesson = idx > 0 ? sorted[idx - 1] : undefined;
  const nextLesson = idx >= 0 && idx < sorted.length - 1 ? sorted[idx + 1] : undefined;

  return (
    <article style={{ maxWidth: 1120, margin: '0 auto' }}>
      <LessonJsonLd
        lesson={lesson}
        breadcrumb={[
          { name: 'Ana Sayfa', path: '/' },
          { name: 'Dersler', path: '/dersler' },
          { name: SUBJECT_LABEL[lesson.subject] },
          { name: lesson.title, path: `/dersler/${lesson.slug}` },
        ]}
      />
      <LessonViewTracker slug={lesson.slug} premium={lesson.premium} />
      <Breadcrumb
        items={[
          { label: 'Dersler', href: '/dersler' },
          { label: SUBJECT_LABEL[lesson.subject] },
          { label: `${lesson.minutes} dk okuma` },
        ]}
      />
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

      <DetailLayout
        aside={
          <>
            <QuizPanel title="Ders içeriği" icon="layers">
              <ol className="lesson-toc">
                {lesson.sections.map((sec, k) => (
                  <li key={k}>
                    <a href={`#bolum-${k + 1}`}>
                      <span className="lesson-toc__num" aria-hidden>
                        {k + 1}
                      </span>
                      {sec.heading}
                    </a>
                  </li>
                ))}
              </ol>
            </QuizPanel>
            <QuizPanel title="Ders bilgisi" icon="clipboard">
              <InfoRow icon="timer" label="Okuma süresi" value={`${lesson.minutes} dk`} />
              <InfoRow
                icon="clipboard"
                label="Soru"
                value={lesson.quizQuestionIds.length + lesson.practiceQuestionIds.length}
              />
              <InfoRow icon="brain" label="Tekrar kartı" value={lesson.reviewCards.length} />
              <InfoRow icon="layers" label="Ders" value={SUBJECT_LABEL[lesson.subject]} />
            </QuizPanel>
            <QuizPanel title="Konu ustası ol" icon="trophy">
              <p className="muted" style={{ margin: 0, fontSize: 'var(--fs-sm)' }}>
                Bölümleri oku, tekrar kartlarını çevir ve pratikleri tamamla — konu ustalığın
                çalışma planına işlenir.
              </p>
            </QuizPanel>
          </>
        }
        main={
          <>
            <div
              className="card kazanim-card"
              style={{ background: 'var(--primary-050)', borderColor: 'var(--primary-100)' }}
            >
              {KAZANIM_ART[lesson.slug] && (
                <img
                  src={KAZANIM_ART[lesson.slug]}
                  alt=""
                  className="kazanim-card__art"
                  aria-hidden
                />
              )}
              <strong>Kazanımlar</strong>
              <ul className="prose" style={{ margin: '8px 0 0' }}>
                {lesson.objectives.map((o, k) => (
                  <li key={k}>{o}</li>
                ))}
              </ul>
            </div>

            <LessonPhotos slug={lesson.slug} />
            <LessonInteractive slug={lesson.slug} />
            <LessonAnimations slug={lesson.slug} />
            <LessonFigure figureId={lesson.figureId} lessonId={lesson.id} />

            {(() => {
              const deep: ReactNode = (
                <>
                  {lesson.sections.map((sec, k) => (
                    <section key={k} id={`bolum-${k + 1}`} style={{ margin: '26px 0' }}>
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

                  <InfoCard
                    title="🧠 Hafıza Teknikleri"
                    color="var(--blue)"
                    items={lesson.memoryTips}
                  />
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
          </>
        }
      />

      <div className="ui-card ui-card--accent hero-banner" style={{ marginTop: 'var(--sp-6)' }}>
        <span className="coach-hero__bot" aria-hidden>
          {/* Üretilmiş maskot (ASSET A4 / 020-A) */}
          <img src="/assets/art/robot-wave.webp" alt="" className="coach-hero__img" />
        </span>
        <div className="hero-banner__body">
          <div className="hero-banner__title">Takıldığın yer mi var?</div>
          <div className="hero-banner__text">
            AI Koç bu ders içeriğinden yanıtlar; ayrıca sana özel çalışma planı çıkarır.
          </div>
        </div>
        <div className="hero-banner__action" style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <a
            className="ui-btn ui-btn--primary ui-btn--sm"
            href={`/ai-koc?soru=${encodeURIComponent(lesson.title + ' konusunu özetler misin?')}`}
          >
            <Icon name="bot" size={16} /> Bu dersi AI Koç&apos;a sor
          </a>
          <a className="ui-btn ui-btn--ghost ui-btn--sm" href="/calisma-plani">
            Çalışma planım
          </a>
        </div>
      </div>

      <PrevNext
        prev={
          prevLesson
            ? { label: prevLesson.title, sub: 'Önceki ders', href: `/dersler/${prevLesson.slug}` }
            : undefined
        }
        next={
          nextLesson
            ? { label: nextLesson.title, sub: 'Sonraki ders', href: `/dersler/${nextLesson.slug}` }
            : undefined
        }
        indexHref="/dersler"
      />

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
