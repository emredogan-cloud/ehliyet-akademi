import type { Metadata } from 'next';
import { EXAM_BLUEPRINT, SUBJECT_LABEL } from '@ea/content-schema';
import { subjectCounts } from '@ea/question-bank';
import { LESSONS } from '@/content/lessons';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { HeroArt } from '@/components/marketing/HeroArt';

export const metadata: Metadata = {
  title: 'B Sınıfı Ehliyet Sınavına Akıllı Hazırlık',
  description:
    'Tanı denemesiyle hazırlık skorunu öğren, zayıf konularına odaklan, ilk denemede geç. Teorik e-Sınav + direksiyon pratiği, özgün trafik işaretleri ve araç görselleriyle.',
};

const FEATURES = [
  {
    icon: '🎯',
    title: 'Tanı → Hazırlık skoru',
    desc: 'Kısa denemeyle seviyeni ölç; trafik ışığıyla ders durumunu gör.',
    href: '/tani',
  },
  {
    icon: '🧠',
    title: 'Akıllı tekrar (SRS)',
    desc: 'Yanlışlarını tam unutmadan önce, doğru zamanda tekrar sorar.',
    href: '/calis',
  },
  {
    icon: '⏱️',
    title: 'Gerçek e-Sınav simülatörü',
    desc: '50 soru · 45 dk · 35 baraj — birebir sınav formatı.',
    href: '/deneme-sinavi',
  },
  {
    icon: '🚸',
    title: 'Trafik işaretleri galerisi',
    desc: 'Özgün SVG işaret sistemi; kategori süz, ara, çevir-öğren.',
    href: '/isaretler',
  },
  {
    icon: '🚙',
    title: 'Araç tanıma',
    desc: 'Motor bölmesinden pedallara — direksiyon için görselli rehber.',
    href: '/arac',
  },
  {
    icon: '🤖',
    title: 'Grounded AI Koç',
    desc: 'Yalnız kendi içeriğimizden yanıt; halüsinasyon üretmez.',
    href: '/ai-koc',
  },
];

const JOURNEY = [
  'Tanı denemesi',
  'Zayıf konuya odak',
  'Aralıklı tekrar',
  'Deneme sınavı',
  'İlk denemede geç',
];

const TRUST = [
  {
    icon: '✍️',
    title: '%100 özgün içerik',
    desc: 'Resmî MEB müfredatından, kendi ifademizle. Kopya soru yok.',
  },
  {
    icon: '🚫',
    title: 'Reklamsız & dikkat dağıtmayan',
    desc: 'Karanlık desen yok; motivasyon kutlamadır, baskı değil.',
  },
  {
    icon: '📴',
    title: 'Offline çalışır (PWA)',
    desc: 'İnternet olmadan da derslere ve pratiğe devam et.',
  },
  {
    icon: '🔒',
    title: 'Gizlilik-öncelikli',
    desc: 'İlerlemen cihazında; rızasız izleyici yüklenmez (KVKK-dostu).',
  },
];

