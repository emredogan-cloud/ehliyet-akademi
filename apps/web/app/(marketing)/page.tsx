import type { Metadata } from 'next';
import { EXAM_BLUEPRINT, SUBJECT_LABEL } from '@ea/content-schema';
import { subjectCounts, allQuestions } from '@ea/question-bank';
import { LESSONS } from '@/content/lessons';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { Reveal } from '@/components/ui/Reveal';
import { Icon, type IconName } from '@/components/ui/icons';
import type { Accent } from '@/components/ui/primitives';
import { CourseJsonLd, FaqJsonLd } from '@/components/JsonLd';
import { buildMetadata } from '@/lib/seo/metadata';
import { HOME_FAQ } from '@/lib/seo/faq';

export const metadata: Metadata = buildMetadata({
  title: 'B Sınıfı Ehliyet Sınavına Akıllı Hazırlık',
  description:
    'Türkiye’nin en gelişmiş ehliyet eğitim platformu: özgün soru bankası, AI Koç, ders anlatımları, trafik işaretleri ve deneme sınavları. Tanı denemesiyle hazırlık skorunu öğren, ilk denemede geç.',
  path: '/',
  keywords: [
    'ehliyet sınavı',
    'ehliyet eğitimi',
    'B sınıfı ehliyet',
    'e-sınav hazırlık',
    'ehliyet deneme sınavı',
    'trafik işaretleri',
    'ehliyet soru bankası',
  ],
});

const FEATURES: Array<{
  icon: IconName;
  img: string;
  accent: Accent;
  title: string;
  desc: string;
  href: string;
}> = [
  {
    icon: 'target',
    accent: 'teal',
    img: '/assets/feature-icons/tani.webp',
    title: 'Tanı + Hazırlık skoru',
    desc: 'Kısa denemeyle seviyeni ölç; trafik ışığıyla ders durumunu gör.',
    href: '/tani',
  },
  {
    icon: 'brain',
    accent: 'purple',
    img: '/assets/feature-icons/beyin.webp',
    title: 'Akıllı tekrar (SRS)',
    desc: 'Yanlışlarını tam unutmadan önce, doğru zamanda tekrar sorar.',
    href: '/calis',
  },
  {
    icon: 'timer',
    accent: 'blue',
    img: '/assets/feature-icons/kronometre.webp',
    title: 'Gerçek e-Sınav simülatörü',
    desc: '50 soru · 45 dk · 35 baraj — birebir sınav formatı.',
    href: '/deneme-sinavi',
  },
  {
    icon: 'sign',
    accent: 'amber',
    img: '/assets/feature-icons/isaret.webp',
    title: 'Trafik işaretleri galerisi',
    desc: 'Özgün SVG işaret sistemi; kategori süz, ara, çevir-öğren.',
    href: '/isaretler',
  },
  {
    icon: 'car',
    accent: 'green',
    img: '/assets/feature-icons/arac.webp',
    title: 'Araç tanıma',
    desc: 'Motor bölmesinden pedallara — direksiyon için görselli rehber.',
    href: '/arac',
  },
  {
    icon: 'bot',
    accent: 'red',
    img: '/assets/feature-icons/ai.webp',
    title: 'Grounded AI Koç',
    desc: 'Yalnız kendi içeriğimizden yanıt; halüsinasyon üretmez.',
    href: '/ai-koc',
  },
];

const JOURNEY = ['Tanı denemesi', 'Zayıf konuya odak', 'Aralıklı tekrar', 'Deneme sınavı'] as const;

const TRUST: Array<{ icon: IconName; accent: Accent; title: string; desc: string }> = [
  {
    icon: 'rocket',
    accent: 'teal',
    title: '%100 özgün içerik',
    desc: 'Resmî MEB müfredatından, kendi ifademizle. Kopya soru yok.',
  },
  {
    icon: 'ban',
    accent: 'red',
    title: 'Reklamsız & dikkat dağıtmayan',
    desc: 'Karanlık desen yok; motivasyon kutlamadır, baskı değil.',
  },
  {
    icon: 'wifi-off',
    accent: 'amber',
    title: 'Offline çalışır (PWA)',
    desc: 'İnternet olmadan da derslere ve pratiğe devam et.',
  },
  {
    icon: 'lock',
    accent: 'green',
    title: 'Gizlilik öncelikli',
    desc: 'İlerlemen cihazında; rızasız izleyici yüklenmez (KVKK-dostu).',
  },
];

