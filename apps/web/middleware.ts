import { NextResponse, type NextRequest } from 'next/server';

/**
 * CSRF koruması (ROADMAP Faz 30 · Sprint 5) — durum-değiştiren /api/* isteklerinde same-origin kontrolü.
 * Çerezler zaten SameSite=Lax (temel CSRF savunması); bu, derinlemesine savunma katmanıdır.
 * Webhook'lar HMAC imzasıyla doğrulanır ve harici origin'den gelir → muaf.
 * Origin başlığı yoksa (tarayıcı-dışı/sunucu-sunucu) CSRF riski yoktur → izin verilir.
 * Yalnız /api/* eşleşir; sayfalar etkilenmez (SSG korunur).
 */
const MUTATING = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

export function middleware(req: NextRequest): NextResponse {
  if (!MUTATING.has(req.method)) return NextResponse.next();
  if (req.nextUrl.pathname.startsWith('/api/webhooks/')) return NextResponse.next();

  const origin = req.headers.get('origin');
  if (origin) {
    const host = req.headers.get('host');
    try {
      if (new URL(origin).host !== host) {
        return NextResponse.json({ error: 'CSRF: geçersiz origin.' }, { status: 403 });
      }
    } catch {
      return NextResponse.json({ error: 'CSRF: geçersiz origin.' }, { status: 403 });
    }
  }
  return NextResponse.next();
}

export const config = { matcher: ['/api/:path*'] };