export default function HomePage() {
  const counts = subjectCounts();
  const totalQ = Object.values(counts).reduce((a, b) => a + b, 0);
  const stats = [
    { n: `${totalQ}`, cap: 'özgün soru' },
    { n: `${LESSONS.length}`, cap: 'ders' },
    { n: `${SIGNS.length}`, cap: 'trafik işareti' },
    { n: `${VEHICLE_PARTS.length}`, cap: 'araç görseli' },
  ];

  return (
    <>
      <section className="hero hero--split">
        <div className="hero__copy">
          <p className="hero__eyebrow">B SINIFI · TEORİK e-SINAV + DİREKSİYON</p>
          <h1>
            Bugün girsen <span className="grad">geçer miydin?</span>
          </h1>
          <p>
            Kısa bir tanı denemesiyle <strong>hazırlık skorunu</strong> öğren, tam da zayıf olduğun
            konulara çalış. Ezber soru yağmuru değil — akıllı, görsel, sınav-odaklı hazırlık.
          </p>
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
            <a className="btn btn--onhero" href="/tani">
              Ücretsiz tanı denemesi →
            </a>
            <a
              className="btn btn--ghost"
              href="/panel"
              style={{ color: '#fff', borderColor: 'rgba(255,255,255,.5)' }}
            >
              Uygulamayı aç
            </a>
          </div>
          <div className="hero__stats">
            {stats.map((s) => (
              <div key={s.cap}>
                <div className="hero__stat-n">{s.n}</div>
                <div className="hero__stat-c">{s.cap}</div>
              </div>
            ))}
          </div>
        </div>
        <HeroArt />
      </section>

      <h2 className="section-title">Neler var?</h2>
      <div className="feature-grid">
        {FEATURES.map((f) => (
          <a className="feature-card" key={f.title} href={f.href}>
            <span className="feature-card__icon" aria-hidden>
              {f.icon}
            </span>
            <strong>{f.title}</strong>
            <span className="muted" style={{ fontSize: '0.88rem' }}>
              {f.desc}
            </span>
          </a>
        ))}
      </div>

      <h2 className="section-title">Öğrenme yolculuğun</h2>
      <div className="journey-flow">
        {JOURNEY.map((step, i) => (
          <div className="journey-flow__step" key={step}>
            <span className="journey-flow__num">{i + 1}</span>
            <span>{step}</span>
            {i < JOURNEY.length - 1 && (
              <span className="journey-flow__arrow" aria-hidden>
                →
              </span>
            )}
          </div>
        ))}
      </div>

      <h2 className="section-title">Teorik e-Sınav dağılımı</h2>
      <p className="muted" style={{ marginTop: 0 }}>
        Gerçek e-Sınav: {EXAM_BLUEPRINT.totalQuestions} soru · {EXAM_BLUEPRINT.durationMinutes} dk ·
        geçmek için {EXAM_BLUEPRINT.passCorrect} doğru. Bankada toplam {totalQ} özgün soru.
      </p>
      <div className="dist-grid">
        {(
          Object.keys(EXAM_BLUEPRINT.distribution) as Array<
            keyof typeof EXAM_BLUEPRINT.distribution
          >
        ).map((s) => {
          const need = EXAM_BLUEPRINT.distribution[s];
          const have = counts[s] ?? 0;
          return (
            <div className="dist-card" key={s}>
              <div className="dist-card__bar" aria-hidden>
                <span
                  style={{
                    width: `${Math.min(100, (need / EXAM_BLUEPRINT.totalQuestions) * 100 * 2)}%`,
                  }}
                />
              </div>
              <strong>{SUBJECT_LABEL[s]}</strong>
              <p className="muted" style={{ margin: '4px 0 0', fontSize: '0.84rem' }}>
                {need} soru · bankada {have} hazır
              </p>
            </div>
          );
        })}
      </div>

      <h2 className="section-title">Neden Ehliyet Akademi?</h2>
      <div className="feature-grid">
        {TRUST.map((t) => (
          <div className="feature-card feature-card--static" key={t.title}>
            <span className="feature-card__icon" aria-hidden>
              {t.icon}
            </span>
            <strong>{t.title}</strong>
            <span className="muted" style={{ fontSize: '0.88rem' }}>
              {t.desc}
            </span>
          </div>
        ))}
      </div>

      <section className="cta-band">
        <h2 style={{ margin: '0 0 8px' }}>Hazırlığa bugün başla</h2>
        <p className="muted" style={{ marginTop: 0 }}>
          Ücretsiz tanı denemesiyle nerede olduğunu gör; gerisini birlikte tamamlayalım.
        </p>
        <a className="btn" href="/tani">
          Tanı denemesine başla →
        </a>
      </section>

      <p className="muted" style={{ marginTop: 22, fontSize: '0.82rem', textAlign: 'center' }}>
        Sorular resmî müfredattan, kendi ifademizle yazılmıştır (uzman onay süreci sürer). Öğrenci
        deneyimleri, yayın sonrası doğrulanmış geri bildirimlerle burada yer alacaktır.
      </p>
    </>
  );
}
