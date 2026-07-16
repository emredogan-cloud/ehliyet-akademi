import { describe, it, expect } from 'vitest';
import { SCENARIOS, scenarioById, validateScenarioGraph } from './scenarios';
import { signById } from './signs';

describe('sürüş senaryoları (Program 2 · Faz 8)', () => {
  it('en az 6 senaryo, kimlikler benzersiz', () => {
    expect(SCENARIOS.length).toBeGreaterThanOrEqual(6);
    const ids = new Set(SCENARIOS.map((s) => s.id));
    expect(ids.size).toBe(SCENARIOS.length);
  });

  it('graf bütünlüğü: start/next çözülür, çıkmaz yok, her adımda güvenli seçenek var', () => {
    for (const s of SCENARIOS) {
      const errors = validateScenarioGraph(s);
      expect(errors, errors.join(' | ')).toHaveLength(0);
    }
  });

  it('açıklamalar öğretici (dolu) ve seçenek metinleri ayrışık', () => {
    for (const s of SCENARIOS) {
      for (const st of s.steps) {
        const texts = new Set(st.options.map((o) => o.text));
        expect(texts.size).toBe(st.options.length);
        for (const o of st.options) {
          expect(o.explain.length, `${s.id}/${st.id}`).toBeGreaterThan(20);
        }
      }
    }
  });

  it('sahne işaret rozetleri işaret kataloğunda çözülür', () => {
    for (const s of SCENARIOS) {
      for (const st of s.steps) {
        if (st.scene.sign) {
          expect(
            signById(st.scene.sign.signId),
            `${s.id}/${st.id} → ${st.scene.sign.signId}`
          ).toBeDefined();
        }
      }
    }
  });

  it('ilgili dersler çözülür', async () => {
    const { lessonBySlug } = await import('./lessons');
    for (const s of SCENARIOS) {
      if (s.relatedLessonSlug) {
        expect(lessonBySlug(s.relatedLessonSlug), `${s.id} → ${s.relatedLessonSlug}`).toBeDefined();
      }
    }
    expect(scenarioById('sagdan-gelen')?.steps.length).toBeGreaterThanOrEqual(2);
  });
});
