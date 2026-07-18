import { test, expect } from '@playwright/test';

test('fiyatlandırma: tek-seferlik model — satın al (mock) → sahiplik', async ({ page }) => {
  await page.goto('/fiyatlandirma');
  await expect(page.getByRole('heading', { name: 'Fiyatlandırma' })).toBeVisible();
  await expect(page.getByText('Abonelik yok.')).toBeVisible();

  // Komple paketi mock-checkout ile al
  await page.getByTestId('buy-komple-b').click();
  await expect(page.getByTestId('pay-msg')).toContainText('demo ödeme');
  await expect(page.getByTestId('owned-komple-b')).toBeVisible();

  // Yenile → sahiplik kalıcı (localStorage entitlement)
  await page.reload();
  await expect(page.getByTestId('owned-komple-b')).toBeVisible();
});

test('ücretsiz kota: günde 1 deneme; 2.si paket önerir; paket → sınırsız', async ({ page }) => {
  // 1. deneme serbest
  await page.goto('/deneme-sinavi');
  await page.getByTestId('exam-start').click();
  await expect(page.getByTestId('exam-running')).toBeVisible();
  await page.getByTestId('exam-finish').click();
  await expect(page.getByTestId('exam-result')).toBeVisible();

  // 2. deneme (aynı gün) → kota mesajı
  await page.getByRole('button', { name: 'Yeni deneme' }).click();
  await expect(page.getByTestId('exam-quota')).toBeVisible();
  await expect(page.getByTestId('exam-quota')).toContainText('Komple B');

  // Komple paketi al → artık sınırsız (tek paket modeli)
  await page.goto('/fiyatlandirma');
  await page.getByTestId('buy-komple-b').click();
  await expect(page.getByTestId('owned-komple-b')).toBeVisible();
  await page.goto('/deneme-sinavi');
  await page.getByTestId('exam-start').click();
  await expect(page.getByTestId('exam-running')).toBeVisible();
});
