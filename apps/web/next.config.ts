import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Yerel e2e/dev'de 127.0.0.1 ↔ localhost çapraz-origin uyarısını sustur.
  allowedDevOrigins: ['127.0.0.1', 'localhost'],
  // Workspace TS paketleri derlemeden kullanılır (ADR-002/005).
  transpilePackages: ['@ea/content-schema', '@ea/question-bank', '@ea/srs-engine'],
  // Güvenlik başlıkları (ROADMAP Faz 30 temeli).
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
        ],
      },
    ];
  },
};

export default nextConfig;
