import type { Metadata } from 'next';
import { allQuestions } from '@ea/question-bank';
import { Practice } from '../../components/Practice';

export const metadata: Metadata = {
  title: 'Akıllı Çalışma (SRS)',
  description:
    'Aralıklı tekrar (SRS) ile akıllı pratik: yanlışların tam unutacağın anda yeniden sorulur; zayıf konulara öncelik verilir.',
};

export default function CalisPage() {
  const pool = allQuestions().filter((q) => q.subject !== 'pratik');
  return (
    <>
      <h1 style={{ margin: '24px 0 6px' }}>Akıllı Çalışma</h1>
      <p className="muted" style={{ marginTop: 0 }}>
        Aralıklı tekrar (SM-2) + zayıf konu önceliği. Her oturum ~10 soru.
      </p>
      <Practice pool={pool} />
    </>
  );
}
