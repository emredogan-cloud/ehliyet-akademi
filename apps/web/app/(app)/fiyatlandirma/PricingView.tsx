'use client';

/**
 * Fiyatlandırma görünümü (ref 028) — SALT SUNUM yenilemesi.
 * İş modeli aynen korunur: TEK-SEFERLİK satın alma, 5 gerçek paket, demo ödeme.
 * Satın alma mantığı components/Pricing.tsx ile birebir aynıdır (lib katmanı ortak).
 */
import { useEffect, useState } from 'react';
import { PRODUCTS, type Product } from '@/lib/products';
import { getPaymentProvider, loadEntitlements } from '@/lib/payments';
import { isAuthed, me, serverPurchase } from '@/lib/authClient';
import { track } from '@/lib/analytics';
import { Card, Button, Badge, IconBadge, type Accent } from '@/components/ui/primitives';
import { Section, Grid, Stack } from '@/components/ui/layout';
import { QuizLayout } from '@/components/ui/quiz';
import { Callout } from '@/components/ui/patterns';
import { Icon, type IconName } from '@/components/ui/icons';

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

export function PricingView() {
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

  const komple = PRODUCTS.find((p) => p.id === 'komple-b');
  const singles = PRODUCTS.filter((p) => p.id !== 'komple-b');
  // Komple paketin gerçek kapsamı: tekil paketlerin tümü + kendi ek özellikleri
  // ("Yukarıdaki her şey dahil" satırı, tekil paket adlarıyla açık yazılır).
  const kompleChecklist = komple
    ? [
        ...singles.map((p) => `${p.title} dahil`),
        ...komple.features.filter((f) => f !== 'Yukarıdaki her şey dahil'),
      ]
    : [];

  return (
    <div>
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
                    src="/assets/ui/premium-banner.webp"
                    alt=""
                    className="premium-emblem"
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

            <Section title="Tekil paketler" icon={<Icon name="layers" size={18} />}>
              <Grid preset="cards">
                {singles.map((p) => {
                  const has = owned.includes(p.id);
                  return (
                    <Card
                      key={p.id}
                      data-testid={`product-${p.id}`}
                      style={{ display: 'flex', flexDirection: 'column', gap: 'var(--sp-2)' }}
                    >
                      <h3 style={{ margin: 0, fontSize: 'var(--fs-md)' }}>{p.title}</h3>
                      <p style={{ margin: 0, color: 'var(--text-3)', fontSize: 'var(--fs-xs)' }}>
                        {p.blurb}
                      </p>
                      <div
                        style={{
                          fontSize: 'var(--fs-xl)',
                          fontWeight: 800,
                          color: 'var(--primary)',
                        }}
                      >
                        {p.priceTRY} ₺{' '}
                        <span
                          style={{
                            color: 'var(--text-3)',
                            fontSize: 'var(--fs-xs)',
                            fontWeight: 500,
                          }}
                        >
                          · tek seferlik
                        </span>
                      </div>
                      <ul className="exam-tips">
                        {p.features.map((f) => (
                          <li key={f}>
                            <span className="exam-tips__check" aria-hidden>
                              <Icon name="check-circle" size={15} />
                            </span>
                            {f}
                          </li>
                        ))}
                      </ul>
                      <div style={{ marginTop: 'auto', paddingTop: 'var(--sp-2)' }}>
                        {has ? (
                          <OwnedBadge productId={p.id} />
                        ) : (
                          <Button
                            variant="soft"
                            accent="teal"
                            size="sm"
                            full
                            onClick={() => buy(p)}
                            disabled={busy !== null}
                            data-testid={`buy-${p.id}`}
                          >
                            {busy === p.id ? 'İşleniyor…' : 'Satın al'}
                          </Button>
                        )}
                      </div>
                    </Card>
                  );
                })}
              </Grid>
            </Section>
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
        Yinelenen ücret yok; satın alınan paketler kalıcıdır. Şu an <strong>demo ödeme</strong>{' '}
        modundadır — gerçek tahsilat yapılmaz (üretimde web-first sağlayıcı bağlanır; bkz.
        ENV_SETUP_GUIDE).
      </p>
    </div>
  );
}
