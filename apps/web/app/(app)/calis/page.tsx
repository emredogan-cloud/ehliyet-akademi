import type { Metadata } from 'next';
import { allQuestions } from '@ea/question-bank';
import { Practice } from '@/components/Practice';
import { PageHeader } from '@/components/ui/layout';

export const metadata: Metadata = {
  title: 'Akıllı Çalışma (SRS)',
  description:
    'Aralıklı tekrar (SRS) ile akıllı pratik: yanlışların tam unutacağın anda yeniden sorulur; zayıf konulara öncelik verilir.',
};

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
