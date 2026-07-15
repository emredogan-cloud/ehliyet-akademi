import { test, expect } from '@playwright/test';

test('yasal sayfalar yayında (gizlilik/ToS/çerez/KVKK)', async ({ page }) => {
  for (const slug of ['gizlilik', 'kullanim-kosullari', 'cerez-politikasi', 'kvkk']) {
    await page.goto(`/${slug}`);
    await expect(page.getByTestId(`legal-${slug}`)).toBeVisible();
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
  }
});

test('marketing footer yasal bağlantıları içerir', async ({ page }) => {
  await page.goto('/');
  const footer = page.locator('footer.site');
  await expect(footer.getByRole('link', { name: 'KVKK' })).toBeVisible();
  await expect(footer.getByRole('link', { name: 'Gizlilik' })).toBeVisible();
});

test('çerez rıza bannerı: görünür → kabul → kaybolur', async ({ page }) => {
  await page.goto('/panel');
  // Test ortamı rızayı önceden veriyor; bannerı görmek için temizle + yeniden yükle.
  await page.evaluate(() => localStorage.removeItem('ea:consent'));
  await page.reload();
  const banner = page.getByTestId('cookie-consent');
  await expect(banner).toBeVisible();
  await page.getByTestId('consent-accept').click();
  await expect(banner).toHaveCount(0);
});

test('premium ders: kilitli → demo satın alma → kilit açılır', async ({ page }) => {
  await page.goto('/dersler/park-manevra');
  await expect(page.getByTestId('premium-locked')).toBeVisible();

  await page.getByTestId('premium-unlock').click();
  await expect(page.getByTestId('purchase-dialog')).toBeVisible();
  await page.getByTestId('purchase-buy').click();

  // Demo grant sonrası kilit kalkar ve ders içeriği (alıştırma/tekrar) görünür.
  await expect(page.getByTestId('premium-locked')).toHaveCount(0);
  await expect(page.getByText('Alıştırma soruları')).toBeVisible();
});

test('ayarlar: misafirde hesap bölümü giriş çağrısı + yasal bağlantılar', async ({ page }) => {
  await page.goto('/ayarlar');
  await expect(page.getByRole('link', { name: 'KVKK Aydınlatma Metni' })).toBeVisible();
  await expect(page.getByTestId('consent-off')).toBeVisible();
});
