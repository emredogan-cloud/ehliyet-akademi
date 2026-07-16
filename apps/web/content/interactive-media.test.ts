import { describe, it, expect } from 'vitest';
import {
  HOTSPOT_SCENES,
  COMPARE_SCENES,
  STEP_FLOWS,
  LESSON_MEDIA,
  hotspotSceneById,
  compareSceneById,
  stepFlowById,
} from './interactive-media';
import { visualAssetById } from './asset-manifest';
import { lessonBySlug } from './lessons';

describe('etkileşimli medya içeriği (Program 2 · Faz 2)', () => {
  it('hotspot sahneleri: varlıklar çözülür, koordinatlar 0–100 içinde, metinler dolu', () => {
    expect(HOTSPOT_SCENES.length).toBeGreaterThanOrEqual(2);
    for (const s of HOTSPOT_SCENES) {
      expect(visualAssetById(s.asset), `${s.id} → ${s.asset}`).toBeDefined();
      expect(s.spots.length).toBeGreaterThanOrEqual(3);
      for (const p of s.spots) {
        expect(p.x).toBeGreaterThanOrEqual(0);
        expect(p.x).toBeLessThanOrEqual(100);
        expect(p.y).toBeGreaterThanOrEqual(0);
        expect(p.y).toBeLessThanOrEqual(100);
        expect(p.title.length).toBeGreaterThan(2);
        expect(p.text.length).toBeGreaterThan(10);
      }
    }
  });

  it('karşılaştırma sahneleri: her iki varlık da çözülür', () => {
    expect(COMPARE_SCENES.length).toBeGreaterThanOrEqual(1);
    for (const c of COMPARE_SCENES) {
      expect(visualAssetById(c.beforeAsset), c.id).toBeDefined();
      expect(visualAssetById(c.afterAsset), c.id).toBeDefined();
      expect(c.beforeLabel).not.toBe(c.afterLabel);
      expect(c.caption.length).toBeGreaterThan(10);
    }
  });

  it('adım akışları: her adımın varlığı çözülür, sıra dolu', () => {
    expect(STEP_FLOWS.length).toBeGreaterThanOrEqual(1);
    for (const f of STEP_FLOWS) {
      expect(f.steps.length).toBeGreaterThanOrEqual(5);
      for (const st of f.steps) {
        expect(visualAssetById(st.asset), `${f.id} → ${st.asset}`).toBeDefined();
        expect(st.title.length).toBeGreaterThan(2);
        expect(st.text.length).toBeGreaterThan(10);
      }
    }
  });

  it('ders eşlemeleri: ders + sahne kimlikleri çözülür', () => {
    const entries = Object.entries(LESSON_MEDIA);
    expect(entries.length).toBeGreaterThanOrEqual(3);
    for (const [slug, m] of entries) {
      expect(lessonBySlug(slug), `ders yok: ${slug}`).toBeDefined();
      if (m.hotspots) expect(hotspotSceneById(m.hotspots), `${slug} → ${m.hotspots}`).toBeDefined();
      if (m.compare) expect(compareSceneById(m.compare), `${slug} → ${m.compare}`).toBeDefined();
      if (m.steps) expect(stepFlowById(m.steps), `${slug} → ${m.steps}`).toBeDefined();
    }
  });
});
