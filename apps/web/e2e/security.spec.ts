import { test, expect } from '@playwright/test';

test('güvenlik başlıkları + CSP yanıtta bulunur', async ({ page }) => {
  const res = await page.goto('/');
  const h = res!.headers();
  expect(h['content-security-policy']).toContain("default-src 'self'");
  expect(h['content-security-policy']).toContain("frame-ancestors 'none'");
  expect(h['x-frame-options']).toBe('DENY');
  expect(h['x-content-type-options']).toBe('nosniff');
  expect(h['referrer-policy']).toBe('strict-origin-when-cross-origin');
  expect(h['strict-transport-security']).toContain('max-age');
  expect(h['x-powered-by']).toBeUndefined();
});

test('sağlık kontrolü ucu 200 + status ok', async ({ page }) => {
  const res = await page.request.get('/api/health');
  expect(res.status()).toBe(200);
  const d = (await res.json()) as { status: string };
  expect(d.status).toBe('ok');
});

test('CSRF: çapraz-origin mutating istek 403', async ({ page }) => {
  const res = await page.request.post('/api/ai/ask', {
    headers: { origin: 'https://evil.example', 'content-type': 'application/json' },
    data: { question: 'DUR levhasında ne yapılır?' },
  });
  expect(res.status()).toBe(403);
});

test('AI Koç: grounded sunucu yanıtı + sınav hazırlığı aksiyonu', async ({ page }) => {
  await page.goto('/ai-koc');
  await page.getByTestId('coach-action-readiness').click();
  await expect(page.getByTestId('msg-ai')).toContainText('Hazırlık skorun');
});
