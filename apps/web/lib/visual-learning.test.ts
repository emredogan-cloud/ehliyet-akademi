import { describe, it, expect } from 'vitest';
import { matchVisuals } from './visual-match';
import { buildRound, quizPool } from './visual-quiz';
import { SIGNS, signById } from '@/content/signs';
import { vehiclePartById } from '@/content/vehicle';
import { visualAssetById } from '@/content/asset-manifest';

/** Deterministik RNG (test tekrarlanabilirliği). */
function seeded(seed = 42): () => number {
  let s = seed;
  return () => {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  };
}

describe('grounded görsel eşleyici (Program 2 · Faz 5)', () => {
  it('işaret adı geçen metne ilgili işaret kartını iliştirir', () => {
    const m = matchVisuals('DUR levhasında araç tam durur ve öncelik verir.');
    expect(m.signs.length).toBeGreaterThanOrEqual(1);
    expect(m.signs.some((s) => s.id === 'dur')).toBe(true);
  });

  it('bileşen adı geçen metne bileşen kartını iliştirir', () => {
    const m = matchVisuals('El freni çekili mi kontrol et; rampada kalkışta önemlidir.');
    expect(m.parts.some((p) => p.id === 'handbrake')).toBe(true);
  });

  it('eşleşme yoksa boş döner (halüsinasyon yok) + limit aşılmaz', () => {
    const none = matchVisuals('Bugün hava çok güzel, pikniğe gidelim.');
    expect(none.signs.length + none.parts.length).toBe(0);
    const many = matchVisuals(
      'Kaygan yol, dur, yol ver, park, hastane, akü, lastik, pedallar hepsi bir arada.'
    );
    expect(many.signs.length + many.parts.length).toBeLessThanOrEqual(2);
  });

  it('dönen her görsel katalogda çözülür (grounded garanti)', () => {
    const m = matchVisuals('Sis farları ve yaya geçidi hakkında bilgi.');
    for (const s of m.signs) expect(signById(s.id)).toBeDefined();
    for (const p of m.parts) expect(vehiclePartById(p.id)).toBeDefined();
  });
});

describe('görsel quiz üreticisi (Program 2 · Faz 5)', () => {
  it('havuz: tüm işaretler + fotoğraflı bileşenler', () => {
    const pool = quizPool();
    expect(pool.length).toBeGreaterThanOrEqual(SIGNS.length + 30);
  });

  it('tur: 4 benzersiz seçenek, doğru cevap içeride, açıklama dolu', () => {
    const rng = seeded();
    for (let i = 0; i < 25; i++) {
      const r = buildRound(rng)!;
      expect(r).not.toBeNull();
      expect(r.options.length).toBe(4);
      expect(new Set(r.options).size).toBe(4);
      expect(r.answerIndex).toBeGreaterThanOrEqual(0);
      expect(r.answerIndex).toBeLessThan(4);
      expect(r.explanation.length).toBeGreaterThan(10);
      expect(r.groupLabel.length).toBeGreaterThan(2);
      // Görsel çözülür: işaret katalogda, bileşen fotosu manifestte
      if (r.kind === 'sign') expect(signById(r.itemId)).toBeDefined();
      else expect(visualAssetById(r.assetId!)).toBeDefined();
    }
  });

  it('zayıf tekrar: belirli öğeden tur üretir', () => {
    const r = buildRound(seeded(7), { kind: 'sign', id: 'dur' })!;
    expect(r.itemId).toBe('dur');
    expect(r.options[r.answerIndex]).toBe(signById('dur')!.name);
    const p = buildRound(seeded(7), { kind: 'part', id: 'battery' })!;
    expect(p.itemId).toBe('battery');
    expect(p.assetId).toBe('battery');
  });
});
