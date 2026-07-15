import type { Metadata } from 'next';
import { SUBJECT_LABEL } from '@ea/content-schema';
import { LESSONS } from '@/content/lessons';

export const metadata: Metadata = {
  title: 'Dersler',
  description: 'Trafik, ilk yardım ve araç tekniği dersleri — kısa, görsel, sınav odaklı.',
};

export default function DerslerPage() {
  return (
    <>
      <h1 style={{ margin: '24px 0 6px' }}>Dersler</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Kısa, sınav odaklı dersler. Her ders sonunda konuyu pekiştiren sorular var.
      </p>
      <div className="grid">
        {LESSONS.map((l) => (
          <a className="card card--link" key={l.id} href={`/dersler/${l.slug}`}>
            <span className="badge">{SUBJECT_LABEL[l.subject]}</span>
            <h3 style={{ margin: '10px 0 6px' }}>
              {l.no}. {l.title}
            </h3>
            <p className="muted" style={{ margin: 0 }}>
              {l.summary}
            </p>
            <p className="muted" style={{ margin: '8px 0 0', fontSize: '0.82rem' }}>
              {l.minutes} dk · {l.quizQuestionIds.length} soru
            </p>
          </a>
        ))}
      </div>
    </>
  );
}
