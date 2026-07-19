import { test, expect, type Page } from '@playwright/test';

/**
 * FINAL SPRINT — ödeme kök-neden regresyon kilidi.
 * Kök neden: webhook `purchases` tablosuna yazıyordu ama istemci `ea:entitlements`'i yalnız
 * /api/state'ten senkronluyordu → paket asla otomatik açılmıyordu (manuel restore gerekiyordu).
 * Bu test: webhook → SONRAKİ yüklemede premium OTOMATİK açılır (restore YOK) + başarı açılışı.
 */

let n = 0;
const uniqueEmail = (p: string) => `${p}-${Date.now()}-${n++}@example.com`;
const PW = 'Test1234!';

async function registerUI(page: Page, email: string) {
  await page.goto('/giris');
  await page.getByTestId('tab-register').click();
  await page.getByTestId('name').fill('Ödeme Test');
  await page.getByTestId('email').fill(email);
  await page.getByTestId('password').fill(PW);
  await page.getByTestId('auth-submit').click();
  await page.waitForURL('**/panel');
}

test('webhook satın alma → sonraki yüklemede OTOMATİK premium (manuel restore GEREKMEZ)', async ({
  page,
}) => {
  // API ile kayıt: kullanıcı id'sini döner + oturum çerezini bağlama yazar (page.goto authed olur).
  const email = uniqueEmail('wh');
  const regRes = await page.request.post('/api/auth/register', {
    data: { email, password: PW, name: 'Ödeme Test' },
  });
  expect(regRes.status()).toBe(201);
  const userId = ((await regRes.json()) as { user?: { id?: string } }).user?.id;
  expect(userId).toBeTruthy();

  // Webhook'u simüle et (mock gateway: gövde doğrudan sipariş) → sunucuda purchases satırı oluşur.
  const whRes = await page.request.post('/api/webhooks/lemonsqueezy', {
    data: { productId: 'komple-b', userId, orderId: 'wh-e2e-' + userId, totalTRY: 449 },
  });
  expect(whRes.status()).toBe(200);

  // Uygulamayı aç → fullSync/reconcile → premium OTOMATİK açılır. Restore'a DOKUNMADAN.
  await page.goto('/fiyatlandirma');
  await expect(page.getByTestId('owned-komple-b')).toBeVisible();

  // Premium yeteneği gerçekten aktif: sınırsız deneme (kota engeli yok).
  await page.goto('/deneme-sinavi');
  await page.getByTestId('exam-start').click();
  await expect(page.getByTestId('exam-running')).toBeVisible();
});

test('mock satın alma → premium başarı açılışı BİR KEZ gösterilir (P9)', async ({ page }) => {
  await registerUI(page, uniqueEmail('popup'));
  await page.goto('/fiyatlandirma');
  await page.getByTestId('buy-komple-b').click();
  // Başarı açılışı görünür + gerçek açılan özellikleri listeler.
  const modal = page.getByTestId('premium-success');
  await expect(modal).toBeVisible();
  await expect(modal).toContainText('Premium Ailesine Hoş Geldin');
  await expect(modal).toContainText('AI Koç');
  // Kapat → tekrar yüklemede gösterilMEZ (bir kez).
  await page.getByTestId('premium-explore').click();
  await expect(modal).not.toBeVisible();
  await page.reload();
  await expect(page.getByTestId('premium-success')).not.toBeVisible();
  await expect(page.getByTestId('owned-komple-b')).toBeVisible();
});

test('P0: yeni hesap bayat localStorage yetkisini MİRAS ALMAZ', async ({ page }) => {
  // Aynı tarayıcıda önceki bir kullanıcıdan kalmış bayat yetki simüle et.
  await page.goto('/');
  await page.evaluate(() =>
    localStorage.setItem('ea:entitlements:v1', JSON.stringify(['komple-b']))
  );
  await registerUI(page, uniqueEmail('p0stale'));
  await page.goto('/fiyatlandirma');
  // Yeni kullanıcı komple-b'ye SAHİP OLMAMALI (sunucu authoritative reconcile).
  await expect(page.getByTestId('buy-komple-b')).toBeVisible();
  await expect(page.getByTestId('owned-komple-b')).toHaveCount(0);
});

test('P0: kullanıcı A satın alır → çıkış → kullanıcı B (aynı tarayıcı) premium miras ALMAZ', async ({
  page,
}) => {
  // A kayıt + satın al
  await registerUI(page, uniqueEmail('p0a'));
  await page.goto('/fiyatlandirma');
  await page.getByTestId('buy-komple-b').click();
  await expect(page.getByTestId('owned-komple-b')).toBeVisible();
  // A çıkış (kullanıcıya-özel veri temizlenir)
  await page.goto('/profil');
  await page.getByTestId('logout').click();
  await page.waitForTimeout(400);
  // B aynı tarayıcıda kayıt olur
  await registerUI(page, uniqueEmail('p0b'));
  await page.goto('/fiyatlandirma');
  await expect(page.getByTestId('buy-komple-b')).toBeVisible();
  await expect(page.getByTestId('owned-komple-b')).toHaveCount(0);
});
