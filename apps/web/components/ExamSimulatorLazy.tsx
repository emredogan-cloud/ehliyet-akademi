'use client';
/**
 * Sınav simülatörünü istemci tarafında tembel yükler (Program 2 · Faz 9 · performans).
 * Soru bankası büyük (1500+); ssr:false + code-split → ilk yük JS'i hafif, banka
 * yalnız kullanıcı bu sayfaya geldiğinde ayrı parça olarak indirilir.
 */
import dynamic from 'next/dynamic';

const ExamSimulator = dynamic(
  () => import('@/components/ExamSimulator').then((m) => m.ExamSimulator),
  {
    ssr: false,
    loading: () => (
      <div className="card" aria-busy="true" style={{ minHeight: 220 }}>
        <div className="skeleton" style={{ width: '40%', height: 22 }} />
        <div className="skeleton" style={{ width: '90%', height: 14, marginTop: 14 }} />
        <div className="skeleton" style={{ width: '80%', height: 14, marginTop: 8 }} />
      </div>
    ),
  }
);

export function ExamSimulatorLazy() {
  return <ExamSimulator />;
}
