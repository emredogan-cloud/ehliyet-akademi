/**
 * QIP — Faz 2 · Yineleme Tespiti (BANK_QUESTİON Part 6).
 *
 * İki katman: (1) TAM yineleme — Faz 1 parmak izi (fingerprint) eşitliği; (2) YAKIN yineleme —
 * jeton kümesi Jaccard benzerliği. Verimlilik: ters indeksle (kelime→sorular) aday üretimi +
 * paylaşılan-jeton eşiğiyle budama → O(n²) taramadan kaçınır. Kümeleme: birleşim-bul (union-find).
 * Dış servis/embedding yok; deterministik. "Merge variants" için küme temsilcisi seçilir.
 */
import { foldText, type NormalizedQuestion } from '@ea/content-schema';

/** Türkçe durak kelimeler (katlanmış) — jeton kümesinden çıkarılır. */
const STOPWORDS = new Set(
  [
    'bir',
    've',
    'ile',
    'icin',
    'bu',
    'su',
    'de',
    'da',
    'ne',
    'mi',
    'mu',
    'ya',
    'en',
    'cok',
    'daha',
    'gibi',
    'olan',
    'olarak',
    'nedir',
    'hangisi',
    'hangi',
    'asagidaki',
    'asagidakilerden',
    'asagidakilerin',
    'yapilir',
    'edilir',
    'nasil',
    'kac',
    'ise',
    'ki',
    'the',
    'veya',
    'ya da',
    'degildir',
    'olur',
    'sonra',
    'once',
    'gerekir',
  ].map((s) => s)
);

/** Bir sorunun anlamlı jeton kümesi (stem + doğru cevap; durak kelimeler ve kısa jetonlar hariç). */
export function tokenSet(
  q: Pick<NormalizedQuestion, 'stem' | 'options' | 'answerIndex'>
): Set<string> {
  const words = foldText(q.stem).split(' ');
  const out = new Set<string>();
  for (const w of words) {
    if (w.length >= 3 && !STOPWORDS.has(w)) out.add(w);
  }
  return out;
}

/** İki küme Jaccard benzerliği |A∩B| / |A∪B|. */
export function jaccard(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 || b.size === 0) return 0;
  let inter = 0;
  const [small, large] = a.size <= b.size ? [a, b] : [b, a];
  for (const x of small) if (large.has(x)) inter++;
  return inter / (a.size + b.size - inter);
}

export interface NearDupPair {
  a: string;
  b: string;
  similarity: number;
}

export interface DedupReport {
  total: number;
  exactDuplicateGroups: number;
  exactDuplicateRecords: number;
  nearDuplicatePairs: number;
  nearDuplicateClusters: number;
  /** (tam-fazla + yakın-küme-fazla) / toplam, yüzde 0–100. */
  duplicateRatePct: number;
  /** id → yakın-yineleme komşu sayısı (kalite skoru için). */
  nearDuplicateCounts: Record<string, number>;
  /** En yüksek benzerlikli örnek çiftler (rapor için). */
  topPairs: NearDupPair[];
}

const SHARED_TOKEN_PRUNE = 4; // en az bu kadar ortak jeton paylaşan çiftler karşılaştırılır

/** Birleşim-bul (union-find) — yakın-yineleme kümeleri + soru aileleri için. */
export class UnionFind {
  private parent: number[];
  constructor(n: number) {
    this.parent = Array.from({ length: n }, (_, i) => i);
  }
  find(x: number): number {
    while (this.parent[x] !== x) {
      this.parent[x] = this.parent[this.parent[x]!]!;
      x = this.parent[x]!;
    }
    return x;
  }
  union(a: number, b: number): void {
    const ra = this.find(a);
    const rb = this.find(b);
    if (ra !== rb) this.parent[ra] = rb;
  }
}

/**
 * Yineleme raporu. `threshold` = yakın-yineleme Jaccard eşiği (varsayılan 0.82 — sıkı; yeniden
 * ifade edilmiş ama aynı içerik). Karşılaştırma yalnız aynı ders içinde yapılır (dersler arası
 * yineleme olası değil) + ters indeksle budanır.
 */
export function dedupReport(pool: NormalizedQuestion[], threshold = 0.82): DedupReport {
  const n = pool.length;

  // (1) Tam yineleme — parmak izi.
  const fpGroups = new Map<string, string[]>();
  for (const q of pool) {
    const g = fpGroups.get(q.fingerprint) ?? [];
    g.push(q.id);
    fpGroups.set(q.fingerprint, g);
  }
  let exactDuplicateGroups = 0;
  let exactDuplicateRecords = 0;
  for (const g of fpGroups.values()) {
    if (g.length > 1) {
      exactDuplicateGroups++;
      exactDuplicateRecords += g.length - 1;
    }
  }

  // (2) Yakın yineleme — jeton kümeleri + ters indeks + budama.
  const sets = pool.map(tokenSet);
  const invIndex = new Map<string, number[]>(); // kelime → soru indeksleri (aynı ders)
  for (let i = 0; i < n; i++) {
    for (const w of sets[i]!) {
      const arr = invIndex.get(w);
      if (arr) arr.push(i);
      else invIndex.set(w, [i]);
    }
  }

  const uf = new UnionFind(n);
  const pairs: NearDupPair[] = [];
  const nearCount = new Array<number>(n).fill(0);
  const seenPair = new Set<string>();

  for (let i = 0; i < n; i++) {
    // aday üret: i ile jeton paylaşan j>i'leri say
    const shared = new Map<number, number>();
    for (const w of sets[i]!) {
      for (const j of invIndex.get(w)!) {
        if (j <= i) continue;
        if (pool[j]!.subject !== pool[i]!.subject) continue;
        shared.set(j, (shared.get(j) ?? 0) + 1);
      }
    }
    for (const [j, c] of shared) {
      if (c < SHARED_TOKEN_PRUNE) continue;
      const sim = jaccard(sets[i]!, sets[j]!);
      if (sim >= threshold) {
        const key = `${i}:${j}`;
        if (!seenPair.has(key)) {
          seenPair.add(key);
          pairs.push({ a: pool[i]!.id, b: pool[j]!.id, similarity: Math.round(sim * 100) / 100 });
          nearCount[i]!++;
          nearCount[j]!++;
          uf.union(i, j);
        }
      }
    }
  }

  // Yakın-yineleme kümeleri (boyutu >1 olanlar).
  const clusterSizes = new Map<number, number>();
  for (let i = 0; i < n; i++) {
    if (nearCount[i]! > 0) {
      const r = uf.find(i);
      clusterSizes.set(r, (clusterSizes.get(r) ?? 0) + 1);
    }
  }
  let nearDuplicateClusters = 0;
  let nearClusterExtra = 0;
  for (const size of clusterSizes.values()) {
    if (size > 1) {
      nearDuplicateClusters++;
      nearClusterExtra += size - 1;
    }
  }

  const nearDuplicateCounts: Record<string, number> = {};
  for (let i = 0; i < n; i++)
    if (nearCount[i]! > 0) nearDuplicateCounts[pool[i]!.id] = nearCount[i]!;

  const duplicateRatePct = n
    ? Math.round(((exactDuplicateRecords + nearClusterExtra) / n) * 1000) / 10
    : 0;

  const topPairs = pairs.sort((x, y) => y.similarity - x.similarity).slice(0, 20);

  return {
    total: n,
    exactDuplicateGroups,
    exactDuplicateRecords,
    nearDuplicatePairs: pairs.length,
    nearDuplicateClusters,
    duplicateRatePct,
    nearDuplicateCounts,
    topPairs,
  };
}
