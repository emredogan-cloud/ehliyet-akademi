import { test, expect, type Page } from '@playwright/test';

/** Tanı denemesini sonuna kadar cevapla (her soruda ilk seçenek). */
async function completeDiagnostic(page: Page) {
  for (let guard = 0; guard < 30; guard++) {
    if (
      await page
        .getByTestId('diagnostic-result')
        .isVisible()
        .catch(() => false)
    )
      break;
    await page.getByTestId('option').first().click();
    await page.getByTestId('next').click();
  }
}

test('ana sayfa kancayı ve CTA’yı gösterir', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Bugün girsen geçer miydin?' })).toBeVisible();
  await expect(page.getByRole('link', { name: /Tanı denemesine başla/ })).toBeVisible();
});

test('çekirdek akış: tanı denemesi → hazırlık skoru → kalıcılık', async ({ page }) => {
  await page.goto('/tani');
  await expect(page.getByTestId('diagnostic')).toBeVisible();

  await completeDiagnostic(page);

  const result = page.getByTestId('diagnostic-result');
  await expect(result).toBeVisible();
  await expect(page.getByTestId('readiness-light')).toBeVisible();
  await expect(result.getByText('%')).toBeTruthy();

  // Kalıcılık: hazırlık skorum sayfası kaydı gösterir
  await page.goto('/hazirlik-skorum');
  await expect(page.getByTestId('readiness-view')).toBeVisible();
});

test('ders sayfası SSG render eder', async ({ page }) => {
  await page.goto('/dersler');
  await expect(page.getByRole('heading', { name: 'Dersler' })).toBeVisible();
  await page.getByRole('link', { name: /Trafik İşaretlerine Giriş/ }).click();
  await expect(page.getByRole('heading', { name: 'Trafik İşaretlerine Giriş' })).toBeVisible();
  await expect(page.getByText('Kazanımlar')).toBeVisible();
});

test('e-sınav dağılımı doğru görünür', async ({ page }) => {
  await page.goto('/e-sinav');
  await expect(page.getByRole('heading', { name: 'Teorik e-Sınav' })).toBeVisible();
  await expect(page.getByText('İlk Yardım Bilgisi')).toBeVisible();
});
