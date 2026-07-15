'use client';

/** Ders görüntüleme izleyici (Sprint 6) — XP/yolculuk için görülen dersleri kaydeder + analitik. */
import { useEffect } from 'react';
import { markLessonViewed } from '@/lib/progress';
import { track } from '@/lib/analytics';

export function LessonViewTracker({ slug, premium }: { slug: string; premium: boolean }) {
  useEffect(() => {
    markLessonViewed(slug);
    track({ name: 'lesson_viewed', props: { slug, premium } });
  }, [slug, premium]);
  return null;
}
