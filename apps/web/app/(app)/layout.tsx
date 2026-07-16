import type { ReactNode } from 'react';
import { Sidebar } from '@/components/Sidebar';
import { TopBar } from '@/components/shell/TopBar';

/**
 * Uygulama kabuğu (Program 3 · Faz D — referans 003-panel):
 * masaüstünde kalıcı tam-boy sol sidebar + içerik; mobilde üst bar + çekmece.
 * İçerik sütununun sağ-üstünde global TopBar (tema/bildirim/avatar).
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
        <TopBar />
        {children}
      </main>
    </div>
  );
}
