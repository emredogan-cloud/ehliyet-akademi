import { defineConfig, devices } from '@playwright/test';

const PORT = 3100;
const BASE_URL = `http://127.0.0.1:${PORT}`;

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    // Production build + start: PGlite native-ESM yüklemesi ve gerçek runtime davranışı
    // (dev bundler farklılıklarından bağımsız, CI ile birebir).
    command: `pnpm run build && pnpm exec next start --port ${PORT}`,
    url: BASE_URL,
    reuseExistingServer: !process.env.CI,
    timeout: 240_000,
    // E2E: 'admin-e2e-*' e-postaları admin olur (deterministik RBAC). Prod'da kullanılmaz.
    env: { ADMIN_EMAIL_PATTERN: '^admin-e2e-' },
  },
});
