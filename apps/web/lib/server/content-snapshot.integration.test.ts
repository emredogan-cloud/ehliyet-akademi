/**
 * Mobil içerik anlık görüntüsü entegrasyon testi (Mobile Phase 3 · Content & Learn).
 * Gerçek route handler'ı çağırır; içerik dizileriyle sayı/şekil ve ETag/304 önbellek davranışını doğrular.
 */
import { describe, it, expect } from 'vitest';
import { GET as snapshot } from '@/app/api/mobile/content-snapshot/route';
import { LESSONS } from '@/content/lessons';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { VIDEOS } from '@/content/videos';
import { GLYPH_IDS } from '@/components/signs/TrafficSign';

const BASE = 'http://test.local';
const get = (headers?: Record<string, string>) =>
  new Request(`${BASE}/api/mobile/content-snapshot`, { headers });

type Snapshot = {
  version: string;
  generatedAt: string;
  counts: { lessons: number; signs: number; vehicleParts: number; videos: number };
  lessons: typeof LESSONS;
  signs: typeof SIGNS;
  vehicleParts: typeof VEHICLE_PARTS;
  videos: typeof VIDEOS;
};

describe('mobil içerik anlık görüntüsü', () => {
  it('200 döner; tüm içerik alanlarını ve doğru sayıları içerir', async () => {
    const res = snapshot(get());
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/application\/json/);
    const body = (await res.json()) as Snapshot;

    expect(body.counts.lessons).toBe(LESSONS.length);
    expect(body.counts.signs).toBe(SIGNS.length);
    expect(body.counts.vehicleParts).toBe(VEHICLE_PARTS.length);
    expect(body.counts.videos).toBe(VIDEOS.length);

    expect(body.lessons).toHaveLength(LESSONS.length);
    expect(body.signs).toHaveLength(SIGNS.length);
    expect(body.vehicleParts).toHaveLength(VEHICLE_PARTS.length);
    expect(body.videos).toHaveLength(VIDEOS.length);
  });

  it('sürüm + ETag verir; eşleşen If-None-Match → gövdesiz 304', async () => {
    const first = snapshot(get());
    const etag = first.headers.get('etag');
    const body = (await first.json()) as Snapshot;
    expect(etag).toBe(`"${body.version}"`);
    expect(body.version).toMatch(/^[a-f0-9]{16}$/);
    expect(first.headers.get('cache-control')).toContain('max-age');

    const second = snapshot(get({ 'if-none-match': etag! }));
    expect(second.status).toBe(304);
    expect(second.headers.get('etag')).toBe(etag);
    expect(await second.text()).toBe('');
  });

  it('sürüm deterministiktir (içerik değişmedikçe sabit)', async () => {
    const a = (await snapshot(get()).json()) as Snapshot;
    const b = (await snapshot(get()).json()) as Snapshot;
    expect(a.version).toBe(b.version);
  });

  it('işaretler tam şema taşır; her glyph referansı çizilebilir', async () => {
    const body = (await snapshot(get()).json()) as Snapshot;
    const known = new Set(GLYPH_IDS);
    for (const s of body.signs) {
      expect(typeof s.id).toBe('string');
      expect(typeof s.name).toBe('string');
      expect(s.shape).toBeTruthy();
      // Her işaret ya çizilebilir bir glyph ya metin (glyphText) taşır ya da kendi başına tam
      // bir levha olan bir şekildir (octagon=DUR, inv-triangle=YOL VER, diamond=Ana Yol).
      // Bilinmeyen glyph = eksik piktogram (kabul edilmez) — asıl bütünlük kontrolü budur.
      if (s.glyph) expect(known.has(s.glyph)).toBe(true);
      const selfContainedShape =
        s.shape === 'octagon' || s.shape === 'inv-triangle' || s.shape === 'diamond';
      const hasVisual = !!s.glyph || !!s.glyphText || selfContainedShape;
      expect(hasVisual).toBe(true);
    }
  });

  it('dersler bölüm + hedef taşır; videolar geçerli durum taşır', async () => {
    const body = (await snapshot(get()).json()) as Snapshot;
    for (const l of body.lessons) {
      expect(l.sections.length).toBeGreaterThan(0);
      expect(l.objectives.length).toBeGreaterThan(0);
    }
    for (const v of body.videos) {
      expect(['available', 'planned']).toContain(v.status);
    }
  });
});
