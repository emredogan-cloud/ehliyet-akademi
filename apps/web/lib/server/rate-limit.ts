/**
 * Hız sınırlama (Sprint 4 / ROADMAP Faz 30) — bellek-içi sabit-pencere sayaç.
 * Çekirdek `rateLimit` saf ve test edilebilir (now enjekte edilir). Serverless'te sayaç
 * örnek-başınadır (kabul edilen taban); ölçekte Upstash/Redis adaptörü aynı arayüzle takılır.
 */
export interface RateLimitResult {
  ok: boolean;
  remaining: number;
  resetMs: number;
}

interface Bucket {
  count: number;
  resetAt: number;
}
const buckets = new Map<string, Bucket>();

/** Anahtar için pencere içinde `limit` isteğe izin ver. Saf: durum `store`ta tutulur. */
export function rateLimit(
  key: string,
  limit: number,
  windowMs: number,
  now: number = Date.now(),
  store: Map<string, Bucket> = buckets
): RateLimitResult {
  const b = store.get(key);
  if (!b || b.resetAt <= now) {
    store.set(key, { count: 1, resetAt: now + windowMs });
    return { ok: true, remaining: limit - 1, resetMs: windowMs };
  }
  b.count += 1;
  const remaining = Math.max(0, limit - b.count);
  return { ok: b.count <= limit, remaining, resetMs: b.resetAt - now };
}

/** İstemci IP'si (proxy başlıklarından; yoksa 'local'). */
export function clientIp(req: Request): string {
  const xf = req.headers.get('x-forwarded-for');
  if (xf) return xf.split(',')[0]!.trim();
  return req.headers.get('x-real-ip') ?? 'local';
}

/**
 * Handler kapısı: sınır aşıldıysa 429 Response döner, aksi halde null.
 * `bucket` çağrı türünü ayırır (login/register/checkout…).
 */
export function checkRateLimit(
  req: Request,
  opts: { bucket: string; limit: number; windowMs: number }
): Response | null {
  // Test/e2e kaçış kapısı: çekirdek `rateLimit` yine birim testlerle doğrulanır.
  if (process.env.NODE_ENV === 'test' || process.env.RATE_LIMIT_DISABLED === '1') return null;
  const key = `${opts.bucket}:${clientIp(req)}`;
  const r = rateLimit(key, opts.limit, opts.windowMs);
  if (r.ok) return null;
  return new Response(
    JSON.stringify({ error: 'Çok fazla istek. Lütfen biraz sonra tekrar deneyin.' }),
    {
      status: 429,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'retry-after': String(Math.ceil(r.resetMs / 1000)),
      },
    }
  );
}

/** Test yardımcısı: tüm sayaçları sıfırla. */
export function _resetRateLimits(): void {
  buckets.clear();
}
