/**
 * LessonPhotos — ders sayfası premium fotoğraf şeridi (Program 2 · Faz 1).
 * LESSON_PHOTOS eşlemesinden dersin görsellerini basar; eşleme yoksa hiçbir şey basmaz.
 */
import { LESSON_PHOTOS } from '@/content/asset-manifest';
import { AssetImage } from '@/components/ui/AssetImage';

export function LessonPhotos({ slug }: { slug: string }) {
  const ids = LESSON_PHOTOS[slug];
  if (!ids || ids.length === 0) return null;
  return (
    <div
      className="lesson-photos"
      data-testid="lesson-photos"
      role="group"
      aria-label="Ders görselleri"
    >
      {ids.map((id) => (
        <AssetImage key={id} assetId={id} sizes="(max-width: 700px) 85vw, 250px" />
      ))}
    </div>
  );
}
