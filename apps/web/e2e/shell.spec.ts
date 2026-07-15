import { test, expect } from '@playwright/test';

test('uygulama kabuğu: kalıcı sidebar + aktif durum + gezinme', async ({ page }) => {
  await page.goto('/panel');
  const sidebar = page.locator('#app-sidebar');
  await expect(sidebar).toBeVisible();
  await expect(sidebar.getByRole('link', { name: /Panel/ })).toHaveAttribute(
    'aria-current',
    'page'
  );

  await sidebar.getByRole('link', { name: /Dersler/ }).click();
  await expect(page).toHaveURL(/\/dersler/);
  await expect(page.getByRole('heading', { name: 'Dersler' })).toBeVisible();
  await expect(sidebar.getByRole('link', { name: /Dersler/ })).toHaveAttribute(
    'aria-current',
    'page'
  );
});

test('mobil: çekmece açılır/kapanır', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/panel');
  const sidebar = page.locator('#app-sidebar');
  await expect(sidebar).not.toBeInViewport();
  await page.getByTestId('drawer-toggle').click();
  await expect(sidebar).toBeInViewport();
  await page.locator('.scrim').click();
  await expect(sidebar).not.toBeInViewport();
});

test('panel: skeleton sonrası istatistikler + hızlı aksiyonlar', async ({ page }) => {
  await page.goto('/panel');
  await expect(page.getByTestId('dashboard')).toBeVisible();
  await expect(page.getByText('Hazırlık skoru', { exact: true })).toBeVisible();
  await expect(page.getByText('Ders bazlı ustalık')).toBeVisible();
  await expect(page.getByRole('link', { name: /Akıllı çalışma/ })).toBeVisible();
});

test('AI koç: öneriye tıkla → kaynaklı yanıt + uyarı', async ({ page }) => {
  await page.goto('/ai-koc');
  await page.getByTestId('suggestion').first().click();
  await expect(page.getByTestId('msg-user')).toBeVisible();
  const ai = page.getByTestId('msg-ai');
  await expect(ai).toBeVisible();
  await expect(ai).toContainText('AI hata yapabilir');
});

test('arama: sonuç bulur ve boş durumu gösterir', async ({ page }) => {
  await page.goto('/arama');
  await page.getByTestId('search-input').fill('hız');
  await expect(page.getByTestId('search-questions')).toBeVisible();
  await page.getByTestId('search-input').fill('qqqqzzzz');
  await expect(page.getByTestId('search-empty')).toBeVisible();
});

test('ayarlar: koyu tema seç → data-theme uygulanır ve kalıcıdır', async ({ page }) => {
  await page.goto('/ayarlar');
  await page.getByTestId('theme-dark').click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.reload();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await page.getByTestId('theme-light').click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});

test('başarılar: rozetler listelenir (kilitli başlangıç)', async ({ page }) => {
  await page.goto('/basarilar');
  await expect(page.getByTestId('achievements')).toBeVisible();
  await expect(page.getByTestId('ach-locked').first()).toBeVisible();
});

test('vitrin (marketing) ayrı kabukta: topbar var, sidebar yok', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('link', { name: 'Uygulamayı Aç', exact: true })).toBeVisible();
  await expect(page.locator('#app-sidebar')).toHaveCount(0);
});