const SUBJECT_META: Record<string, { icon: IconName; accent: Accent }> = {
  trafik: { icon: 'trafficlight', accent: 'teal' },
  ilkyardim: { icon: 'firstaid', accent: 'amber' },
  motor: { icon: 'car', accent: 'purple' },
  adab: { icon: 'road', accent: 'blue' },
};

export default function HomePage() {
  const counts = subjectCounts();
  const totalQ = Object.values(counts).reduce((a, b) => a + b, 0);
  const stats: Array<{ icon: IconName; n: string; cap: string }> = [
    { icon: 'clipboard', n: `${totalQ}`, cap: 'Özgün Soru' },
    { icon: 'check-circle', n: `${LESSONS.length}`, cap: 'Ders' },
    { icon: 'book', n: `${SIGNS.length}`, cap: 'Trafik İşareti' },
    { icon: 'car', n: `${VEHICLE_PARTS.length}`, cap: 'Araç Görseli' },
  ];

  return (
    <>
      <CourseJsonLd lessonCount={LESSONS.length} questionCount={allQuestions().length} />
      <FaqJsonLd items={HOME_FAQ} />
      {/* ── Hero (ref 001) ─────────────────────────────────── */}
      <section className="mk-hero">
        <div className="mk-hero__copy">
          <p className="mk-hero__eyebrow">B SINIFI · TEORİK · SINAV · DİREKSİYON</p>
          <h1 className="mk-hero__title">
            Bugün girsen <span className="mk-hero__grad">geçer miydin?</span>
          </h1>
          <p className="mk-hero__lead">
            Kısa bir tanı denemesiyle <strong className="mk-hero__key">hazırlık skorunu</strong>{' '}
            öğren, hangi konularda eksiğin olduğunu gör ve sana özel çalışma planınla sınavda
            başarıya ulaş.
          </p>
          <div className="mk-hero__cta">
            <a className="ui-btn ui-btn--primary ui-btn--lg" href="/tani">
              <Icon name="user" size={18} /> Ücretsiz tanı denemesi →
            </a>
            <a className="ui-btn ui-btn--ghost ui-btn--lg" href="/panel">
              <Icon name="phone" size={18} /> Uygulamayı aç
            </a>
          </div>
          <div className="mk-hero__stats">
            {stats.map((s) => (
              <div key={s.cap} className="mk-hero__stat">
                <span className="mk-hero__stat-ic" aria-hidden>
                  <Icon name={s.icon} size={20} />
                </span>
                <span>
                  <span className="mk-hero__stat-n">{s.n}</span>
                  <span className="mk-hero__stat-c">{s.cap}</span>
                </span>
              </div>
            ))}
          </div>
        </div>
        <div className="mk-hero__art">
          {/* Üretilmiş kahraman görseli (ASSET A1 / 001-A) */}
          <img
            src="/assets/ui/landing-hero.webp"
            alt=""
            width={1536}
            height={1024}
            className="mk-hero__img"
            aria-hidden
          />
        </div>
      </section>

      {/* ── 4 adımlı yolculuk (ref 002-A) ─────────────────── */}
      <Reveal as="section">
        <div className="mk-stepper" role="list" aria-label="Öğrenme yolculuğu">
          {JOURNEY.map((step, i) => (
            <div className="mk-stepper__item" role="listitem" key={step}>
              <span className="mk-stepper__pill">
                <span className="mk-stepper__num">{i + 1}</span>
                {step}
                <span aria-hidden className="mk-stepper__go">
                  {i === 0 ? '✓' : '→'}
                </span>
              </span>
              {i < JOURNEY.length && <span className="mk-stepper__dash" aria-hidden />}
            </div>
          ))}
          <div className="mk-stepper__item" role="listitem">
            <span className="mk-stepper__pill mk-stepper__pill--win">
              <Icon name="trophy" size={16} /> İlk denemede geç
            </span>
          </div>
        </div>
      </Reveal>

      {/* ── e-Sınav dağılımı (ref 002-B) ──────────────────── */}
      <Reveal as="section">
        <h2 className="section-title mk-title">Teorik e-Sınav dağılımı</h2>
        <p className="muted" style={{ marginTop: 0 }}>
          Gerçek e-Sınav: {EXAM_BLUEPRINT.totalQuestions} soru · {EXAM_BLUEPRINT.durationMinutes} dk
          · geçmek için {EXAM_BLUEPRINT.passCorrect} doğru. Bankada toplam {totalQ} özgün soru.
        </p>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '240px' }}>
          {(
            Object.keys(EXAM_BLUEPRINT.distribution) as Array<
              keyof typeof EXAM_BLUEPRINT.distribution
            >
          ).map((s) => {
            const need = EXAM_BLUEPRINT.distribution[s];
            const have = counts[s] ?? 0;
            const meta = SUBJECT_META[s] ?? { icon: 'book', accent: 'teal' };
            return (
              <div className="ui-card mk-dist" key={s}>
                <span
                  className="mastery-row__icon"
                  style={{ ['--m-accent' as string]: `var(--accent-${meta.accent})` }}
                  aria-hidden
                >
                  <Icon name={meta.icon} size={20} />
                </span>
                <div className="mk-dist__body">
                  <strong>{SUBJECT_LABEL[s]}</strong>
                  <div
                    className="ui-progress"
                    role="progressbar"
                    aria-valuenow={need}
                    aria-valuemin={0}
                    aria-valuemax={EXAM_BLUEPRINT.totalQuestions}
                    aria-label={`${SUBJECT_LABEL[s]} soru payı`}
                  >
                    <span
                      className="ui-progress__fill"
                      style={{ width: `${(need / EXAM_BLUEPRINT.totalQuestions) * 100}%` }}
                    />
                  </div>
                  <p className="muted mk-dist__meta">
                    {need} soru · bankada {have} hazır
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </Reveal>

      {/* ── Neler var? (ref 001-J) ────────────────────────── */}
      <Reveal as="section">
        <h2 className="section-title mk-title">Neler var?</h2>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '160px' }}>
          {FEATURES.map((f) => (
            <a className="ui-card ui-card--interactive mk-feature" key={f.title} href={f.href}>
              <span className="mk-feature__img" aria-hidden>
                <img src={f.img} alt="" />
              </span>
              <strong>{f.title}</strong>
              <span className="muted mk-feature__desc">{f.desc}</span>
              <span className="mk-feature__go" aria-hidden>
                →
              </span>
            </a>
          ))}
        </div>
      </Reveal>

      {/* ── Neden Ehliyet Akademi? (ref 002-C) ────────────── */}
      <Reveal as="section">
        <h2 className="section-title mk-title">Neden Ehliyet Akademi?</h2>
        <div className="grid-auto" style={{ ['--grid-min' as string]: '240px' }}>
          {TRUST.map((t) => (
            <div className="ui-card mk-feature" key={t.title}>
              <span
                className="ui-iconbadge ui-iconbadge--md"
                style={{ ['--ib-accent' as string]: `var(--accent-${t.accent})` }}
                aria-hidden
              >
                <Icon name={t.icon} size={22} />
              </span>
              <strong>{t.title}</strong>
              <span className="muted mk-feature__desc">{t.desc}</span>
            </div>
          ))}
        </div>
      </Reveal>

      {/* ── CTA bandı (ref 002-D) ─────────────────────────── */}
      <section className="mk-cta">
        <div className="mk-cta__art mk-cta__art--car" aria-hidden>
          {/* Beyaz sedan (ref 002-D) */}
          <img src="/assets/art/sedan-side.webp" alt="" />
        </div>
        <div className="mk-cta__body">
          <h2 className="mk-cta__title">
            Hazırlığa <span className="mk-hero__grad">bugün</span> başla
          </h2>
          <p className="muted">
            Ücretsiz tanı denemesiyle nerede olduğunu gör, güçlü ve zayıf konularını birlikte
            tamamlayalım.
          </p>
          <a className="ui-btn ui-btn--primary ui-btn--lg" href="/tani">
            Tanı denemesine başla →
          </a>
        </div>
        <div className="mk-cta__flag" aria-hidden>
          🏁
        </div>
      </section>

      {/* ── SSS (AEO/AI Overviews — FaqJsonLd ile birebir) ──── */}
      <section className="mk-faq" aria-labelledby="sss-baslik">
        <h2 id="sss-baslik" className="mk-section__title" style={{ textAlign: 'center' }}>
          Sık Sorulan Sorular
        </h2>
        <div className="mk-faq__list">
          {HOME_FAQ.map((f) => (
            <details key={f.question} className="mk-faq__item">
              <summary className="mk-faq__q">{f.question}</summary>
              <p className="mk-faq__a">{f.answer}</p>
            </details>
          ))}
        </div>
      </section>

      <p className="muted mk-smallprint">
        Sorular resmî müfredattan, kendi ifademizle yazılmıştır (uzman onay süreci sürer). Öğrenci
        deneyimleri, yayın sonrası doğrulanmış geri bildirimlerle burada yer alacaktır.
      </p>
    </>
  );
}
