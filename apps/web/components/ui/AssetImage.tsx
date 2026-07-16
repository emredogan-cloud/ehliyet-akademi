/**
 * AssetImage — premium görsel varlık render bileşeni (Program 2 · Faz 1).
 * Manifest'ten kimlikle görsel basar: next/image (lazy + responsive), erişilebilir
 * figure/figcaption, tema-uyumlu çerçeve. Manifest dışı kimlikte hiçbir şey basmaz.
 */
import Image from 'next/image';
import { visualAssetById } from '@/content/asset-manifest';

export function AssetImage({
  assetId,
  caption,
  priority = false,
  sizes = '(max-width: 700px) 100vw, 340px',
}: {
  assetId: string;
  /** Görsel altı açıklama; verilmezse manifest başlığı kullanılır. false → caption yok. */
  caption?: string | false;
  priority?: boolean;
  sizes?: string;
}) {
  const asset = visualAssetById(assetId);
  if (!asset) return null;
  const cap = caption === false ? null : (caption ?? asset.title);
  return (
    <figure className="asset-figure" data-testid="asset-image">
      <Image
        src={asset.src}
        alt={asset.alt}
        width={asset.width}
        height={asset.height}
        sizes={sizes}
        priority={priority}
        className="asset-figure__img"
      />
      {cap && <figcaption className="asset-figure__cap">{cap}</figcaption>}
    </figure>
  );
}
