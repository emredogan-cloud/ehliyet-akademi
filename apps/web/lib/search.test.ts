import { describe, it, expect } from 'vitest';
import { LocalSearchProvider } from './search';

describe('SearchProvider (yerel)', () => {
  it('statik ders + soru içinde bulur', async () => {
    const p = new LocalSearchProvider();
    const hits = await p.search('hız');
    expect(hits.length).toBeGreaterThan(0);
    expect(hits.some((h) => h.type === 'question')).toBe(true);
  });

  it('kısa/anlamsız sorguda boş döner', async () => {
    const p = new LocalSearchProvider();
    expect(await p.search('a')).toEqual([]);
    expect(await p.search('qqqqzzzz')).toEqual([]);
  });

  it('indexContent: yayınlanan görünür, emekli olan düşer (kanca sözleşmesi)', async () => {
    const p = new LocalSearchProvider();
    await p.indexContent([
      { id: 'c1', type: 'article', title: 'Kavşak rehberi', status: 'published' },
    ]);
    expect((await p.search('kavşak rehberi')).some((h) => h.id === 'c1')).toBe(true);
    await p.indexContent([
      { id: 'c1', type: 'article', title: 'Kavşak rehberi', status: 'retired' },
    ]);
    expect((await p.search('kavşak rehberi')).some((h) => h.id === 'c1')).toBe(false);
  });

  it('limit uygulanır', async () => {
    const p = new LocalSearchProvider();
    const hits = await p.search('trafik', { limit: 3 });
    expect(hits.length).toBeLessThanOrEqual(3);
  });
});
