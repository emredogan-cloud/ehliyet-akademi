import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { signById, CATEGORY_LABEL } from '@/content/signs';
import { allSignIds, confusionsFor, questionsForSign } from '@/content/sign-extras';
import { TrafficSign } from '@/components/signs/TrafficSign';
import { Breadcrumb } from '@/components/ui/patterns';
import { SignJsonLd, FaqJsonLd } from '@/components/JsonLd';
import { buildMetadata } from '@/lib/seo/metadata';

export function generateStaticParams() {
  return allSignIds().map((id) => ({ id }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const sign = signById(id);
  if (!sign) return { title: 'İşaret bulunamadı', robots: { index: false, follow: false } };
  return buildMetadata({
    title: `${sign.name} — Trafik İşareti Anlamı`,
    description: `${sign.meaning} ${sign.name} levhası ne anlama gelir, nerede kullanılır ve sınavda nasıl sorulur — Ehliyet Akademi.`,
    path: `/isaretler/${sign.id}`,
    type: 'article',
    keywords: [sign.name, 'trafik işareti', 'trafik levhası', ...(sign.keywords ?? [])],
  });
}

export default async function SignDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const sign = signById(id);
  if (!sign) notFound();

  const confusions = confusionsFor(sign.id);
  const questions = questionsForSign(sign);
  const breadcrumb = [
    { name: 'Ana Sayfa', path: '/' },
    { name: 'Trafik İşaretleri', path: '/isaretler' },
    { name: CATEGORY_LABEL[sign.category] },
    { name: sign.name, path: `/isaretler/${sign.id}` },
  ];

  return (
    <article style={{ maxWidth: 720, margin: '0 auto' }} data-testid="sign-detail">
      <SignJsonLd
        sign={{
          id: sign.id,
          name: sign.name,
          meaning: sign.meaning,
          categoryLabel: CATEGORY_LABEL[sign.category],
          keywords: sign.keywords,
        }}
        breadcrumb={breadcrumb}
      />
      {questions.length > 0 && (
        <FaqJsonLd items={questions.map((q) => ({ question: q.stem, answer: q.explanation }))} />
      )}
      <Breadcrumb
        items={[
          { label: 'Trafik İşaretleri', href: '/isaretler' },
          { label: CATEGORY_LABEL[sign.category] },
          { label: sign.name },
        ]}
      />
      <h1 className="page-head__title" style={{ margin: '2px 0 16px', fontSize: 'var(--fs-2xl)' }}>
        {sign.name}
      </h1>

      <div
        className="card"
        style={{ display: 'flex', gap: 20, alignItems: 'center', flexWrap: 'wrap' }}
      >
        <TrafficSign
          shape={sign.shape}
          glyph={sign.glyph}
          glyphText={sign.glyphText}
          label={sign.name}
          size={140}
        />
        <div style={{ flex: 1, minWidth: 240 }}>
          <p style={{ margin: 0, fontSize: '1.05rem' }}>{sign.meaning}</p>
          <p className="muted" style={{ margin: '10px 0 0', fontSize: '0.9rem' }}>
            Sınav önemi: <strong>{sign.examImportance}</strong>
          </p>
        </div>
      </div>

      <div className="callout" style={{ ['--callout-c' as string]: 'var(--blue)' }} role="note">
        <span className="callout__icon" aria-hidden>
          🧠
        </span>
        <div>
          <strong className="callout__title">Hafıza tekniği</strong>
          <p className="callout__text">{sign.memoryTip}</p>
        </div>
      </div>

      {sign.commonMistake && (
        <div className="callout" style={{ ['--callout-c' as string]: 'var(--red)' }} role="note">
          <span className="callout__icon" aria-hidden>
            ⚠️
          </span>
          <div>
            <strong className="callout__title">Sık yapılan hata</strong>
            <p className="callout__text">{sign.commonMistake}</p>
          </div>
        </div>
      )}

      {confusions.length > 0 && (
        <section style={{ marginTop: 22 }} data-testid="sign-confusions">
          <h2 className="section-title" style={{ marginTop: 0 }}>
            Karıştırma! Farkı gör
          </h2>
          {confusions.map(({ other, difference }) => (
            <div
              key={other.id}
              className="card"
              style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}
            >
              <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                <TrafficSign
                  shape={sign.shape}
                  glyph={sign.glyph}
                  glyphText={sign.glyphText}
                  label={sign.name}
                  size={72}
                />
                <span className="muted" aria-hidden>
                  vs
                </span>
                <a href={`/isaretler/${other.id}`} title={other.name}>
                  <TrafficSign
                    shape={other.shape}
                    glyph={other.glyph}
                    glyphText={other.glyphText}
                    label={other.name}
                    size={72}
                  />
                </a>
              </div>
              <p style={{ flex: 1, minWidth: 220, margin: 0, fontSize: '0.92rem' }}>{difference}</p>
            </div>
          ))}
        </section>
      )}

      {questions.length > 0 && (
        <section style={{ marginTop: 22 }} data-testid="sign-questions">
          <h2 className="section-title" style={{ marginTop: 0 }}>
            Bankadan ilgili sorular
          </h2>
          {questions.map((q) => (
            <details key={q.id} className="card" style={{ marginTop: 10 }}>
              <summary style={{ cursor: 'pointer', fontWeight: 600 }}>{q.stem}</summary>
              <ol type="A" className="prose" style={{ margin: '10px 0 0' }}>
                {q.options.map((o, i) => (
                  <li
                    key={i}
                    style={
                      i === q.answerIndex ? { color: 'var(--green)', fontWeight: 700 } : undefined
                    }
                  >
                    {o}
                  </li>
                ))}
              </ol>
              <p className="muted" style={{ margin: '8px 0 0', fontSize: '0.88rem' }}>
                {q.explanation}
              </p>
            </details>
          ))}
        </section>
      )}

      <div style={{ marginTop: 26, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <a className="btn" href="/gorsel-quiz">
          📸 Görsel quizde dene
        </a>
        {sign.relatedLessonSlug && (
          <a className="btn btn--ghost" href={`/dersler/${sign.relatedLessonSlug}`}>
            İlgili ders →
          </a>
        )}
        <a className="btn btn--ghost" href="/isaretler">
          ← Galeriye dön
        </a>
      </div>
    </article>
  );
}
