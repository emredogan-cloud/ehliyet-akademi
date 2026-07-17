import type { ReactNode } from 'react';
import { Icon } from '@/components/ui/icons';

/**
 * Pazarlama kabuğu (Program 3.1 — referans 001/002) — yalnız halka açık vitrin.
 * Kalkan marka + slogan, nav, teal "Giriş Yap" pill; zengin footer (marka/linkler/yasal).
 * Uygulama, (app) kabuğunu kullanır.
 */
export default function MarketingLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <a className="skip-link" href="#main">
        İçeriğe atla
      </a>
      <header className="topbar">
        <div className="container topbar__inner">
          <a className="sb-brand" href="/" aria-label="Ehliyet Akademi ana sayfa">
            <span className="sb-brand__logo" aria-hidden>
              <Icon name="shield" size={22} strokeWidth={1.8} />
            </span>
            <span className="sb-brand__text">
              <span className="sb-brand__name">
                Ehliyet <b>Akademi</b>
              </span>
              <span className="sb-brand__tag">Güvenli sürüş, aydınlık gelecek.</span>
            </span>
          </a>
          <nav className="nav" aria-label="Ana menü">
            <a href="/panel">Uygulamayı Aç</a>
            <a href="/tani">Tanı Denemesi</a>
            <a href="/fiyatlandirma">Fiyatlandırma</a>
          </nav>
          <a className="ui-btn ui-btn--primary ui-btn--sm mk-login" href="/giris">
            <Icon name="user" size={16} /> Giriş Yap
          </a>
        </div>
      </header>
      <main id="main" className="container" tabIndex={-1}>
        {children}
      </main>
      <footer className="site">
        <div className="container">
          <div className="mk-footer">
            <div className="mk-footer__brand">
              <a className="sb-brand" href="/" aria-label="Ehliyet Akademi">
                <span className="sb-brand__logo" aria-hidden>
                  <Icon name="shield" size={22} strokeWidth={1.8} />
                </span>
                <span className="sb-brand__text">
                  <span className="sb-brand__name">
                    Ehliyet <b>Akademi</b>
                  </span>
                </span>
              </a>
              <p className="muted mk-footer__desc">
                Ehliyet sınavına akıllı, etkili ve güvenilir hazırlık platformu.
              </p>
            </div>
            <nav className="mk-footer__col" aria-label="Hızlı bağlantılar">
              <strong>Hızlı Linkler</strong>
              <a href="/panel">Panel</a>
              <a href="/dersler">Dersler</a>
              <a href="/fiyatlandirma">Premium</a>
            </nav>
            <nav className="mk-footer__col" aria-label="Yardım">
              <strong>Yardım</strong>
              <a href="/arama">Arama</a>
              <a href="/ayarlar">Ayarlar</a>
              <a href="/videolar">Videolar</a>
            </nav>
            <div className="mk-footer__note">
              <span className="mk-footer__cap" aria-hidden>
                <Icon name="gradcap" size={26} />
              </span>
              <p className="muted">
                Öğrenci deneyimleri, yayın sonrası doğrulanmış geri bildirimlerle burada yer
                alacaktır.
              </p>
            </div>
          </div>
          <p className="mk-footer__meb muted">
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
