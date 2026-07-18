import { defineConfig, devices } from '@playwright/test';

const PORT = 3100;
const BASE_URL = `http://127.0.0.1:${PORT}`;

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  // E2E DB'si tek-iş-parçacıklı bellek-içi PGlite (webServer env). 12 çekirdekte varsayılan 6
  // worker onu doyurup 30 sn timeout flake'lerine yol açıyordu; 3 worker deterministik ve hızlı
  // (~11 sn). Süre DB-bağımlı olduğundan daha fazla worker hız kazandırmaz, yalnız çekişme ekler.
  workers: 3,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    // Çerez rızası önceden verilmiş sayılır → banner testleri obscure etmez.
    // (Banner'ın kendisi cerez.spec.ts'te rıza temizlenip yeniden yüklenerek test edilir.)
    storageState: './e2e/storage-state.json',
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
    // RATE_LIMIT_DISABLED: e2e'de çok sayıda kayıt/istek hız sınırına takılmasın (çekirdek birim testli).
    // Aşağıdaki boş/override değişkenler LOKAL e2e'yi CI ile eşitler (CI'da bu gerçek servis
    // anahtarları yoktur). Next.js .env.local'i yalnız TANIMSIZ değişkenlere uygular; boş string
    // tanımlı sayılır ve .env.local değeri EZİLMEZ → deterministik, izole, hızlı çalışma:
    //   ANTHROPIC_API_KEY='' → AI Koç deterministik MockModel (gerçek API ~5 sn/istek + rate-limit
    //     e2e'yi flaky yapıyordu). Gerçek AI entegrasyonu integration testte doğrulanır.
    //   DATABASE_URL='' + PGLITE_DIR='memory://' → gerçek Neon yerine taze bellek-içi PGlite.
    //     Neon ağ gecikmesi istemci debounce/senkron zamanlamasını bozuyor, kalıcı .pglite ise
    //     çalışmalar-arası durum biriktiriyordu (restore flake). Gerçek Neon yazma→okuma akışları
    //     ayrıca curl + integration testle doğrulandı (kayıt, /api/state, içerik hattı hepsi çalışır).
    env: {
      ADMIN_EMAIL_PATTERN: '^admin-e2e-',
      RATE_LIMIT_DISABLED: '1',
      ANTHROPIC_API_KEY: '',
      DATABASE_URL: '',
      PGLITE_DIR: 'memory://',
    },
  },
});
