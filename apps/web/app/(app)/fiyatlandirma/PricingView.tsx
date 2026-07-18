'use client';

/**
 * Fiyatlandırma görünümü (ref 028) — TEK PAKET modeli (FINAL SPRINT P1): yalnız Komple B
 * satın alınabilir. Ödeme dönüşünde (?checkout=success) sahiplik uzlaştırılır + premium başarı
 * açılışı gösterilir (P9). İş modeli/entitlement mimarisi korunur.
 */
import { useEffect, useRef, useState } from 'react';
import { PRODUCTS, type Product, unlockedFeatures } from '@/lib/products';
import { getPaymentProvider, loadEntitlements } from '@/lib/payments';
import { isAuthed, me, serverPurchase, reconcileEntitlements } from '@/lib/authClient';
import { startCheckout } from '@/lib/checkoutClient';
import { track } from '@/lib/analytics';
import { Card, Button, Badge, IconBadge, type Accent } from '@/components/ui/primitives';
import { Section, Stack } from '@/components/ui/layout';
import { QuizLayout } from '@/components/ui/quiz';
import { Callout } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';
import { PremiumSuccessDialog } from '@/components/PremiumSuccessDialog';

const PREMIUM_WELCOME_KEY = 'ea:premiumWelcomeShown:v1';

const BENEFITS: Array<{ icon: IconName; accent: Accent; title: string; text: string }> = [
  {
    icon: 'check-circle',
    accent: 'teal',
    title: 'Ömür boyu erişim',
    text: 'Bir kez öde, aldığın paketin tüm özelliklerine sınırsız süre eriş.',
  },
  {
    icon: 'shield',
    accent: 'green',
    title: 'Gizli ücret yok',
    text: 'Abonelik, yenileme veya iptal derdi yok. Tamamen senin.',
  },
  {
    icon: 'rocket',
    accent: 'blue',
    title: 'Sürekli güncellemeler',
    text: 'Komple pakette gelecek içerik güncellemeleri de dahildir.',
  },
];

function OwnedBadge({ productId }: { productId: string }) {
  return (
    <span
      className="ui-badge"
      style={{ ['--badge-accent' as string]: 'var(--accent-green)' }}
      data-testid={`owned-${productId}`}
    >
      ✓ Sahipsin — ömür boyu
    </span>
  );
}

