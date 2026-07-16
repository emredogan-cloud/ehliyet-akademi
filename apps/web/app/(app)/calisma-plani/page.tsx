'use client';

/**
 * Kişisel Çalışma Planı (Sprint 3) — içerik lib/study (soru bankası, 1500+) üzerinden üretilir.
 * Program 2 · Faz 9 performans: içerik bileşeni ssr:false ile tembel yüklenir → ilk yük hafif.
 */
import dynamic from 'next/dynamic';

const CalismaPlaniContent = dynamic(
  () => import('@/components/CalismaPlaniContent').then((m) => m.CalismaPlaniContent),
  {
    ssr: false,
    loading: () => (
      <div className="grid" aria-busy="true">
        {[1, 2, 3].map((k) => (
          <div key={k} className="card">
            <div className="skeleton" style={{ width: '60%', height: 20 }} />
            <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 10 }} />
          </div>
        ))}
      </div>
    ),
  }
);

export default function CalismaPlaniPage() {
  return <CalismaPlaniContent />;
}
