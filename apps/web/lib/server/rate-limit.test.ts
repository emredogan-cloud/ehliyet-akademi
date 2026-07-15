import { describe, it, expect } from 'vitest';
import { rateLimit } from './rate-limit';

describe('rateLimit (çekirdek)', () => {
  it('pencere içinde limite kadar izin verir, sonra reddeder', () => {
    const store = new Map();
    const now = 1_000_000;
    const results = [1, 2, 3].map(() => rateLimit('k', 3, 60_000, now, store));
    expect(results.every((r) => r.ok)).toBe(true);
    const fourth = rateLimit('k', 3, 60_000, now, store);
    expect(fourth.ok).toBe(false);
    expect(fourth.remaining).toBe(0);
  });

  it('pencere dolunca sayaç sıfırlanır', () => {
    const store = new Map();
    rateLimit('k', 1, 1000, 0, store);
    expect(rateLimit('k', 1, 1000, 500, store).ok).toBe(false); // aynı pencere
    expect(rateLimit('k', 1, 1000, 1500, store).ok).toBe(true); // yeni pencere
  });

  it('farklı anahtarlar bağımsız sayılır', () => {
    const store = new Map();
    expect(rateLimit('a', 1, 1000, 0, store).ok).toBe(true);
    expect(rateLimit('b', 1, 1000, 0, store).ok).toBe(true);
    expect(rateLimit('a', 1, 1000, 0, store).ok).toBe(false);
  });
});
