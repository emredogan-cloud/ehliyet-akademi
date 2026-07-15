import type { ReactNode } from 'react';

/** Pazarlama kabuğu — yalnız halka açık vitrin (landing). Uygulama, (app) kabuğunu kullanır. */
export default function MarketingLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <a className="skip-link" href="#main">
        İçeriğe atla
      </a>
      <header className="topbar">
        <div className="container topbar__inner">
          <a className="brand" href="/" aria-label="Ehliyet Akademi ana sayfa">
            🚗{' '}
            <span>
              <b>Ehliyet</b> Akademi
            </span>
          </a>
          <nav className="nav" aria-label="Ana menü">
            <a href="/panel">Uygulamayı Aç</a>
            <a href="/tani">Tanı Denemesi</a>
            <a href="/fiyatlandirma">Fiyatlandırma</a>
          </nav>
        </div>
      </header>
      <main id="main" className="container" tabIndex={-1}>
        {children}
      </main>
      <footer className="site">
        <div className="container">
          <p>
            Ehliyet Akademi · Eğitim amaçlı hazırlık platformu. Resmî sınav ve güncel kural için
            MEB/MTSK ve sürücü kursunuz esastır. Bu bir <em>resmî MEB sınavı değildir</em>; gerçek
            sınav formatında denemedir.
          </p>
          <nav className="site__legal" aria-label="Yasal bağlantılar">
            <a href="/gizlilik">Gizlilik</a>
            <a href="/kullanim-kosullari">Kullanım Koşulları</a>
            <a href="/cerez-politikasi">Çerez Politikası</a>
            <a href="/kvkk">KVKK</a>
          </nav>
        </div>
      </footer>
    </>
  );
}
