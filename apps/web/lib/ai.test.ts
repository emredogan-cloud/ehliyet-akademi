import { describe, it, expect } from 'vitest';
import { retrieve, MockAIProvider } from './ai';

describe('AI koç retrieval (grounded, deterministik)', () => {
  it('DUR levhası sorusu doğru içeriği bulur', () => {
    const g = retrieve('DUR levhasında ne yapılır?');
    expect(g.question?.topic === 'isaretler' || g.lessonSlug === 'trafik-isaretleri').toBe(true);
  });

  it('hararet sorusu motor içeriğine gider', () => {
    const g = retrieve('hararet ikazı yanarsa ne yapmalıyım');
    expect(g.question?.subject).toBe('motor');
  });

  it('boş/anlamsız sorguda eşleşme yok', () => {
    expect(retrieve('xyzqw')).toEqual({});
  });

  it('deterministik: aynı soru aynı grounding', () => {
    const a = retrieve('kalp masajı kaç bası');
    const b = retrieve('kalp masajı kaç bası');
    expect(a.question?.id).toBe(b.question?.id);
  });
});

describe('MockAIProvider', () => {
  it('kaynaklı yanıt + uyarı metni üretir', async () => {
    const ai = new MockAIProvider();
    const ans = await ai.ask('yaya geçidinde öncelik kimde?');
    expect(ans).toContain('AI hata yapabilir');
    expect(ans.length).toBeGreaterThan(50);
  });

  it('eşleşme yoksa dürüstçe bilmediğini söyler (halüsinasyon yok)', async () => {
    const ai = new MockAIProvider();
    const ans = await ai.ask('qqqq zzzz');
    expect(ans).toContain('eşleşme bulamadım');
  });
});
