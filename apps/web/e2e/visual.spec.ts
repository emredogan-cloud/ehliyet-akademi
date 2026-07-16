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

test('ders içi görsel bloklar: callout + karşılaştırma tablosu (Bölüm D)', async ({ page }) => {
  await page.goto('/dersler/trafik-isaretleri');
  // Karşılaştırma tablosu (DUR / Yol Ver, renk-şekil) görünür
  const table = page.locator('table.cmp').first();
  await expect(table).toBeVisible();
  await expect(table.getByText('Tehlike uyarısı')).toBeVisible();
  // Callout vurgu kutusu görünür
  await expect(page.locator('.callout').first()).toBeVisible();
  await expect(page.getByText('Sınavda ağır kusur')).toBeVisible();
});

test('premium boş durum: işaret araması sonuç yoksa', async ({ page }) => {
  await page.goto('/isaretler');
  await page.getByTestId('sign-search').fill('zzzxyq');
  await expect(page.getByTestId('signs-empty')).toBeVisible();
  await expect(page.getByText(/bulunamadı/)).toBeVisible();
});

test('araç tanıma: bileşen kartları + görseller (sistemlere göre)', async ({ page }) => {
  await page.goto('/arac');
  await expect(page.getByTestId('arac')).toBeVisible();
  const parts = page.getByTestId('vehicle-part');
  expect(await parts.count()).toBeGreaterThan(25);
  await expect(page.getByTestId('vsys-motor-bolmesi')).toBeVisible();
});

test('premium fotoğraflar: /arac foto kartları + şema aç/kapa (Program 2 · Faz 1)', async ({
  page,
}) => {
  await page.goto('/arac');
  // Premium foto kartları render edilir
  const photos = page.getByTestId('asset-image');
  expect(await photos.count()).toBeGreaterThan(25);
  // Akü fotosu erişilebilir alt metniyle görünür
  await expect(
    page.getByRole('img', { name: 'Motor bölmesindeki araç aküsü ve kutup başları' })
  ).toBeVisible();
  // Çizim şeması <details> ile açılabilir
  const toggle = page.getByTestId('diagram-toggle').first();
  await toggle.scrollIntoViewIfNeeded();
  await toggle.click();
  await expect(page.getByRole('img', { name: 'Motor Bölmesi' }).first()).toBeVisible();
});

test('ders sayfası premium foto şeridi (Program 2 · Faz 1)', async ({ page }) => {
  await page.goto('/dersler/motor-temel');
  const strip = page.getByTestId('lesson-photos');
  await expect(strip).toBeVisible();
  expect(await strip.getByTestId('asset-image').count()).toBeGreaterThanOrEqual(3);
});

test('etkileşimli hotspot turu: aç/kapa + klavye (Program 2 · Faz 2)', async ({ page }) => {
  await page.goto('/dersler/motor-temel');
  const hotspots = page.getByTestId('hotspots');
  await hotspots.scrollIntoViewIfNeeded();
  await expect(hotspots).toBeVisible();
  // Nokta tıkla → açıklama balonu açılır
  await page.getByTestId('hotspot-0').click();
  const pop = page.getByTestId('hotspot-pop');
  await expect(pop).toBeVisible();
  await expect(pop).toContainText('Soğutma Suyu');
  // Escape kapatır (klavye erişilebilirliği)
  await page.keyboard.press('Escape');
  await expect(pop).not.toBeVisible();
});

test('adım akışı + karşılaştırma kaydırıcısı (Program 2 · Faz 2)', async ({ page }) => {
  await page.goto('/dersler/arac-hazirlik');
  // Adım akışı: ileri git → ilerleme değişir
  const flow = page.getByTestId('stepflow');
  await flow.scrollIntoViewIfNeeded();
  await expect(flow).toBeVisible();
  await expect(page.getByTestId('stepflow-progress')).toHaveText('1 / 7');
  await page.getByTestId('stepflow-next').click();
  await expect(page.getByTestId('stepflow-progress')).toHaveText('2 / 7');
  await expect(page.getByTestId('stepflow-title')).toContainText('Lastikler');
  // Karşılaştırma kaydırıcısı: range klavye/fill ile hareket eder
  const range = page.getByTestId('compare-range');
  await range.scrollIntoViewIfNeeded();
  await range.fill('20');
  await expect(range).toHaveValue('20');
  await expect(page.getByTestId('compare-slider')).toContainText('1,6 mm');
});

test('eğitsel animasyon: oynat/duraklat + baştan (Program 2 · Faz 3)', async ({ page }) => {
  await page.goto('/dersler/kavsak-oncelik');
  const anim = page.getByTestId('anim-right-of-way');
  await anim.scrollIntoViewIfNeeded();
  await expect(anim).toBeVisible();
  // Sahne SVG'si erişilebilir etiketle render edilir
  await expect(anim.getByRole('img', { name: /Kavşak animasyonu/ })).toBeVisible();
  // Duraklat → stage paused durumuna geçer
  const stage = anim.locator('.animp__stage');
  await expect(stage).toHaveAttribute('data-playing', 'true');
  await anim.getByTestId('anim-toggle').click();
  await expect(stage).toHaveAttribute('data-playing', 'false');
  // Baştan → yeniden oynar
  await anim.getByTestId('anim-restart').click();
  await expect(stage).toHaveAttribute('data-playing', 'true');
  // Adım metinleri her zaman görünür (reduced-motion bilgi eşdeğerliği)
  await expect(anim.locator('.animp__steps li')).toHaveCount(4);
});

test('/arac interaktif keşif: hotspot + zoom inceleme (Program 2 · Faz 2)', async ({ page }) => {
  await page.goto('/arac');
  await expect(page.getByTestId('hotspots')).toBeVisible();
  // Zoom aç → overlay; kapat → kaybolur
  const opener = page.getByTestId('zoom-open');
  await opener.scrollIntoViewIfNeeded();
  await opener.click();
  await expect(page.getByTestId('zoom-overlay')).toBeVisible();
  await page.getByTestId('zoom-close').click();
  await expect(page.getByTestId('zoom-overlay')).not.toBeVisible();
});
