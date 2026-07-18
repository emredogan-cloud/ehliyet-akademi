import type { Metadata } from 'next';
import { SUBJECT_LABEL, type Subject } from '@ea/content-schema';
import { LESSONS } from '@/content/lessons';
import { PageHeader, Section, Grid } from '@/components/ui/layout';
import { LessonCard } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';
import type { Accent } from '@/components/ui/primitives';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Dersler',
  description:
    'Trafik, ilk yardım, araç tekniği, trafik adabı ve direksiyon (sürüş akademisi) dersleri — kısa, görsel, sınav odaklı.',
  path: '/dersler',
});

const GROUP_ORDER: Subject[] = ['trafik', 'ilkyardim', 'motor', 'adab', 'pratik'];
const GROUP_NOTE: Record<Subject, string> = {
  trafik: 'e-Sınav ağırlığı en yüksek ders (23 soru).',
  ilkyardim: 'Hayat kurtaran temel bilgiler (12 soru).',
  motor: 'Aracı tanı, ikazları oku (9 soru).',
  adab: 'Güvenli ve saygılı sürücülük (6 soru).',
  pratik: 'Sürüş Akademisi — direksiyon sınavı uygulaması.',
};
const GROUP_META: Record<Subject, { icon: IconName; accent: Accent }> = {
  trafik: { icon: 'trafficlight', accent: 'teal' },
  ilkyardim: { icon: 'firstaid', accent: 'red' },
  motor: { icon: 'car', accent: 'purple' },
  adab: { icon: 'road', accent: 'blue' },
  pratik: { icon: 'target', accent: 'green' },
};
// Ders-özel üretilmiş ikonlar (ref 004-B) — eşleşmeyen dersler çizgi-ikon + aksanla kalır.
const LESSON_ICON: Record<string, string> = {
  'trafik-isaretleri': '/assets/lesson-icons/yon-levhalari.webp',
  'kavsak-oncelik': '/assets/lesson-icons/kavsak.webp',
  'kavsak-uygulama': '/assets/lesson-icons/kavsak.webp',
  'hiz-takip': '/assets/lesson-icons/hiz-guvenlik.webp',
  'sollama-serit': '/assets/lesson-icons/direksiyon.webp',
  'isik-gece': '/assets/lesson-icons/gece-suruc.webp',
  'yaya-gecidi': '/assets/lesson-icons/yaya.webp',
  'cevre-yakit': '/assets/lesson-icons/cevre.webp',
  'yasal-sorumluluk': '/assets/lesson-icons/yasal-belge.webp',
  'trafik-adabi': '/assets/lesson-icons/yaya.webp',
  'ilk-yardim-temel': '/assets/lesson-icons/ilkyardim.webp',
  'kanama-sok': '/assets/lesson-icons/kanama.webp',
  'tyd-kalp-masaji': '/assets/lesson-icons/solunum.webp',
  'motor-temel': '/assets/lesson-icons/motor.webp',
  'gosterge-ikaz': '/assets/lesson-icons/gosterge.webp',
};

// Kart ikonlarına referanstaki gibi çeşitlilik: grup içinde aksan döngüsü.
const ACCENT_CYCLE: Accent[] = ['teal', 'blue', 'green', 'purple', 'amber', 'red'];

export default function DerslerPage() {
  return (
    <>
      <PageHeader
        title="Dersler"
        emoji="📚"
        subtitle="Teorik akademi + Sürüş Akademisi. Her ders görselli, özetli; sonunda tekrar kartları ve alıştırma soruları var."
        actions={
          /* Üretilmiş başlık dekoru (ASSET A7) */
          <img
            src="/assets/art/workzone-scene.webp"
            alt=""
            className="page-decor"
            aria-hidden
            loading="lazy"
          />
        }
      />

      {GROUP_ORDER.map((subject) => {
        const items = LESSONS.filter((l) => l.subject === subject).sort((a, b) => a.no - b.no);
        if (items.length === 0) return null;
        const gm = GROUP_META[subject];
        return (
          <Section
            key={subject}
            icon={<Icon name={gm.icon} size={22} />}
            title={
              <span
                style={{
                  display: 'inline-flex',
                  alignItems: 'baseline',
                  gap: 10,
                  flexWrap: 'wrap',
                }}
              >
                {SUBJECT_LABEL[subject]}
                <span className="muted" style={{ fontSize: 'var(--fs-sm)', fontWeight: 400 }}>
                  {GROUP_NOTE[subject]}
                </span>
              </span>
            }
          >
            <Grid preset="cards">
              {items.map((l, i) => {
                const questions = l.quizQuestionIds.length + l.practiceQuestionIds.length;
                const meta = `${l.minutes} dk · ${questions} soru${
                  l.reviewCards.length > 0 ? ` · ${l.reviewCards.length} tekrar kartı` : ''
                }`;
                return (
                  <LessonCard
                    key={l.id}
                    icon={gm.icon}
                    iconSrc={LESSON_ICON[l.slug]}
                    accent={ACCENT_CYCLE[i % ACCENT_CYCLE.length]}
                    title={l.title}
                    desc={l.summary}
                    meta={meta}
                    href={`/dersler/${l.slug}`}
                    premium={l.premium}
                  />
                );
              })}
            </Grid>
          </Section>
        );
      })}

      <div className="ui-card ui-card--accent hero-banner" style={{ marginTop: 'var(--sp-4)' }}>
        <span
          className="ui-iconbadge ui-iconbadge--lg"
          style={{ ['--ib-accent' as string]: 'var(--accent-amber)' }}
          aria-hidden
        >
          <Icon name="trophy" size={26} />
        </span>
        <div className="hero-banner__body">
          <div className="hero-banner__title">
            Sınavda başarıya giden yol, iyi bir hazırlıkla başlar.
          </div>
          <div className="hero-banner__text">Düzenli çalış, tekrar yap ve kendine güven!</div>
        </div>
        <div className="hero-banner__action">
          <a className="ui-btn ui-btn--primary ui-btn--md" href="/calis">
            Çalışmaya devam et →
          </a>
        </div>
      </div>
    </>
  );
}
