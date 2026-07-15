import { json } from '@/lib/server/auth';

/**
 * Sağlık kontrolü (ROADMAP Faz 31 · Sprint 5) — izleme/uptime probu için.
 * DB'ye dokunmaz (Vercel'de DATABASE_URL yoksa hata fırlatmasın): yalnız yapılandırma raporu.
 */
export function GET(): Response {
  const db = process.env.DATABASE_URL
    ? 'configured'
    : process.env.VERCEL
      ? 'unconfigured'
      : 'pglite';
  return json(
    {
      status: 'ok',
      service: 'ehliyet-akademi',
      db,
      email: process.env.RESEND_API_KEY ? 'resend' : 'console',
      payments: process.env.LEMONSQUEEZY_API_KEY ? 'lemonsqueezy' : 'mock',
    },
    { headers: { 'cache-control': 'no-store' } }
  );
}
