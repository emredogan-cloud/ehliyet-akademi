import { describe, it, expect } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { VIDEOS, videoById, availableVideos, summarizeTranscript } from './videos';
import { lessonBySlug } from './lessons';

const PUBLIC = join(__dirname, '..', 'public');

describe('video öğrenme kataloğu (Program 2 · Faz 4 · ADR-013)', () => {
  it('katalog: benzersiz kimlikler + en az 2 mevcut + planlananlar dürüst işaretli', () => {
    const ids = new Set(VIDEOS.map((v) => v.id));
    expect(ids.size).toBe(VIDEOS.length);
    expect(availableVideos().length).toBeGreaterThanOrEqual(2);
    for (const v of VIDEOS) {
      expect(['available', 'planned']).toContain(v.status);
      if (v.status === 'planned') {
        expect(v.src, `${v.id}: planned video src taşımamalı`).toBeUndefined();
      }
    }
  });

  it('mevcut videolar: dosyalar diskte (mp4+webm+poster+vtt), alanlar tam', () => {
    for (const v of availableVideos()) {
      expect(v.src, v.id).toBeTruthy();
      expect(v.srcWebm, v.id).toBeTruthy();
      expect(v.poster, v.id).toBeTruthy();
      expect(v.captions, v.id).toBeTruthy();
      expect(v.duration, v.id).toBeGreaterThan(0);
      for (const p of [v.src!, v.srcWebm!, v.poster!, v.captions!]) {
        expect(existsSync(join(PUBLIC, p)), `${v.id}: ${p} yok`).toBe(true);
      }
      // VTT geçerli başlıyor
      const vtt = readFileSync(join(PUBLIC, v.captions!), 'utf8');
      expect(vtt.startsWith('WEBVTT'), v.id).toBe(true);
    }
  });

  it('bölümler + transkript süre içinde ve sıralı', () => {
    for (const v of availableVideos()) {
      const d = v.duration!;
      for (const list of [v.chapters!, v.transcript!]) {
        expect(list.length).toBeGreaterThanOrEqual(3);
        for (let i = 0; i < list.length; i++) {
          expect(list[i]!.t).toBeGreaterThanOrEqual(0);
          expect(list[i]!.t).toBeLessThan(d);
          if (i > 0) expect(list[i]!.t).toBeGreaterThan(list[i - 1]!.t);
        }
      }
    }
  });

  it('ilgili dersler çözülür + özet transkriptten türetilir', () => {
    for (const v of VIDEOS) {
      if (v.relatedLessonSlug) {
        expect(lessonBySlug(v.relatedLessonSlug), `${v.id} → ${v.relatedLessonSlug}`).toBeDefined();
      }
    }
    const s = summarizeTranscript(videoById('parallel-park')!);
    expect(s.length).toBeGreaterThanOrEqual(3);
    expect(s[0]).toContain('hizalan');
  });
});
