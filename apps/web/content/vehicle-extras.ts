/**
 * Araç bileşeni ekstraları (Program 2 · Faz 7): grounded soru eşleme + kimlik listesi.
 */
import { VEHICLE_PARTS, type VehiclePart } from './vehicle';
import { allQuestions } from '@ea/question-bank';
import type { Question } from '@ea/content-schema';

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

/** Bileşenle ilgili banka sorularını grounded bulur (ad, soru kökünde). */
export function questionsForPart(part: VehiclePart, limit = 2): Question[] {
  const terms = part.name
    .split(/[&()]/)[0]!
    .split(/\s+/)
    .map(norm)
    .filter((t) => t.length >= 4);
  const out: Question[] = [];
  for (const q of allQuestions()) {
    if (out.length >= limit) break;
    const stem = norm(q.stem);
    if (terms.length > 0 && terms.every((t) => stem.includes(t))) out.push(q);
  }
  return out;
}

export function allPartIds(): string[] {
  return VEHICLE_PARTS.map((p) => p.id);
}
