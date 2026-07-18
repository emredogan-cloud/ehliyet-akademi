import type { Metadata } from 'next';
import { GorselQuizContent } from '@/components/GorselQuizContent';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Görsel Trafik İşareti Quizi',
  description:
    'Trafik işaretlerini görselden tanı: rastgele işaret gelir, dört şıktan doğru anlamı seç. Anında geri bildirim ve zayıf işaretler destesiyle sınav pratiği.',
  path: '/gorsel-quiz',
  keywords: ['görsel quiz', 'trafik işareti quizi', 'işaret tanıma testi'],
});

export default function GorselQuizPage() {
  return <GorselQuizContent />;
}
