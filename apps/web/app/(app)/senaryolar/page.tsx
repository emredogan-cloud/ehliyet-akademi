import type { Metadata } from 'next';
import { SenaryolarContent } from '@/components/SenaryolarContent';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Trafik Senaryoları — İnteraktif Karar',
  description:
    'Gerçek trafik durumlarında doğru kararı ver: ışıksız kavşak, dönel kavşak, yaya geçidi ve daha fazlası. Adım adım senaryolarla öncelik ve güvenli sürüş pratiği.',
  path: '/senaryolar',
  keywords: ['trafik senaryoları', 'kavşak önceliği', 'yaya geçidi kuralı'],
});

export default function SenaryolarPage() {
  return <SenaryolarContent />;
}
