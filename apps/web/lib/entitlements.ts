/**
 * Premium erişim kontrolü (Sprint 4). Kilitli içerik ↔ gerekli yetenek ↔ satın alınabilir ürün.
 * Saf ve test edilebilir. Güvenlik/ilk-yardım içeriği ASLA kilitlenmez (yalnız ileri alıştırma).
 */
import { hasCapability, productById, PRODUCTS, type Capability, type ProductId } from './products';

/** Premium ders slug'ı → içeriği açan yetenek. */
const LESSON_CAPABILITY: Record<string, Capability> = {
  'park-manevra': 'direksiyon-premium',
  'kavsak-uygulama': 'direksiyon-premium',
  'sollama-serit': 'teori-premium',
};

export function requiredCapability(slug: string): Capability | undefined {
  return LESSON_CAPABILITY[slug];
}

export interface AccessibleLesson {
  slug: string;
  premium?: boolean;
}

/** Ders erişilebilir mi? premium değilse her zaman; premium ise gerekli yetenek sahipliğine bağlı. */
export function canAccessLesson(lesson: AccessibleLesson, owned: string[]): boolean {
  if (!lesson.premium) return true;
  const cap = LESSON_CAPABILITY[lesson.slug];
  if (!cap) return true; // premium işaretli ama eşleme yoksa: güvenli varsayılan = açık
  return hasCapability(owned, cap);
}

/** Bir yeteneği açan en uygun (en ucuz) ürün — kilit ekranında önerilir. */
export function productForCapability(cap: Capability): ProductId {
  const owning = PRODUCTS.filter((p) => p.capabilities.includes(cap)).sort(
    (a, b) => a.priceTRY - b.priceTRY
  );
  return owning[0]?.id ?? 'komple-b';
}

/** Ders için önerilecek ürün (kilit ekranı CTA'sı). */
export function productForLesson(slug: string): ProductId {
  const cap = LESSON_CAPABILITY[slug];
  return cap ? productForCapability(cap) : 'komple-b';
}

export { productById };
