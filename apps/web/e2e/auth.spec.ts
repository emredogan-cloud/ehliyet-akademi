import { test, expect, type Page } from '@playwright/test';

const PW = 'e2e-parola-123';
function uniqueEmail(tag: string): string {
  return `e2e-${tag}-${Date.now()}-${Math.floor(Math.random() * 1e6)}@ea.dev`;
}

async function registerUI(page: Page, email: string) {
  await page.goto('/giris');
  await page.getByTestId('tab-register').click();
  await page.getByTestId('name').fill('E2E Aday');
  await page.getByTestId('email').fill(email);
  await page.getByTestId('password').fill(PW);
  await page.getByTestId('auth-submit').click();
  await page.waitForURL('**/panel');
}

test('kayıt → panel; profil korumalı sayfada kullanıcıyı gösterir; oturum reload sonrası kalıcı', async ({
  page,
}) => {
  const email = uniqueEmail('reg');
  await registerUI(page, email);
  await page.goto('/profil');
  await expect(page.getByTestId('profile-email')).toHaveText(email);
  await page.reload();
  await expect(page.getByTestId('profile-email')).toHaveText(email); // çerez oturumu
});

test('korumalı /profil: oturumsuz giriş CTA', async ({ page }) => {
  await page.goto('/profil');
  await expect(page.getByTestId('profile-guest')).toBeVisible();
  await page.getByTestId('go-login').click();
  await expect(page).toHaveURL(/\/giris/);
});

test('cihazlar-arası senkron: cihaz A çalışır → cihaz B girişte ilerlemeyi görür', async ({
  browser,
}) => {
  const email = uniqueEmail('sync');

  // Cihaz A: kayıt + 2 pratik cevabı
  const ctxA = await browser.newContext();
  const a = await ctxA.newPage();
  await registerUI(a, email);
  await a.goto('/calis');
  for (let k = 0; k < 2; k++) {
    await a.getByTestId('p-option').first().click();
    await a.getByTestId('p-next').click();
  }
  await a.waitForTimeout(700); // debounce push
  await ctxA.close();

  // Cihaz B: taze bağlam (boş localStorage) → giriş → panelde ilerleme görünür
  const ctxB = await browser.newContext();
  const b = await ctxB.newPage();
  await b.goto('/giris');
  await b.getByTestId('email').fill(email);
  await b.getByTestId('password').fill(PW);
  await b.getByTestId('auth-submit').click();
  await b.waitForURL('**/panel');
  await expect(b.getByTestId('dashboard')).toBeVisible();
  // cevaplanan soru istatistiği > 0 (senkron kanıtı)
  await expect(b.getByText('Cevaplanan soru')).toBeVisible();
  const stat = b.locator('.stat-tile__num').nth(2);
  await expect(stat).not.toHaveText('0');
  await ctxB.close();
});

test('kalıcı satın alma: girişli satın al → başka cihazda restore ile geri gelir', async ({
  browser,
}) => {
  const email = uniqueEmail('buy');

  const ctxA = await browser.newContext();
  const a = await ctxA.newPage();
  await registerUI(a, email);
  await a.goto('/fiyatlandirma');
  await a.getByTestId('buy-simulator-paketi').click();
  await expect(a.getByTestId('owned-simulator-paketi')).toBeVisible();
  await ctxA.close();

  const ctxB = await browser.newContext();
  const b = await ctxB.newPage();
  await b.goto('/giris');
  await b.getByTestId('email').fill(email);
  await b.getByTestId('password').fill(PW);
  await b.getByTestId('auth-submit').click();
  await b.waitForURL('**/panel');
  await b.goto('/profil');
  await b.getByTestId('restore').click();
  await expect(b.getByTestId('restore-msg')).toContainText('geri yüklendi');
  await b.goto('/fiyatlandirma');
  await expect(b.getByTestId('owned-simulator-paketi')).toBeVisible();
  await ctxB.close();
});

test('çıkış: oturum düşer, profil misafir olur', async ({ page }) => {
  const email = uniqueEmail('out');
  await registerUI(page, email);
  await page.goto('/profil');
  await page.getByTestId('logout').click();
  await page.waitForURL('**/panel');
  await page.goto('/profil');
  await expect(page.getByTestId('profile-guest')).toBeVisible();
});
