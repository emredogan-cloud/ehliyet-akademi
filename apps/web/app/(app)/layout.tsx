import type { ReactNode } from 'react';
import { Sidebar } from '@/components/Sidebar';

/**
 * Uygulama kabuğu (ROADMAP Faz 7 redesign — SaaS layout):
 * masaüstünde kalıcı tam-boy sol sidebar + içerik; mobilde üst bar + çekmece.
 * Tüm öğrenme sayfaları bu kabuğu kullanır; (marketing) yalnız vitrindir.
 */
export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <div className="shell">
      <a className="skip-link" href="#main">
        İçeriğe atla
      </a>
      <Sidebar />
      <main id="main" className="shell__content" tabIndex={-1}>
        {children}
      </main>
    </div>
  );
}
