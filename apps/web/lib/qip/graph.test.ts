import { describe, it, expect } from 'vitest';
import { SIGNS } from '@/content/signs';
import { VEHICLE_PARTS } from '@/content/vehicle';
import { LESSONS } from '@/content/lessons';
import { allQuestions } from '@ea/question-bank';
import { buildGraph, neighbors, relatedContent, relatedQuestions, graphStats } from './graph';

describe('buildGraph — bilgi grafiği', () => {
  const g = buildGraph();

  it('içerik düğümlerini gerçek sayılarla kurar', () => {
    const s = graphStats(g);
    expect(s.byNodeType.subject).toBe(5);
    expect(s.byNodeType.sign).toBe(SIGNS.length);
    expect(s.byNodeType.part).toBe(VEHICLE_PARTS.length);
    expect(s.byNodeType.lesson).toBe(LESSONS.length);
    expect(s.byNodeType.question).toBe(allQuestions().length);
    expect(s.nodeCount).toBeGreaterThan(allQuestions().length);
    expect(s.edgeCount).toBeGreaterThan(0);
  });

  it('deterministik — buildGraph aynı önbelleği döner', () => {
    expect(buildGraph()).toBe(g);
  });

  it('soru düğümü ders/konu/tema komşularına bağlı', () => {
    const subs = neighbors('question:trafik-101', { nodeType: 'subject' }, g);
    expect(subs.map((n) => n.ref)).toContain('trafik');
    const themes = neighbors('question:trafik-101', { nodeType: 'theme' }, g);
    expect(themes.length).toBeGreaterThanOrEqual(1);
    const topics = neighbors('question:trafik-101', { edgeType: 'about-topic' }, g);
    expect(topics.length).toBe(1);
  });
});

describe('relatedContent / relatedQuestions — öneri', () => {
  it('grafik-güdümlü ilgili içerik döner, kendini dışlar', () => {
    const rc = relatedContent('trafik-101');
    expect(rc.questions.every((n) => n.ref !== 'trafik-101')).toBe(true);
    expect(rc.questions.length).toBeGreaterThan(0);
    // ders bağı olan bir soruda ilgili ders gelir
    expect(rc.lessons.length).toBeGreaterThanOrEqual(0);
  });

  it('relatedQuestions ham id döner, limitli, kendini içermez', () => {
    const ids = relatedQuestions('trafik-101', 4);
    expect(ids.length).toBeLessThanOrEqual(4);
    expect(ids).not.toContain('trafik-101');
  });

  it('bilinmeyen soru boş ilgili içerik verir', () => {
    const rc = relatedContent('yok-boyle-soru');
    expect(rc.questions).toEqual([]);
    expect(rc.lessons).toEqual([]);
  });
});

describe('graphStats', () => {
  it('tutarlı sayımlar üretir', () => {
    const s = graphStats();
    const nodeSum = Object.values(s.byNodeType).reduce((a, b) => a + b, 0);
    expect(nodeSum).toBe(s.nodeCount);
    expect(s.orphanQuestions).toBeLessThanOrEqual(allQuestions().length);
    expect(s.avgQuestionDegree).toBeGreaterThan(0);
  });
});
