import type { Metadata } from 'next';
import { EXAM_BLUEPRINT, SUBJECT_LABEL } from '@ea/content-schema';
import { subjectCounts } from '@ea/question-bank';

export const metadata: Metadata = {
  title: 'B Sınıfı Ehliyet Sınavına Akıllı Hazırlık',
  description:
    'Tanı denemesiyle hazırlık skorunu öğren, zayıf konularına odaklan, ilk denemede geç. Teorik e-Sınav + direksiyon pratiği.',
};

export default function HomePage() {
  const counts = subjectCounts();
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  return (
    <>
      <section className="hero">
        <p style={{ opacity: 0.85, fontWeight: 700, letterSpacing: '0.06em', margin: 0 }}>
          B SINIFI · TEORİK e-SINAV + DİREKSİYON
        </p>
        <h1>Bugün girsen geçer miydin?</h1>
        <p>
          Kısa bir tanı denemesiyle <strong>hazırlık skorunu</strong> ve ders bazlı eksiklerini
          öğren. Sonra tam da zayıf olduğun konulara çalış — ezber soru yağmuru değil, akıllı
          hazırlık.
        </p>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
          <a className="btn btn--onhero" href="/tani">
            Tanı denemesine başla →
          </a>
          <a
            className="btn btn--ghost"
            href="/dersler"
            style={{ color: '#fff', borderColor: 'rgba(255,255,255,.5)' }}
          >
            Derslere göz at
          </a>
        </div>
      </section>

      <h2 className="section-title">Nasıl çalışır?</h2>
      <div className="grid">
        <div className="card">
          <h3>1 · Tanı denemesi</h3>
          <p className="muted">Dört dersten dengeli sorular; birkaç dakikada seviyeni ölç.</p>
        </div>
        <div className="card">
          <h3>2 · Hazırlık skoru</h3>
          <p className="muted">
            Sınav geçme olasılığın ve <strong>trafik ışığı</strong> (yeşil/sarı/kırmızı) ile ders
            durumun.
          </p>
        </div>
        <div className="card">
          <h3>3 · Zayıf konuya odak</h3>
          <p className="muted">Aralıklı tekrar (SRS) yanlışlarını doğru zamanda tekrar sorar.</p>
        </div>
      </div>

      <h2 className="section-title">Teorik e-Sınav dağılımı</h2>
      <p className="muted">
        Gerçek e-Sınav: {EXAM_BLUEPRINT.totalQuestions} soru · {EXAM_BLUEPRINT.durationMinutes} dk ·
        geçmek için {EXAM_BLUEPRINT.passCorrect} doğru.
      </p>
      <div className="grid">
        {(
          Object.keys(EXAM_BLUEPRINT.distribution) as Array<
            keyof typeof EXAM_BLUEPRINT.distribution
          >
        ).map((s) => (
          <div className="card" key={s}>
            <strong>{SUBJECT_LABEL[s]}</strong>
            <p className="muted" style={{ margin: '6px 0 0' }}>
              {EXAM_BLUEPRINT.distribution[s]} soru · bankada {counts[s] ?? 0} hazır
            </p>
          </div>
        ))}
      </div>
      <p className="muted" style={{ marginTop: 16, fontSize: '0.85rem' }}>
        Toplam {total} özgün soru (başlangıç kümesi). Sorular resmî müfredattan, kendi ifademizle
        yazılmıştır.
      </p>
    </>
  );
}
