/**
 * Görsel quiz üreticisi (Program 2 · Faz 5) — saf, test edilebilir.
 * Havuz: trafik işaretleri (özgün SVG) + fotoğraflı araç bileşenleri.
 * Çeldiriciler AYNI kategori/sistemden seçilir (öğretici zorluk).
 */
import { SIGNS, CATEGORY_LABEL, type TrafficSign } from '@/content/signs';
import { VEHICLE_PARTS, SYSTEM_LABEL, type VehiclePart } from '@/content/vehicle';

export type Rng = () => number;

export interface VisualQuizRound {
  kind: 'sign' | 'part';
  /** Katalog kimliği (işaret id / bileşen id) — zayıf deste bu kimlikle çalışır. */
  itemId: string;
  /** Bileşen turlarında gösterilecek fotoğrafın manifest kimliği. */
  assetId?: string;
  prompt: string;
  options: string[]; // 4 seçenek (ad)
  answerIndex: number;
  /** Doğru cevabın öğretici açıklaması. */
  explanation: string;
  /** Grup etiketi (kategori/sistem) — arayüz rozeti. */
  groupLabel: string;
}

function shuffle<T>(arr: T[], rng: Rng): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j]!, a[i]!];
  }
  return a;
}

function signRound(sign: TrafficSign, rng: Rng): VisualQuizRound {
  const sameCat = SIGNS.filter((s) => s.category === sign.category && s.id !== sign.id);
  const others = SIGNS.filter((s) => s.category !== sign.category && s.id !== sign.id);
  const distractors = shuffle([...shuffle(sameCat, rng).slice(0, 3), ...shuffle(others, rng)], rng)
    .slice(0, 3)
    .map((s) => s.name);
  const options = shuffle([sign.name, ...distractors], rng);
  return {
    kind: 'sign',
    itemId: sign.id,
    prompt: 'Bu işaret nedir?',
    options,
    answerIndex: options.indexOf(sign.name),
    explanation: sign.meaning,
    groupLabel: CATEGORY_LABEL[sign.category],
  };
}

function partRound(part: VehiclePart, rng: Rng): VisualQuizRound {
  const sameSys = VEHICLE_PARTS.filter((p) => p.system === part.system && p.id !== part.id);
  const others = VEHICLE_PARTS.filter((p) => p.system !== part.system && p.id !== part.id);
  const distractors = shuffle([...shuffle(sameSys, rng).slice(0, 3), ...shuffle(others, rng)], rng)
    .slice(0, 3)
    .map((p) => p.name);
  const options = shuffle([part.name, ...distractors], rng);
  return {
    kind: 'part',
    itemId: part.id,
    assetId: part.photo,
    prompt: 'Bu araç bileşeni nedir?',
    options,
    answerIndex: options.indexOf(part.name),
    explanation: part.desc,
    groupLabel: SYSTEM_LABEL[part.system],
  };
}

/** Fotoğrafı olan bileşenler + tüm işaretler = quiz havuzu. */
export function quizPool(): Array<{ kind: 'sign' | 'part'; id: string }> {
  return [
    ...SIGNS.map((s) => ({ kind: 'sign' as const, id: s.id })),
    ...VEHICLE_PARTS.filter((p) => p.photo).map((p) => ({ kind: 'part' as const, id: p.id })),
  ];
}

/** Tek tur üret; `only` verilirse o öğeden (zayıf tekrar modu). */
export function buildRound(
  rng: Rng = Math.random,
  only?: { kind: 'sign' | 'part'; id: string }
): VisualQuizRound | null {
  if (only) {
    if (only.kind === 'sign') {
      const s = SIGNS.find((x) => x.id === only.id);
      return s ? signRound(s, rng) : null;
    }
    const p = VEHICLE_PARTS.find((x) => x.id === only.id);
    return p ? partRound(p, rng) : null;
  }
  const pool = quizPool();
  const pick = pool[Math.floor(rng() * pool.length)]!;
  return buildRound(rng, pick);
}
