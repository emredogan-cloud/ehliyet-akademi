'use client';

/**
 * Arama gövdesi tembel yükleyici (LCP perf) — arama sağlayıcısı soru bankasını (1534)
 * çeker; ssr:false ile bu ağırlık ilk yükten çıkar → /arama First Load JS ~584kB → ~104kB.
 */
import dynamic from 'next/dynamic';

const AramaContent = dynamic(
  () => import('@/components/AramaContent').then((m) => m.AramaContent),
  {
    ssr: false,
    loading: () => (
      <div aria-busy="true" aria-label="Arama yükleniyor">
        <div className="search-box">
          <div className="skeleton" style={{ height: 48, borderRadius: 'var(--radius-sm)' }} />
        </div>
      </div>
    ),
  }
);

export function AramaLazy() {
  return <AramaContent />;
}
