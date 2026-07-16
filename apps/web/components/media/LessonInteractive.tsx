/**
 * LessonInteractive — dersin etkileşimli medya bloğu (Program 2 · Faz 2).
 * LESSON_MEDIA eşlemesine göre hotspot turu / karşılaştırma / adım akışı basar.
 */
import { LESSON_MEDIA } from '@/content/interactive-media';
import { Hotspots } from './Hotspots';
import { CompareSlider } from './CompareSlider';
import { StepFlow } from './StepFlow';

export function LessonInteractive({ slug }: { slug: string }) {
  const media = LESSON_MEDIA[slug];
  if (!media) return null;
  return (
    <section className="lesson-interactive" data-testid="lesson-interactive">
      {media.hotspots && <Hotspots sceneId={media.hotspots} />}
      {media.steps && <StepFlow sceneId={media.steps} />}
      {media.compare && <CompareSlider sceneId={media.compare} />}
    </section>
  );
}
