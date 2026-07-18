import type { Metadata } from 'next';
import { allQuestions } from '@ea/question-bank';
import { Practice } from '@/components/Practice';
import { PageHeader } from '@/components/ui/layout';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Akıllı Çalışma (SRS)',
  description:
    'Aralıklı tekrar (SRS) ile akıllı pratik: yanlışların tam unutacağın anda yeniden sorulur; zayıf konulara öncelik verilir.',
  path: '/calis',
});

export default function CalisPage() {
  const pool = allQuestions().filter((q) => q.subject !== 'pratik');
  return (
    <>
      <PageHeader
        title="Akıllı Çalışma"
        emoji="🧠"
        subtitle="Aralıklı tekrar (SM-2) + zayıf konu önceliği. Her oturum ~10 soru."
      />
      <Practice pool={pool} />
    </>
  );
}
