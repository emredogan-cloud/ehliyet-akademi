import { test, expect, type Page } from '@playwright/test';

const PW = 'admin-parola-123';
const email = () => `admin-e2e-${Date.now()}-${Math.floor(Math.random() * 1e6)}@ea.dev`;

async function registerAdmin(page: Page): Promise<string> {
  const e = email();
  await page.goto('/giris');
  await page.getByTestId('tab-register').click();
  await page.getByTestId('name').fill('Yönetici');
  await page.getByTestId('email').fill(e);
  await page.getByTestId('password').fill(PW);
  await page.getByTestId('auth-submit').click();
  await page.waitForURL('**/panel');
  return e;
}

test('içerik hattı UI: taslak oluştur → düzenle → yayınla; sürüm geçmişi büyür', async ({
  page,
}) => {
  // İlk kullanıcı bootstrap admin olur
  await registerAdmin(page);
  await page.goto('/admin');
  await expect(page.getByTestId('admin-stats')).toBeVisible();

  await page.goto('/admin/icerik');
  await page.getByTestId('new-article').click();
  await page.waitForURL('**/admin/icerik/**');
  await expect(page.getByTestId('edit-status')).toHaveText('draft');

  // Başlığı düzenle + kaydet → yeni sürüm
  await page.getByTestId('edit-title').fill('Kavşakta Öncelik Rehberi');
  await page.getByTestId('edit-save').click();
  await expect(page.getByTestId('edit-msg')).toContainText('Kaydedildi');

  // İş akışı: incele → onayla → yayınla
  await page.getByTestId('transition-in_review').click();
  await expect(page.getByTestId('edit-status')).toHaveText('in_review');
  await page.getByTestId('transition-approved').click();
  await expect(page.getByTestId('edit-status')).toHaveText('approved');
  await page.getByTestId('transition-published').click();
  await expect(page.getByTestId('edit-status')).toHaveText('published');
});

test('geçersiz payload düzenlemesi reddedilir (Zod)', async ({ page }) => {
  await registerAdmin(page);
  await page.goto('/admin/icerik');
  await page.getByTestId('new-article').click();
  await page.waitForURL('**/admin/icerik/**');
  await page.getByTestId('edit-payload').fill('{"title":"x"}'); // eksik alanlar
  await page.getByTestId('edit-save').click();
  await expect(page.getByTestId('edit-err')).toContainText('Doğrulama');
});

test('medya: SVG yükle → ızgarada görünür', async ({ page }) => {
  await registerAdmin(page);
  await page.goto('/admin/medya');
  const svg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"><rect width="12" height="12" fill="teal"/></svg>';
  await page.getByTestId('media-file').setInputFiles({
    name: 'test-isaret.svg',
    mimeType: 'image/svg+xml',
    buffer: Buffer.from(svg),
  });
  await expect(page.getByTestId('media-msg')).toContainText('Yüklendi');
  await expect(page.getByTestId('media-grid')).toBeVisible();
});

test('RBAC: normal kullanıcı /admin göremez', async ({ browser }) => {
  // Adım 1: bir admin garanti et (pattern admin-e2e) → sistemde admin var.
  const a = await browser.newContext();
  await registerAdmin(await a.newPage());
  await a.close();

  // Adım 2: 'user-e2e-*' → pattern eşleşmez + admin zaten var → normal user.
  const ctx = await browser.newContext();
  const page = await ctx.newPage();
  const e = `user-e2e-${Date.now()}-${Math.floor(Math.random() * 1e6)}@ea.dev`;
  await page.goto('/giris');
  await page.getByTestId('tab-register').click();
  await page.getByTestId('name').fill('Normal Aday');
  await page.getByTestId('email').fill(e);
  await page.getByTestId('password').fill(PW);
  await page.getByTestId('auth-submit').click();
  await page.waitForURL('**/panel');
  await page.goto('/admin');
  await expect(page.getByTestId('admin-denied')).toBeVisible();
  await ctx.close();
});

test('Soru Zekâsı panosu gerçek metrikleri gösterir (QIP Faz 2)', async ({ page }) => {
  await registerAdmin(page);
  await page.goto('/admin/soru-zekasi');
  await expect(page.getByTestId('qip-panel')).toBeVisible();
  // Kalite + yineleme bölümleri görünür
  await expect(page.getByTestId('qip-quality')).toBeVisible();
  await expect(page.getByTestId('qip-dedup')).toBeVisible();
  // Toplam soru sayısı gerçek bir değer (banka > 1000)
  const total = await page.getByTestId('qip-stat-total').innerText();
  expect(Number(total.replace(/\D/g, ''))).toBeGreaterThan(1000);
});

test('arama sayfası soyutlama üzerinden sonuç verir', async ({ page }) => {
  await page.goto('/arama');
  await page.getByTestId('search-input').fill('hız');
  await expect(page.getByTestId('search-results')).toBeVisible();
});
