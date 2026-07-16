import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { VISUAL_ASSETS, visualAssetById, LESSON_PHOTOS } from './asset-manifest';
import { lessonBySlug } from './lessons';

const PUBLIC = join(__dirname, '..', 'public');

describe('premium görsel varlık manifesti (Program 2 · Faz 1)', () => {
  it('yeterli varlık + benzersiz kimlikler', () => {
    expect(VISUAL_ASSETS.length).toBeGreaterThanOrEqual(24);
    const ids = new Set(VISUAL_ASSETS.map((a) => a.id));
    expect(ids.size).toBe(VISUAL_ASSETS.length);
  });

  it('her varlık erişilebilirlik + lisans metaverisi taşır', () => {
    for (const a of VISUAL_ASSETS) {
      expect(a.alt.length, a.id).toBeGreaterThan(12);
      expect(a.title.length, a.id).toBeGreaterThan(2);
      expect(a.license, a.id).toBeTruthy();
      expect(a.width).toBeGreaterThan(0);
      expect(a.height).toBeGreaterThan(0);
      expect(a.tags.length, a.id).toBeGreaterThan(0);
    }
  });

  it('her varlık dosyası diskte mevcut ve geçerli WebP', () => {
    for (const a of VISUAL_ASSETS) {
      const p = join(PUBLIC, a.src);
      expect(existsSync(p), `${a.id}: ${a.src} yok`).toBe(true);
      const head = readFileSync(p).subarray(0, 12);
      // RIFF....WEBP sihirli baytları
      expect(head.subarray(0, 4).toString('ascii'), a.id).toBe('RIFF');
      expect(head.subarray(8, 12).toString('ascii'), a.id).toBe('WEBP');
    }
  });

  it('varlıklar performans bütçesinde (dosya başına < 400KB)', () => {
    for (const a of VISUAL_ASSETS) {
      const size = readFileSync(join(PUBLIC, a.src)).length;
      expect(size, `${a.id} ${Math.round(size / 1024)}KB`).toBeLessThan(400 * 1024);
    }
  });

  it('ders foto eşlemeleri geçerli ders + geçerli varlıklara işaret eder', () => {
    for (const [slug, assetIds] of Object.entries(LESSON_PHOTOS)) {
      expect(lessonBySlug(slug), `ders yok: ${slug}`).toBeDefined();
      for (const id of assetIds) {
        expect(visualAssetById(id), `${slug} → ${id}`).toBeDefined();
      }
    }
  });
});
