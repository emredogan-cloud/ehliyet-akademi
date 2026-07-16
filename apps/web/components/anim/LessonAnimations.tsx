/**
 * LessonAnimations — dersin eğitsel animasyon bloğu (Program 2 · Faz 3).
 * LESSON_ANIMS eşlemesine göre sahneleri basar; eşleme yoksa hiçbir şey basmaz.
 */
import { LESSON_ANIMS } from '@/content/animations';
import { AnimPlayer } from './AnimPlayer';

export function LessonAnimations({ slug }: { slug: string }) {
  const ids = LESSON_ANIMS[slug];
  if (!ids || ids.length === 0) return null;
  return (
    <section className="lesson-anims" data-testid="lesson-anims">
      {ids.map((id) => (
        <AnimPlayer key={id} animId={id} />
      ))}
    </section>
  );
}
