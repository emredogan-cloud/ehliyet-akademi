'use client';

/**
 * Fiyatlandırma (ROADMAP Faz 16) — TEK-SEFERLİK satın alma: bir kez öde, kalıcı erişim.
 * Abonelik/yinelenen faturalama YOK. Varsayılan sağlayıcı mock (demo — gerçek tahsilat yok).
 */
import { useEffect, useState } from 'react';
import { PRODUCTS, type Product } from '../lib/products';
import { getPaymentProvider, loadEntitlements } from '../lib/payments';
import { isAuthed, me, serverPurchase } from '../lib/authClient';
import { track } from '../lib/analytics';

export function Pricing() {
  const [owned, setOwned] = useState<string[]>([]);
  const [msg, setMsg] = useState<string>('');
  const [busy, setBusy] = useState<string | null>(null);

  useEffect(() => {
    void me().finally(() => setOwned(loadEntitlements()));
  }, []);

  async function buy(p: Product) {
    setBusy(p.id);
    setMsg('');
    // Girişliyse: sunucu-taraflı kalıcı sahiplik (Epic 3). Değilse: yerel demo + not.
    if (isAuthed()) {
      const owned = await serverPurchase(p.id);
      setBusy(null);
      if (owned) {
        setMsg(
          `${p.title} hesabına KALICI olarak tanımlandı (demo ödeme — tüm cihazlarında geçerli).`
        );
        setOwned(owned);
      } else {
        setMsg('Satın alma başarısız — tekrar dene.');
      }
      return;
    }
    const res = await getPaymentProvider().checkout(p.id);
    setBusy(null);
    setMsg(res.message + ' Not: hesapla giriş yaparsan satın alman tüm cihazlarında geçerli olur.');
    if (res.ok) {
      track({ name: 'purchase_completed', props: { productId: p.id, priceTRY: p.priceTRY } });
      setOwned(loadEntitlements());
    }
  }

  return (
    <div>
      {msg && (
        <div className="explain" role="status" data-testid="pay-msg">
          {msg}
        </div>
      )}
      <div
        className="grid"
        style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))' }}
      >
        {PRODUCTS.map((p) => {
          const has = owned.includes(p.id);
          return (
            <div
              className="card"
              key={p.id}
              style={
                p.highlight
                  ? { borderColor: 'var(--primary)', boxShadow: '0 0 0 2px var(--primary-100)' }
                  : undefined
              }
              data-testid={`product-${p.id}`}
            >
              {p.highlight && <span className="badge">En avantajlı</span>}
              <h3 style={{ margin: '8px 0 4px' }}>{p.title}</h3>
              <p className="muted" style={{ margin: '0 0 10px' }}>
                {p.blurb}
              </p>
              <div style={{ fontSize: '1.8rem', fontWeight: 800, color: 'var(--primary)' }}>
                {p.priceTRY} ₺
                <span className="muted" style={{ fontSize: '0.8rem', fontWeight: 500 }}>
                  {' '}
                  · tek seferlik
                </span>
              </div>
              <ul className="prose" style={{ margin: '10px 0', paddingLeft: 18 }}>
                {p.features.map((f, k) => (
                  <li key={k}>{f}</li>
                ))}
              </ul>
              {has ? (
                <span className="badge" data-testid={`owned-${p.id}`}>
                  ✓ Sahipsin — ömür boyu
                </span>
              ) : (
                <button
                  className="btn"
                  onClick={() => buy(p)}
                  disabled={busy !== null}
                  data-testid={`buy-${p.id}`}
                >
                  {busy === p.id ? 'İşleniyor…' : 'Bir kez öde, hep senin'}
                </button>
              )}
            </div>
          );
        })}
      </div>
      <p className="muted" style={{ marginTop: 18, fontSize: '0.85rem' }}>
        Yinelenen ücret yok; satın alınan paketler kalıcıdır. Şu an <strong>demo ödeme</strong>{' '}
        modundadır — gerçek tahsilat yapılmaz (üretimde web-first sağlayıcı bağlanır; bkz.
        ENV_SETUP_GUIDE).
      </p>
    </div>
  );
}
