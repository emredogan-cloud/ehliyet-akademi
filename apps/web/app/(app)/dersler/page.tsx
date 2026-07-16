import type { Metadata } from 'next';
import { SUBJECT_LABEL, type Subject } from '@ea/content-schema';
import { LESSONS } from '@/content/lessons';
import { PageHeader, Section, Grid } from '@/components/ui/layout';
import { LessonCard } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';
import type { Accent } from '@/components/ui/primitives';

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
const GROUP_META: Record<Subject, { icon: IconName; accent: Accent }> = {
  trafik: { icon: 'trafficlight', accent: 'teal' },
  ilkyardim: { icon: 'firstaid', accent: 'red' },
  motor: { icon: 'car', accent: 'purple' },
  adab: { icon: 'road', accent: 'blue' },
  pratik: { icon: 'target', accent: 'green' },
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
    </>
  );
}
