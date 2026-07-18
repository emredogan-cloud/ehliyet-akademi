import type { NextConfig } from 'next';

/**
 * İçerik Güvenlik Politikası (CSP · ROADMAP Faz 30 · Sprint 5).
 * SSG-uyumlu: nonce yok (nonce her isteği dinamikleştirir, SSG/performansı bozar) → statik CSP.
 * Not: React inline-style ve Next bootstrap/JSON-LD/tema inline-script'i 'unsafe-inline' gerektirir;
 * XSS savunması `mdBold`/`mdLite` HTML-escape + React varsayılan escaping + object/base/frame kısıtları
 * ile sağlanır. Analitik alan adları YALNIZCA ilgili ENV build'de set edildiğinde eklenir.
 */
function buildCsp(): string {
  const script = ["'self'", "'unsafe-inline'"];
  const connect = ["'self'"];
  const img = ["'self'", 'data:', 'blob:'];

  if (process.env.NEXT_PUBLIC_GA_ID) {
    script.push('https://www.googletagmanager.com');
    connect.push('https://*.google-analytics.com', 'https://*.analytics.google.com');
    img.push('https://*.google-analytics.com', 'https://www.googletagmanager.com');
  }
  if (process.env.NEXT_PUBLIC_CLARITY_ID) {
    script.push('https://www.clarity.ms', 'https://*.clarity.ms');
    connect.push('https://*.clarity.ms');
  }
  if (process.env.NEXT_PUBLIC_POSTHOG_KEY) {
    const host = process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://*.posthog.com';
    script.push(host);
    connect.push(host);
  }

  return [
    `default-src 'self'`,
    `base-uri 'self'`,
    `object-src 'none'`,
    `frame-ancestors 'none'`,
    `form-action 'self'`,
    `img-src ${img.join(' ')}`,
    `font-src 'self' data:`,
    `style-src 'self' 'unsafe-inline'`,
    `script-src ${script.join(' ')}`,
    `connect-src ${connect.join(' ')}`,
    `frame-src 'none'`,
    `manifest-src 'self'`,
    `worker-src 'self'`,
    `upgrade-insecure-requests`,
  ].join('; ');
}

const SECURITY_HEADERS = [
  { key: 'Content-Security-Policy', value: buildCsp() },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  {
    key: 'Permissions-Policy',
    value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
  },
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
];

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Yerel e2e/dev'de 127.0.0.1 ↔ localhost çapraz-origin uyarısını sustur.
  allowedDevOrigins: ['127.0.0.1', 'localhost'],
  // Workspace TS paketleri derlemeden kullanılır (ADR-002/005).
  transpilePackages: ['@ea/content-schema', '@ea/question-bank', '@ea/srs-engine', '@ea/db'],
  // Native/wasm sürücüler sunucu bundle'ına alınmaz (Faz 27):
  serverExternalPackages: ['@electric-sql/pglite', 'pg'],
  // Güvenlik başlıkları + CSP (ROADMAP Faz 30 · Sprint 5).
  async headers() {
    const immutable = 'public, max-age=31536000, immutable';
    return [
      { source: '/:path*', headers: SECURITY_HEADERS },
      { source: '/icon.svg', headers: [{ key: 'Cache-Control', value: 'public, max-age=86400' }] },
      // Statik içerik görselleri (124 webp) önceden max-age=0 idi → her yüklemede yeniden doğrulanıyordu.
      // İçerik-kararlı varlıklar (deploy ile versiyonlanır); uzun immutable cache (PERF).
      { source: '/assets/:path*', headers: [{ key: 'Cache-Control', value: immutable }] },
      { source: '/videos/:path*', headers: [{ key: 'Cache-Control', value: immutable }] },
    ];
  },
};

export default nextConfig;