export function PricingView({
  realPayments = false,
}: {
  /** Sunucudan: gerçek ödeme sağlayıcısı (LemonSqueezy) yapılandırıldı mı? */
  realPayments?: boolean;
}) {
  const [owned, setOwned] = useState<string[]>([]);
  const [msg, setMsg] = useState<string>('');
  const [busy, setBusy] = useState<string | null>(null);
  const [showPremium, setShowPremium] = useState(false);
  const returnedRef = useRef(false);

  /** Komple sahipse premium başarı açılışını BİR KEZ göster (P9). */
  function maybeShowPremium(list: string[]) {
    if (!list.includes('komple-b')) return;
    try {
      if (localStorage.getItem(PREMIUM_WELCOME_KEY)) return;
      localStorage.setItem(PREMIUM_WELCOME_KEY, '1');
    } catch {
      /* kota */
    }
    setShowPremium(true);
  }

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const isReturn = params.get('checkout') === 'success';
    if (!isReturn) {
      // Girişli kullanıcı için sahiplik SUNUCUDAN uzlaştırılır (purchases → entitlements) → webhook
      // ile alınan paket bu sayfada da hemen "Sahipsin" görünür (localStorage yarışına bağlı değil).
      void (async () => {
        await me();
        setOwned(isAuthed() ? await reconcileEntitlements() : loadEntitlements());
      })();
      return;
    }
    // ÖDEME DÖNÜŞÜ: sahipliği sunucudan uzlaştır (webhook gecikebilir → yeniden dener),
    // gelince premium açılışını göster. Kök neden düzeltmesinin görünen ucu.
    returnedRef.current = true;
    let cancelled = false;
    let tries = 0;
    setMsg('Satın alman doğrulanıyor…');
    void (async () => {
      await me();
      const poll = async () => {
        if (cancelled) return;
        const list = await reconcileEntitlements();
        setOwned(list);
        if (list.includes('komple-b')) {
          setMsg('');
          maybeShowPremium(list);
          window.history.replaceState({}, '', '/fiyatlandirma');
          return;
        }
        if (tries++ < 6) {
          setTimeout(() => void poll(), 1500);
        } else {
          setMsg(
            'Ödemen alındı. Premium erişimin birkaç dakika içinde açılır — istersen "Satın almayı geri yükle" ile hemen kontrol edebilirsin.'
          );
        }
      };
      await poll();
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function buy(p: Product) {
    setBusy(p.id);
    setMsg('');

    // GERÇEK ÖDEME: herkes ödeme oturumu üzerinden — girişli kullanıcı hosted checkout'a yönlenir,
    // sahiplik webhook ile yazılır; dönüşte ?checkout=success uzlaştırır; misafire giriş istenir.
    if (realPayments) {
      const res = await startCheckout(p.id);
      setBusy(null);
      if (res.needsLogin) {
        setMsg('Satın almak için önce giriş yapmalısın — paketin hesabına kalıcı yazılır.');
        window.location.href = '/giris';
        return;
      }
      if (!res.redirected) setMsg(res.message);
      return;
    }

    // MOCK/DEV: dürüst demo akışı (yerel geliştirme ve e2e).
    if (isAuthed()) {
      const list = await serverPurchase(p.id);
      setBusy(null);
      if (list) {
        setMsg(
          `${p.title} hesabına KALICI olarak tanımlandı (demo ödeme — tüm cihazlarında geçerli).`
        );
        setOwned(list);
        maybeShowPremium(list);
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
      const list = loadEntitlements();
      setOwned(list);
      maybeShowPremium(list);
    }
  }

  const komple = PRODUCTS.find((p) => p.id === 'komple-b');
  // TEK PAKET (P1): Komple B'nin açtığı GERÇEK özellikler (yeteneklerden) + kalıcı-erişim satırları.
  const kompleChecklist = komple
    ? [
        ...unlockedFeatures([komple.id]).map((f) => f.label),
        ...komple.features.filter((f) => f !== 'Yukarıdaki her şey dahil'),
      ]
    : [];

  return (
    <div>
      {showPremium && <PremiumSuccessDialog owned={owned} onClose={() => setShowPremium(false)} />}
      {msg && (
        <div className="explain" role="status" data-testid="pay-msg">
          {msg}
        </div>
      )}

      <QuizLayout
        main={
          <Stack gap="var(--sp-6)">
            {komple && (
              <Card
                accent="teal"
                glow
                data-testid={`product-${komple.id}`}
                style={{ textAlign: 'center', padding: 'var(--sp-8) var(--sp-6)' }}
              >
                <Badge accent="teal">
                  <Icon name="star" size={13} /> En avantajlı
                </Badge>
                <h2 style={{ margin: 'var(--sp-3) 0 var(--sp-1)', fontSize: 'var(--fs-xl)' }}>
                  {komple.title}
                </h2>
                <p style={{ margin: 0, color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                  Tek ödeme · Ömür boyu erişim
                </p>

                <div
                  style={{
                    marginTop: 'var(--sp-4)',
                    fontSize: 'var(--fs-3xl)',
                    fontWeight: 800,
                    color: 'var(--primary)',
                    lineHeight: 1.1,
                  }}
                >
                  {komple.priceTRY} ₺
                </div>
                <p
                  style={{
                    margin: 'var(--sp-1) 0 0',
                    color: 'var(--text-3)',
                    fontSize: 'var(--fs-sm)',
                  }}
                >
                  Tek seferlik ödeme
                </p>

                <p
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 'var(--sp-2)',
                    margin: 'var(--sp-3) 0 0',
                    color: 'var(--text-2)',
                    fontSize: 'var(--fs-sm)',
                  }}
                >
                  <span
                    style={{ color: 'var(--accent-green)', display: 'inline-flex' }}
                    aria-hidden
                  >
                    <Icon name="check-circle" size={16} />
                  </span>
                  Abonelik yok · Yenilenmez · İptal derdi yok
                </p>

                <div style={{ margin: 'var(--sp-5) 0 0' }} aria-hidden>
                  {/* Üretilmiş premium amblemi (ASSET A12 / 028-A) */}
                  <img
                    src="/assets/art/premium-emblem-3d.webp"
                    alt=""
                    className="premium-emblem premium-emblem--3d"
                    aria-hidden
                  />
                </div>

                <ul
                  className="exam-tips"
                  style={{ width: 'fit-content', margin: 'var(--sp-5) auto 0', textAlign: 'left' }}
                >
                  {kompleChecklist.map((f) => (
                    <li key={f}>
                      <span className="exam-tips__check" aria-hidden>
                        <Icon name="check-circle" size={15} />
                      </span>
                      {f}
                    </li>
                  ))}
                </ul>

                <div style={{ marginTop: 'var(--sp-6)' }}>
                  {owned.includes(komple.id) ? (
                    <OwnedBadge productId={komple.id} />
                  ) : (
                    <Button
                      variant="primary"
                      size="lg"
                      full
                      onClick={() => buy(komple)}
                      disabled={busy !== null}
                      data-testid={`buy-${komple.id}`}
                    >
                      {busy === komple.id ? 'İşleniyor…' : 'Hemen satın al'}
                    </Button>
                  )}
                </div>
                <p
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: 'var(--sp-1)',
                    margin: 'var(--sp-3) 0 0',
                    color: 'var(--text-3)',
                    fontSize: 'var(--fs-xs)',
                  }}
                >
                  <Icon name="shield" size={13} /> Güvenli ödeme altyapısı ile
                </p>
              </Card>
            )}

            <p
              style={{
                textAlign: 'center',
                color: 'var(--text-3)',
                fontSize: 'var(--fs-sm)',
                margin: 0,
              }}
            >
              Tek paket, tek ödeme — her şey dahil. Ayrı ayrı paket seçmene gerek yok.
            </p>
          </Stack>
        }
        aside={
          <>
            <Section title="Neden Tek Ödeme?">
              <Stack gap="var(--sp-4)">
                {BENEFITS.map((b) => (
                  <Card
                    key={b.title}
                    style={{ display: 'flex', gap: 'var(--sp-3)', alignItems: 'flex-start' }}
                  >
                    <IconBadge accent={b.accent} size="md">
                      <Icon name={b.icon} size={20} />
                    </IconBadge>
                    <div>
                      <strong style={{ display: 'block', fontSize: 'var(--fs-md)' }}>
                        {b.title}
                      </strong>
                      <span style={{ color: 'var(--text-2)', fontSize: 'var(--fs-sm)' }}>
                        {b.text}
                      </span>
                    </div>
                  </Card>
                ))}
              </Stack>
            </Section>
            <Callout tone="warn" title="Bu yatırım, ehliyet hedefin için atacağın en akıllı adım.">
              Başarıya giden yolculuk burada başlar!
            </Callout>
          </>
        }
      />

      <p style={{ marginTop: 'var(--sp-5)', color: 'var(--text-3)', fontSize: 'var(--fs-sm)' }}>
        {realPayments ? (
          <>
            Yinelenen ücret yok; satın alınan paketler kalıcıdır. Ödemeler{' '}
            <strong>LemonSqueezy</strong> güvenli altyapısıyla alınır; fatura e-postana gönderilir.
          </>
        ) : (
          <>
            Yinelenen ücret yok; satın alınan paketler kalıcıdır. Şu an <strong>demo ödeme</strong>{' '}
            modundadır — gerçek tahsilat yapılmaz (üretimde web-first sağlayıcı bağlanır; bkz.
            ENV_SETUP_GUIDE).
          </>
        )}
      </p>
    </div>
  );
}
