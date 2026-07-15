import { describe, it, expect, vi } from 'vitest';
import { enabledProviders, track, setSink, type AnalyticsEvent } from './analytics';

describe('enabledProviders (gizlilik-öncelikli)', () => {
  it('rıza yoksa hiçbir sağlayıcı — ENV olsa bile', () => {
    expect(enabledProviders(false, { ga4: 'G-XXX', clarity: 'c', posthog: 'p' })).toEqual([]);
  });
  it('rıza var ama ENV yoksa boş', () => {
    expect(enabledProviders(true, {})).toEqual([]);
  });
  it('rıza + ilgili ENV → yalnız o sağlayıcılar', () => {
    expect(enabledProviders(true, { ga4: 'G-XXX' })).toEqual(['ga4']);
    expect(enabledProviders(true, { ga4: 'G', clarity: 'C', posthog: 'P' })).toEqual([
      'ga4',
      'clarity',
      'posthog',
    ]);
  });
});

describe('track', () => {
  it('olayi sink-e iletir ve asla firlatmaz', () => {
    const spy = vi.fn();
    setSink({ track: spy });
    const e: AnalyticsEvent = { name: 'lesson_viewed', props: { slug: 'x', premium: false } };
    track(e);
    expect(spy).toHaveBeenCalledWith(e);
    // sink fırlatsa bile track yutmalı
    setSink({
      track: () => {
        throw new Error('boom');
      },
    });
    expect(() => track(e)).not.toThrow();
  });
});
