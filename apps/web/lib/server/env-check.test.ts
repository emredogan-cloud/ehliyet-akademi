import { describe, it, expect } from 'vitest';
import { checkEnv } from './env-check';
import { captureException, captureMessage, observabilityConfigured } from './observability';

describe('checkEnv (sır/ortam doğrulaması)', () => {
  it('üretim-dışı ortamda uyarı yok', () => {
    const r = checkEnv({ NODE_ENV: 'development' } as NodeJS.ProcessEnv);
    expect(r.ok).toBe(true);
    expect(r.warnings).toHaveLength(0);
  });

  it('üretimde eksik DATABASE_URL/RESEND uyarı üretir', () => {
    const r = checkEnv({ VERCEL: '1' } as unknown as NodeJS.ProcessEnv);
    expect(r.ok).toBe(false);
    expect(r.warnings.join(' ')).toMatch(/DATABASE_URL/);
    expect(r.warnings.join(' ')).toMatch(/RESEND_API_KEY/);
  });

  it('ödeme kısmen yapılandırıldıysa webhook sırrı zorunlu uyarısı', () => {
    const r = checkEnv({
      VERCEL: '1',
      DATABASE_URL: 'x',
      RESEND_API_KEY: 'x',
      NEXT_PUBLIC_SITE_URL: 'https://x',
      LEMONSQUEEZY_API_KEY: 'k',
    } as unknown as NodeJS.ProcessEnv);
    expect(r.warnings.join(' ')).toMatch(/WEBHOOK_SECRET/);
  });
});

describe('observability', () => {
  it('SENTRY_DSN yoksa yapılandırılmamış; captureException fırlatmaz', () => {
    expect(observabilityConfigured()).toBe(false);
    expect(() => captureException(new Error('test'), { where: 'unit' })).not.toThrow();
    expect(() => captureMessage('bilgi', {})).not.toThrow();
  });
});
