import { describe, it, expect } from 'vitest';
import { tierForXp, dailyChallenge, referralLink, TIERS } from './community';

describe('XP kademeleri (dürüst lider tablosu)', () => {
  it('XP degerine gore dogru kademe + sonraki', () => {
    expect(tierForXp(0).current.name).toBe('Bronz');
    expect(tierForXp(500).current.name).toBe('Gümüş');
    expect(tierForXp(7000).current.name).toBe('Elmas');
    const g = tierForXp(600); // Gümüş(500)..Altın(1500)
    expect(g.current.name).toBe('Gümüş');
    expect(g.next?.name).toBe('Altın');
    expect(g.toNext).toBe(900);
  });
  it('en üst kademede sonraki yok', () => {
    const t = tierForXp(999999);
    expect(t.current.name).toBe(TIERS[TIERS.length - 1]!.name);
    expect(t.next).toBeUndefined();
    expect(t.toNext).toBe(0);
  });
});

describe('günlük meydan okuma (deterministik)', () => {
  it('aynı gün aynı, farklı gün farklı olabilir', () => {
    const d1 = dailyChallenge(new Date('2026-07-15T01:00:00').getTime());
    const d1b = dailyChallenge(new Date('2026-07-15T22:00:00').getTime());
    expect(d1.id).toBe(d1b.id);
    expect(d1.title.length).toBeGreaterThan(3);
    expect(d1.target).toBeGreaterThan(0);
  });
});

describe('davet bağlantısı', () => {
  it('base + kod ile bağlantı üretir', () => {
    expect(referralLink('https://x.app/', 'ABC123')).toBe('https://x.app/?davet=ABC123');
  });
});
