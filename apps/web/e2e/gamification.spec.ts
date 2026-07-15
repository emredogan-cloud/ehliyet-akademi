import { test, expect } from '@playwright/test';

test('ilerleme panosu: XP/seviye + meydan okuma + ısı haritası + yolculuk + içgörüler + başarılar', async ({
  page,
}) => {
  await page.goto('/ilerleme');
  await expect(page.getByTestId('ilerleme')).toBeVisible();
  await expect(page.getByTestId('level-title')).toBeVisible();
  await expect(page.getByTestId('daily-challenge')).toBeVisible();
  await expect(page.getByRole('img', { name: /ısı haritası/i })).toBeVisible();
  await expect(page.getByTestId('journey')).toBeVisible();
  await expect(page.getByTestId('insights')).toBeVisible();
  await expect(page.getByTestId('ach-locked').first()).toBeVisible();
});

test('panel: akıllı dürtme bannerı görünür (veri yokken başlangıç)', async ({ page }) => {
  await page.goto('/panel');
  await expect(page.getByTestId('nudge')).toBeVisible();
});

test('davet: bağlantı kopyalanır', async ({ page, context }) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto('/ilerleme');
  await page.getByTestId('copy-ref').click();
  await expect(page.getByTestId('copy-ref')).toContainText('Kopyalandı');
});
