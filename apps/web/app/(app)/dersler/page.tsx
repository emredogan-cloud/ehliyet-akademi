import type { Metadata } from 'next';
import { SUBJECT_LABEL, type Subject } from '@ea/content-schema';
import { LESSONS } from '@/content/lessons';

export const metadata: Metadata = {
  title: 'Dersler',
  description:
    'Trafik, ilk yardım, araç tekniği, trafik adabı ve direksiyon (sürüş akademisi) dersleri — kısa, görsel, sınav odaklı.',
};

const GROUP_ORDER: Subject[] = ['trafik', 'ilkyardim', 'motor', 'adab', 'pratik'];
const GROUP_NOTE: Record<Subject, string> = {
  trafik: 'e-Sınav ağırlığı en yüksek ders (23 soru).',
  ilkyardim: 'Hayat kurtaran temel bilgiler (12 soru).',
  motor: 'Aracı tanı, ikazları oku (9 soru).',
  adab: 'Güvenli ve saygılı sürücülük (6 soru).',
  pratik: 'Sürüş Akademisi — direksiyon sınavı uygulaması.',
};

export default function DerslerPage() {
  return (
    <>
      <h1 style={{ margin: '24px 0 6px' }}>Dersler</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Teorik akademi + Sürüş Akademisi. Her ders görselli, özetli; sonunda tekrar kartları ve
        alıştırma soruları var.
      </p>

      {GROUP_ORDER.map((subject) => {
        const items = LESSONS.filter((l) => l.subject === subject).sort((a, b) => a.no - b.no);
        if (items.length === 0) return null;
        return (
          <section key={subject} style={{ marginTop: 26 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, flexWrap: 'wrap' }}>
              <h2 className="section-title" style={{ marginTop: 0 }}>
                {SUBJECT_LABEL[subject]}
              </h2>
              <span className="muted" style={{ fontSize: '0.85rem' }}>
                {GROUP_NOTE[subject]}
              </span>
            </div>
            <div className="grid">
              {items.map((l) => (
                <a className="card card--link" key={l.id} href={`/dersler/${l.slug}`}>
                  <span className="badge">{SUBJECT_LABEL[l.subject]}</span>
                  <h3 style={{ margin: '10px 0 6px' }}>{l.title}</h3>
                  <p className="muted" style={{ margin: 0 }}>
                    {l.summary}
                  </p>
                  <p className="muted" style={{ margin: '8px 0 0', fontSize: '0.82rem' }}>
                    {l.minutes} dk · {l.quizQuestionIds.length + l.practiceQuestionIds.length} soru
                    {l.reviewCards.length > 0 ? ` · ${l.reviewCards.length} tekrar kartı` : ''}
                  </p>
                </a>
              ))}
            </div>
          </section>
        );
      })}
    </>
  );
}
