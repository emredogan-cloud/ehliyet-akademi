import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { vehiclePartById, partsBySystem, SYSTEM_LABEL } from '@/content/vehicle';
import { allPartIds, questionsForPart } from '@/content/vehicle-extras';
import { AssetImage } from '@/components/ui/AssetImage';
import { VehicleFigure, VEHICLE_PART_IDS } from '@/components/vehicle/VehicleFigure';
import { Breadcrumb } from '@/components/ui/patterns';
import { VehicleJsonLd, FaqJsonLd } from '@/components/JsonLd';
import { buildMetadata } from '@/lib/seo/metadata';

// Yalnız kataloğdaki bileşenler geçerli; bilinmeyen id → gerçek 404 (soft-404 önlenir).
export const dynamicParams = false;

export function generateStaticParams() {
  return allPartIds().map((id) => ({ id }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ id: string }>;
}): Promise<Metadata> {
  const { id } = await params;
  const part = vehiclePartById(id);
  if (!part) return { title: 'Bileşen bulunamadı', robots: { index: false, follow: false } };
  return buildMetadata({
    title: `${part.name} — Araç Tanıma`,
    description: `${part.desc} ${part.name}: ne işe yarar, nasıl kontrol edilir ve direksiyon sınavında neden önemli — Ehliyet Akademi.`,
    path: `/arac/${part.id}`,
    type: 'article',
    keywords: [part.name, 'araç tekniği', 'direksiyon', SYSTEM_LABEL[part.system]],
  });
}

const HAS_DIAGRAM = new Set(VEHICLE_PART_IDS);

export default async function PartDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const part = vehiclePartById(id);
  if (!part) notFound();

  const questions = questionsForPart(part);
  // İlgili bileşenler — aynı sistemdeki kardeşler (crawl derinliği + kullanıcı keşfi).
  const related = (partsBySystem()[part.system] ?? []).filter((p) => p.id !== part.id).slice(0, 4);
  const breadcrumb = [
    { name: 'Ana Sayfa', path: '/' },
    { name: 'Araç Tanıma', path: '/arac' },
    { name: SYSTEM_LABEL[part.system] },
    { name: part.name, path: `/arac/${part.id}` },
  ];

  return (
    <article style={{ maxWidth: 720, margin: '0 auto' }} data-testid="part-detail">
      <VehicleJsonLd
        part={{ id: part.id, name: part.name, desc: part.desc, steps: part.inspection }}
        breadcrumb={breadcrumb}
      />
      {questions.length > 0 && (
        <FaqJsonLd items={questions.map((q) => ({ question: q.stem, answer: q.explanation }))} />
      )}
      <Breadcrumb
        items={[
          { label: 'Araç Tanıma', href: '/arac' },
          { label: SYSTEM_LABEL[part.system] },
          { label: part.name },
        ]}
      />
      <h1 className="page-head__title" style={{ margin: '2px 0 16px', fontSize: 'var(--fs-2xl)' }}>
        {part.name}
      </h1>

      {part.photo && (
        <AssetImage assetId={part.photo} priority sizes="(max-width: 760px) 100vw, 680px" />
      )}

      <p style={{ fontSize: '1.05rem', margin: '14px 0 4px' }}>{part.desc}</p>
      <p style={{ margin: 0, color: 'var(--primary)' }}>💡 {part.tip}</p>

      {part.inspection && part.inspection.length > 0 && (
        <div className="card" style={{ marginTop: 16 }} data-testid="part-inspection">
          <strong>🔎 Kontrol adımları</strong>
          <ol className="prose" style={{ margin: '8px 0 0' }}>
            {part.inspection.map((step, i) => (
              <li key={i}>{step}</li>
            ))}
          </ol>
        </div>
      )}

      {part.mistake && (
        <div className="callout" style={{ ['--callout-c' as string]: 'var(--red)' }} role="note">
          <span className="callout__icon" aria-hidden>
            ⚠️
          </span>
          <div>
            <strong className="callout__title">Sık yapılan hata</strong>
            <p className="callout__text">{part.mistake}</p>
          </div>
        </div>
      )}

      {HAS_DIAGRAM.has(part.id) && (
        <details style={{ marginTop: 14 }}>
          <summary className="muted" style={{ cursor: 'pointer' }}>
            Çizim şeması
          </summary>
          <VehicleFigure part={part.id} label={part.name} />
        </details>
      )}

      {questions.length > 0 && (
        <section style={{ marginTop: 22 }} data-testid="part-questions">
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

      {related.length > 0 && (
        <section style={{ marginTop: 22 }} data-testid="part-related">
          <h2 className="section-title" style={{ marginTop: 0 }}>
            {SYSTEM_LABEL[part.system]} — ilgili bileşenler
          </h2>
          <ul style={{ margin: 0, paddingLeft: 18, lineHeight: 1.9 }}>
            {related.map((r) => (
              <li key={r.id}>
                <a href={`/arac/${r.id}`}>{r.name}</a>
              </li>
            ))}
          </ul>
        </section>
      )}

      <div style={{ marginTop: 26, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        <a className="btn" href="/gorsel-quiz">
          📸 Görsel quizde dene
        </a>
        {part.relatedLessonSlug && (
          <a className="btn btn--ghost" href={`/dersler/${part.relatedLessonSlug}`}>
            İlgili ders →
          </a>
        )}
        <a className="btn btn--ghost" href="/arac">
          ← Araç Tanıma
        </a>
      </div>
    </article>
  );
}
