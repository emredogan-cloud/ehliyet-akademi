import { test, expect } from '@playwright/test';

/**
 * PROGRAM SEO regresyon kilidi. Canonical'ın sayfaya özel (self-referencing) olması, işaret
 * galerisinin gerçek <a href> ile detaya bağlanması, sitemap/robots kapsamı ve JSON-LD varlığı.
 */

test('her sayfa kendi self-canonical URL’ini verir (kök "/" hatası çözüldü)', async ({ page }) => {
  await page.goto('/');
  const homeCanon = await page.locator('link[rel="canonical"]').getAttribute('href');
  expect(homeCanon).toBeTruthy();

  await page.goto('/isaretler/dur');
  const signCanon = await page.locator('link[rel="canonical"]').getAttribute('href');
  expect(signCanon).toMatch(/\/isaretler\/dur$/);
  // Detay sayfası ana sayfaya kanonikleşMEMELİ (eski hata).
  expect(signCanon).not.toEqual(homeCanon);
});

test('işaret galerisi detay sayfalarına gerçek <a href> ile bağlanır (crawlable)', async ({
  page,
}) => {
  await page.goto('/isaretler');
  const link = page.getByTestId('sign-detail-link').first();
  await expect(link).toHaveAttribute('href', /^\/isaretler\/[a-z0-9-]+$/);
  // aria-pressed flip davranışı korunur.
  const card = page.getByTestId('sign-card').first();
  await card.click();
  await expect(card).toHaveAttribute('aria-pressed', 'true');
});

test('robots.txt indekslenmeyen alanları engeller + sitemap’i işaret eder', async ({ request }) => {
  const res = await request.get('/robots.txt');
  expect(res.status()).toBe(200);
  const body = await res.text();
  expect(body).toContain('Disallow: /admin');
  expect(body).toContain('Disallow: /api/');
  expect(body).toMatch(/Sitemap:\s*https?:\/\/\S+\/sitemap\.xml/);
});

test('sitemap tüm içerik detay sayfalarını içerir (>200 URL)', async ({ request }) => {
  const res = await request.get('/sitemap.xml');
  expect(res.status()).toBe(200);
  const xml = await res.text();
  const locs = xml.match(/<loc>/g) ?? [];
  expect(locs.length).toBeGreaterThan(200);
  expect(xml).toContain('/isaretler/dur');
  expect(xml).toMatch(/\/arac\/[a-z0-9-]+/);
  expect(xml).toMatch(/\/dersler\/[a-z0-9-]+/);
});

test('ana sayfa Organization + WebSite + FAQPage yapısal verisi taşır', async ({ page }) => {
  await page.goto('/');
  const blocks = await page.locator('script[type="application/ld+json"]').allTextContents();
  const joined = blocks.join(' ');
  expect(joined).toContain('"Organization"');
  expect(joined).toContain('"WebSite"');
  expect(joined).toContain('"SearchAction"');
  expect(joined).toContain('"FAQPage"');
  // Tüm bloklar geçerli JSON.
  for (const b of blocks) expect(() => JSON.parse(b)).not.toThrow();
});

test('işaret detay sayfası DefinedTerm + BreadcrumbList üretir', async ({ page }) => {
  await page.goto('/isaretler/dur');
  const joined = (await page.locator('script[type="application/ld+json"]').allTextContents()).join(
    ' '
  );
  expect(joined).toContain('"DefinedTerm"');
  expect(joined).toContain('"BreadcrumbList"');
});
