import { test, expect } from '@playwright/test';

test('trafik işaretleri galerisi: kategori filtresi + arama + flip', async ({ page }) => {
  await page.goto('/isaretler');
  const gallery = page.getByTestId('signs-gallery');
  await expect(gallery).toBeVisible();
  const cards = page.getByTestId('sign-card');
  expect(await cards.count()).toBeGreaterThan(30);

  // kategori filtresi
  await page.getByTestId('cat-yasak').click();
  await expect(cards.first()).toBeVisible();
  const yasakCount = await cards.count();
  expect(yasakCount).toBeGreaterThan(0);

  // arama
  await page.getByTestId('cat-all').click();
  await page.getByTestId('sign-search').fill('dur');
  await expect(page.getByRole('img', { name: 'DUR', exact: true })).toBeVisible();

  // flip: karta dokun → anlam görünür
  const card = cards.first();
  await card.click();
  await expect(card).toHaveAttribute('aria-pressed', 'true');
});

test('trafik dersinden işaret galerisine bağlantı', async ({ page }) => {
  await page.goto('/dersler/trafik-isaretleri');
  await expect(page.getByRole('link', { name: /İşaret galerisi/ })).toBeVisible();
});

test('araç tanıma: bileşen kartları + görseller (sistemlere göre)', async ({ page }) => {
  await page.goto('/arac');
  await expect(page.getByTestId('arac')).toBeVisible();
  const parts = page.getByTestId('vehicle-part');
  expect(await parts.count()).toBeGreaterThan(15);
  await expect(page.getByRole('img', { name: 'Akü' })).toBeVisible();
  await expect(page.getByTestId('vsys-motor-bolmesi')).toBeVisible();
});
