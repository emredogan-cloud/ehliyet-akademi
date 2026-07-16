import { describe, it, expect } from 'vitest';
import { ANIMATIONS, LESSON_ANIMS, animationById } from './animations';
import { lessonBySlug } from './lessons';

describe('eğitsel animasyon kataloğu (Program 2 · Faz 3)', () => {
  it('en az 4 animasyon, benzersiz kimlikler, dolu adımlar', () => {
    expect(ANIMATIONS.length).toBeGreaterThanOrEqual(4);
    const ids = new Set(ANIMATIONS.map((a) => a.id));
    expect(ids.size).toBe(ANIMATIONS.length);
    for (const a of ANIMATIONS) {
      expect(a.title.length).toBeGreaterThan(3);
      expect(a.description.length).toBeGreaterThan(10);
      expect(a.duration).toBeGreaterThanOrEqual(4);
      expect(a.steps.length).toBeGreaterThanOrEqual(3);
      for (const s of a.steps) expect(s.length).toBeGreaterThan(8);
    }
  });

  it('ders eşlemeleri: ders + animasyon kimlikleri çözülür', () => {
    const entries = Object.entries(LESSON_ANIMS);
    expect(entries.length).toBeGreaterThanOrEqual(3);
    for (const [slug, ids] of entries) {
      expect(lessonBySlug(slug), `ders yok: ${slug}`).toBeDefined();
      for (const id of ids) {
        expect(animationById(id), `${slug} → ${id}`).toBeDefined();
      }
    }
  });
});
