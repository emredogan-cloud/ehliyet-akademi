import type { Metadata } from 'next';
import { VIDEOS } from '@/content/videos';
import { VideoPlayer } from '@/components/video/VideoPlayer';

export const metadata: Metadata = {
  title: 'Video Dersler',
  description:
    'Animasyonlu manevra anlatımları ve planlanan gerçek çekim video müfredatı — bölümler, transkript ve yer imleriyle.',
};

export default function VideolarPage() {
  const available = VIDEOS.filter((v) => v.status === 'available');
  const planned = VIDEOS.filter((v) => v.status === 'planned');
  return (
    <div data-testid="videolar">
      <h1 style={{ margin: '24px 0 6px' }}>Video Dersler</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Bölümler, senkron transkript ve yer imleriyle video öğrenme. Mevcut videolar kendi animasyon
        sistemimizden üretilmiş <strong>%100 özgün</strong> anlatımlardır; gerçek çekim müfredatı
        aşağıda açıkça “planlanıyor” olarak listelenir.
      </p>

      {available.map((v) => (
        <section key={v.id} style={{ margin: '26px 0' }}>
          <h2 className="section-title" style={{ marginTop: 0 }}>
            {v.title}
          </h2>
          <p className="muted" style={{ marginTop: 0, fontSize: '0.9rem' }}>
            {v.description}
          </p>
          <VideoPlayer videoId={v.id} />
          {v.relatedLessonSlug && (
            <a
              className="btn btn--ghost"
              style={{ marginTop: 10 }}
              href={`/dersler/${v.relatedLessonSlug}`}
            >
              İlgili derse git →
            </a>
          )}
        </section>
      ))}

      <h2 className="section-title">Planlanan gerçek çekim müfredatı</h2>
      <p className="muted" style={{ marginTop: 0, fontSize: '0.9rem' }}>
        Bu videolar gerçek araç çekimi gerektirir; çekimler tamamlandığında burada yayınlanacaktır.
      </p>
      <div className="vehicle-grid">
        {planned.map((v) => (
          <div className="card" key={v.id} style={{ margin: 0 }} data-testid="video-planned">
            <strong>🎬 {v.title}</strong>
            <p className="muted" style={{ margin: '6px 0 0', fontSize: '0.86rem' }}>
              {v.description}
            </p>
            <span
              className="badge"
              style={{ marginTop: 10, display: 'inline-block' }}
              data-testid="planned-badge"
            >
              Çekim planlanıyor
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
