/**
 * İşaret ekstraları (Program 2 · Faz 6): karıştırılan işaret çiftleri + soru eşleme.
 * Çift kimlikleri katalogda çözülmek zorundadır (test kapısı).
 */
import { SIGNS, signById, type TrafficSign } from './signs';
import { allQuestions } from '@ea/question-bank';
import type { Question } from '@ea/content-schema';

export interface SignConfusion {
  a: string; // sign id
  b: string; // sign id
  difference: string; // farkın tek cümlelik özü
}

export const SIGN_CONFUSIONS: SignConfusion[] = [
  {
    a: 'dur',
    b: 'yol-ver',
    difference:
      'DUR her koşulda TAM durmayı; Yol Ver yalnız gerektiğinde durup öncelik vermeyi ister.',
  },
  {
    a: 'tehlikeli-viraj-sol',
    b: 'donus-yasak-sol',
    difference: 'Üçgen viraj UYARIR (yol sola kıvrılıyor); kırmızı halka dönüşü YASAKLAR.',
  },
  {
    a: 'yaya-geciti-tehlike',
    b: 'yaya-gecidi-bilgi',
    difference:
      'Üçgen sürücüyü yaklaşan geçide karşı uyarır; mavi levha geçidin tam yerini bildirir.',
  },
  {
    a: 'park-yasak',
    b: 'duraklama-yasak',
    difference:
      'Park yasağında kısa duraklama serbesttir; duraklama yasağında durmak dahi yasaktır.',
  },
  {
    a: 'yol-daralmasi',
    b: 'iki-yonlu-trafik',
    difference: 'Daralmada yol fiziksel daralır; iki yönlü trafikte karşı yön trafiği başlar.',
  },
  {
    a: 'azami-hiz-50',
    b: 'asgari-hiz-30',
    difference: 'Kırmızı halka EN ÇOK hızı sınırlar; mavi disk EN AZ hızı zorunlu kılar.',
  },
];

export function confusionsFor(signId: string): Array<{ other: TrafficSign; difference: string }> {
  const out: Array<{ other: TrafficSign; difference: string }> = [];
  for (const c of SIGN_CONFUSIONS) {
    const otherId = c.a === signId ? c.b : c.b === signId ? c.a : null;
    if (!otherId) continue;
    const other = signById(otherId);
    if (other) out.push({ other, difference: c.difference });
  }
  return out;
}

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

/** İşaretle ilgili banka sorularını grounded bulur (ad/anahtar kelime, soru kökünde). */
export function questionsForSign(sign: TrafficSign, limit = 2): Question[] {
  const terms = [sign.name, ...sign.keywords].map(norm).filter((t) => t.length >= 4);
  const out: Question[] = [];
  for (const q of allQuestions()) {
    if (out.length >= limit) break;
    const stem = norm(q.stem);
    if (terms.some((t) => stem.includes(t))) out.push(q);
  }
  return out;
}

/** Galeriden detaya: katalogdaki tüm kimlikler (statik sayfa üretimi). */
export function allSignIds(): string[] {
  return SIGNS.map((s) => s.id);
}
