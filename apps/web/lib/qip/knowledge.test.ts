import { describe, it, expect } from 'vitest';
import { DRIVING_RULES, rulesBySubject, ruleTopics } from './knowledge';
import { buildGraph, graphStats, neighbors } from './graph';

describe('DRIVING_RULES — bilgi katmanı (Faz 2, olgu)', () => {
  it('kurallar benzersiz id + zorunlu alanlarla', () => {
    const ids = DRIVING_RULES.map((r) => r.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const r of DRIVING_RULES) {
      expect(r.statement.length).toBeGreaterThan(8);
      expect(r.topics.length).toBeGreaterThan(0);
      expect(r.source.length).toBeGreaterThan(4);
    }
  });

  it('dört teorik dersin hepsini kapsar', () => {
    const by = rulesBySubject();
    expect(by.trafik).toBeGreaterThan(0);
    expect(by.ilkyardim).toBeGreaterThan(0);
    expect(by.motor).toBeGreaterThan(0);
  });

  it('sayısal limitler mevcut (hız/alkol/ceza/TYD)', () => {
    const vals = DRIVING_RULES.filter((r) => r.value).map((r) => r.value);
    expect(vals).toContain('50 km/s');
    expect(vals).toContain('0.50 promil');
    expect(vals).toContain('30:2');
  });
});

describe('knowledge → bilgi grafiği entegrasyonu', () => {
  it('kural düğümleri grafiğe eklenir', () => {
    const s = graphStats(buildGraph());
    expect(s.byNodeType.rule).toBe(DRIVING_RULES.length);
    expect(s.byEdgeType['rule-topic']).toBeGreaterThan(0);
  });

  it('kural, paylaşılan konu üzerinden çözülebilir (kural↔konu)', () => {
    // hız kuralları 'hiz' konusuna bağlı → topic düğümünün kural komşuları var
    const rules = neighbors('topic:hiz', { nodeType: 'rule' });
    expect(rules.length).toBeGreaterThan(0);
    expect(ruleTopics().has('hiz')).toBe(true);
  });
});
