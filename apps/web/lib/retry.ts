/**
 * Yeniden deneme stratejisi (Sprint 4 / ROADMAP Faz 31) — dış çağrılar (ödeme/e-posta API)
 * için üstel geri çekilme. Saf ve test edilebilir (sleep enjekte edilir).
 */
export interface RetryOptions {
  retries?: number; // ek deneme sayısı (toplam = retries + 1)
  baseMs?: number;
  factor?: number;
  shouldRetry?: (err: unknown) => boolean;
  sleep?: (ms: number) => Promise<void>;
}

const defaultSleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

export async function withRetry<T>(fn: () => Promise<T>, opts: RetryOptions = {}): Promise<T> {
  const retries = opts.retries ?? 2;
  const baseMs = opts.baseMs ?? 200;
  const factor = opts.factor ?? 2;
  const shouldRetry = opts.shouldRetry ?? (() => true);
  const sleep = opts.sleep ?? defaultSleep;

  let lastErr: unknown;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      if (attempt === retries || !shouldRetry(err)) break;
      await sleep(baseMs * Math.pow(factor, attempt));
    }
  }
  throw lastErr;
}
