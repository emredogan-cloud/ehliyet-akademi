import { describe, it, expect } from 'vitest';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { VIDEOS, videoById, availableVideos, summarizeTranscript } from './videos';
import { lessonBySlug } from './lessons';

const PUBLIC = join(__dirname, '..', 'public');

describe('video öğrenme kataloğu (Program 2 · Faz 4 · ADR-013)', () => {
  it('katalog: benzersiz kimlikler + en az 2 mevcut + planlananlar dürüst işaretli', () => {
    const ids = new Set(VIDEOS.map((v) => v.id));
    expect(ids.size).toBe(VIDEOS.length);
    // E12 manevra seti + yükseltilen iki sahne = 7 oynatılabilir video.
    expect(availableVideos().length).toBeGreaterThanOrEqual(7);
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

  // ── Evolution Faz E12 ────────────────────────────────────────────────────
  describe('E12 — manevra seti ve üretim hattı bütünlüğü', () => {
    it('roadmap manevra seti eksiksiz ve oynatılabilir', () => {
      for (const id of ['parallel-park', 'l-park', 'u-turn', 'reverse-25m']) {
        const v = videoById(id);
        expect(v, `${id} katalogda yok`).toBeDefined();
        expect(v!.status, id).toBe('available');
      }
    });

    it('BÖLÜMLER ile ALTYAZI aynı kaynaktan gelir — VTT damgaları transkriptle birebir', () => {
      for (const v of availableVideos()) {
        const vtt = readFileSync(join(PUBLIC, v.captions!), 'utf8');
        // "mm:ss.mmm --> ..." satırlarının başlangıç saniyeleri
        const starts = [...vtt.matchAll(/^(\d{2}):(\d{2})\.(\d{3}) -->/gm)].map(
          (m) => Number(m[1]) * 60 + Number(m[2]) + Number(m[3]) / 1000
        );
        expect(starts.length, `${v.id}: VTT ipucu yok`).toBe(v.transcript!.length);
        v.transcript!.forEach((cue, i) => {
          expect(starts[i], `${v.id} ipucu ${i}`).toBeCloseTo(cue.t, 3);
        });
      }
    });

    it('animasyon videoları ANİMASYON olarak etiketlenir — sahte gerçek çekim iddiası yok', () => {
      for (const v of availableVideos()) {
        expect(v.title, `${v.id}: başlıkta (Animasyon) yok`).toContain('(Animasyon)');
        expect(v.title, `${v.id}: animasyon "Gerçek Çekim" diye sunulamaz`).not.toContain(
          'Gerçek Çekim —'
        );
      }
    });

    it('planlanan videolar gerçek çekim gerektirdiğini AÇIKÇA söyler', () => {
      const planned = VIDEOS.filter((v) => v.status === 'planned');
      expect(planned.length).toBeGreaterThan(0);
      for (const v of planned) {
        expect(v.title, `${v.id}`).toContain('planlanıyor');
        expect(v.description.toLowerCase(), `${v.id}`).toContain('gerçek');
      }
    });

    it('premium standart: dosyalar makul boyutta ve poster gerçek bir kare', () => {
      for (const v of availableVideos()) {
        const mp4 = statSync(join(PUBLIC, v.src!)).size;
        const poster = statSync(join(PUBLIC, v.poster!)).size;
        // Boş/bozuk çıktıya karşı alt sınır, şişmeye karşı üst sınır (bütçe: video başına 1 MB).
        expect(mp4, `${v.id} mp4`).toBeGreaterThan(20_000);
        expect(mp4, `${v.id} mp4 bütçesi`).toBeLessThan(1_000_000);
        expect(poster, `${v.id} poster`).toBeGreaterThan(4_000);
      }
    });
  });
});
