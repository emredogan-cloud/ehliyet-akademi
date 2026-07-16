/**
 * Grounded görsel eşleyici (Program 2 · Faz 5).
 * Serbest metni YALNIZ kendi kataloglarımızla (işaret + araç bileşeni) eşler —
 * halüsinasyon kapısı görsel kimlikleri de kapsar: katalog dışı görsel asla dönmez.
 */
import { SIGNS, type TrafficSign } from '@/content/signs';
import { VEHICLE_PARTS, type VehiclePart } from '@/content/vehicle';

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

export interface VisualMatches {
  signs: TrafficSign[];
  parts: VehiclePart[];
}

/**
 * Kelime-sınırlı içerme: kısa terimler (≤4) TAM kelime ister ("dur" ≠ "durum");
 * uzun terimlerde TR morfolojisi için sonek serbesttir ("lastik" → "lastiklerin").
 */
function hasTerm(text: string, term: string): boolean {
  const t = norm(term);
  if (t.length < 3) return false;
  const esc = t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const suffix = t.length <= 4 ? '([^a-z0-9]|$)' : '';
  return new RegExp(`(^|[^a-z0-9])${esc}${suffix}`).test(text);
}

/**
 * Metinden görsel eşleşmeleri çıkarır (en fazla `limit` toplam; işaretler öncelikli).
 * Eşleşme ölçütü: işaret adı VEYA anahtar kelimesi / bileşen adı metinde geçer.
 */
export function matchVisuals(text: string, limit = 2): VisualMatches {
  const t = norm(text);
  const signs: TrafficSign[] = [];
  const parts: VehiclePart[] = [];

  // 1. geçiş: AD eşleşmesi (güçlü sinyal) — 2. geçiş: anahtar kelime.
  for (const s of SIGNS) {
    if (signs.length >= limit) break;
    if (hasTerm(t, s.name)) signs.push(s);
  }
  for (const s of SIGNS) {
    if (signs.length >= limit) break;
    if (!signs.includes(s) && s.keywords.some((k) => hasTerm(t, k))) signs.push(s);
  }
  for (const p of VEHICLE_PARTS) {
    if (signs.length + parts.length >= limit) break;
    if (hasTerm(t, p.name)) {
      parts.push(p);
    }
  }
  return { signs, parts };
}
