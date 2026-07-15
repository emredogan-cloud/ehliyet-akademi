import { test, expect } from '@playwright/test';

test('SRS pratik oturumu: 10 soru → tamamlama + seri', async ({ page }) => {
  await page.goto('/calis');
  await expect(page.getByTestId('practice')).toBeVisible();

  for (let guard = 0; guard < 15; guard++) {
    if (
      await page
        .getByTestId('practice-done')
        .isVisible()
        .catch(() => false)
    )
      break;
    await page.getByTestId('p-option').first().click();
    await page.getByTestId('p-next').click();
  }
  await expect(page.getByTestId('practice-done')).toBeVisible();
  await expect(page.getByText(/Seri:/)).toBeVisible();
});

test('e-Sınav simülatörü: başlat → 50 soru + süre → bitir → sonuç', async ({ page }) => {
  await page.goto('/deneme-sinavi');
  await expect(page.getByTestId('exam-intro')).toBeVisible();
  await page.getByTestId('exam-start').click();

  await expect(page.getByTestId('exam-running')).toBeVisible();
  await expect(page.getByTestId('exam-timer')).toContainText('44:'); // 45dk geri sayım başladı
  await expect(page.getByText('Soru 1/50')).toBeVisible();

  // Birkaç soru cevapla, soru haritasıyla gez, sonra teslim et
  await page.getByTestId('e-option').first().click();
  await page.getByTestId('e-next').click();
  await page.getByTestId('e-option').first().click();
  await page.getByTestId('exam-finish').click();

  await expect(page.getByTestId('exam-result')).toBeVisible();
  await expect(page.getByTestId('exam-verdict')).toBeVisible(); // GEÇTİN/KALDIN
  await expect(page.getByText('Ders bazlı sonuç')).toBeVisible();
});

test('ders görseli (SVG figür) render olur', async ({ page }) => {
  await page.goto('/dersler/trafik-isaretleri');
  await expect(page.getByRole('img', { name: 'Trafik işaret grupları' })).toBeVisible();
});

test('yeni dersler yayında: kavşak + trafik adabı', async ({ page }) => {
  await page.goto('/dersler');
  await expect(page.getByRole('link', { name: /Kavşaklar ve Geçiş Önceliği/ })).toBeVisible();
  await expect(page.getByRole('link', { name: /Trafik Adabı: Saygı/ })).toBeVisible();
});
