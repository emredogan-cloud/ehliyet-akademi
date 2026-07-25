import { createHash } from 'node:crypto';
import { json } from '@/lib/server/auth';
import { ALL_LESSONS } from '@/content/lessons';
import { SIGNS } from '@/content/signs';
import { ALL_VEHICLE_PARTS } from '@/content/vehicle';
import { VIDEOS } from '@/content/videos';

/**
 * Mobil içerik anlık görüntüsü (Mobile Phase 3 · Content & Learn).
 *
 * Tüm öğrenme içeriği (dersler, işaretler, araç parçaları, videolar) statik ve kullanıcıya özel
 * değildir → tek, halka açık, önbelleğe alınabilir uç nokta. Flutter istemcisi bunu bir kez indirir,
 * `version` ile yerelde (drift) saklar ve yalnız sürüm değişince yeniden indirir (çevrimdışı-öncelik).
 *
 * Web ile birebir uyumlu: aynı `content/*` modüllerini serileştirir; web tarafını hiç değiştirmez.
 * Dersler ve araç parçaları için sınıfa özgü (A/D) içeriği de kapsayan `ALL_*` listeleri servis
 * edilir — web `LESSONS`/`VEHICLE_PARTS`'ı kullanmaya devam eder (Faz E4/E5).
 */

type Snapshot = {
  version: string;
  generatedAt: string;
  counts: { lessons: number; signs: number; vehicleParts: number; videos: number };
  lessons: typeof ALL_LESSONS;
  signs: typeof SIGNS;
  vehicleParts: typeof ALL_VEHICLE_PARTS;
  videos: typeof VIDEOS;
};

/** İçeriğin deterministik sürümü — yalnız içerik değişince değişir (generatedAt hariç). */
function contentVersion(): string {
  const payload = JSON.stringify({
    lessons: ALL_LESSONS,
    signs: SIGNS,
    vehicleParts: ALL_VEHICLE_PARTS,
    videos: VIDEOS,
  });
  return createHash('sha256').update(payload).digest('hex').slice(0, 16);
}

export function GET(req: Request): Response {
  const version = contentVersion();
  const etag = `"${version}"`;

  // İçerik değişmediyse gövdesiz 304 → mobil yalnız sürüm farkında indirir.
  const inm = req.headers.get('if-none-match');
  if (inm && inm === etag) {
    return new Response(null, {
      status: 304,
      headers: {
        etag,
        'cache-control': 'public, max-age=300, stale-while-revalidate=86400',
      },
    });
  }

  const body: Snapshot = {
    version,
    generatedAt: new Date().toISOString(),
    counts: {
      lessons: ALL_LESSONS.length,
      signs: SIGNS.length,
      vehicleParts: ALL_VEHICLE_PARTS.length,
      videos: VIDEOS.length,
    },
    lessons: ALL_LESSONS,
    signs: SIGNS,
    vehicleParts: ALL_VEHICLE_PARTS,
    videos: VIDEOS,
  };

  return json(body, {
    headers: {
      etag,
      'cache-control': 'public, max-age=300, stale-while-revalidate=86400',
    },
  });
}
