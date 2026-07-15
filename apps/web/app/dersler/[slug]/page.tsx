import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { BADGE_LABEL, SUBJECT_LABEL } from '@ea/content-schema';
import { LESSONS, lessonBySlug } from '../../../content/lessons';
import { LessonFigure } from '../../../components/LessonFigure';

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

export default async function LessonPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const lesson = lessonBySlug(slug);
  if (!lesson) notFound();

  return (
    <article style={{ maxWidth: 760, margin: '0 auto' }}>
      <p className="muted" style={{ marginBottom: 4 }}>
        {SUBJECT_LABEL[lesson.subject]} · {lesson.minutes} dk okuma
      </p>
      <h1 style={{ margin: '0 0 10px' }}>{lesson.title}</h1>
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

      <LessonFigure lessonId={lesson.id} />

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
        </section>
      ))}

      {lesson.mistakes.length > 0 && (
        <div
          className="card"
          style={{ background: 'color-mix(in srgb, var(--red) 8%, var(--surface))' }}
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

      {lesson.tips.length > 0 && (
        <div
          className="card"
          style={{
            marginTop: 14,
            background: 'color-mix(in srgb, var(--green) 8%, var(--surface))',
          }}
        >
          <strong style={{ color: 'var(--green)' }}>Sınav İpuçları</strong>
          <ul className="prose" style={{ margin: '8px 0 0' }}>
            {lesson.tips.map((t, k) => (
              <li key={k}>{t}</li>
            ))}
          </ul>
        </div>
      )}

      <div style={{ marginTop: 26, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <a className="btn" href="/tani">
          Kendini tanı denemesiyle test et
        </a>
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
