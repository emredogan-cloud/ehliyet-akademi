/**
 * Arama soyutlaması (Sprint 2, Epic 5 / ROADMAP Faz 28).
 * Sözleşme sabittir; Meilisearch/Typesense/Algolia adaptörü ENV ile takılır —
 * uygulama kodu değişmez. Varsayılan: yerel (bellek-içi) sağlayıcı.
 */
import { SUBJECT_LABEL } from '@ea/content-schema';
import { allQuestions } from '@ea/question-bank';
import { LESSONS } from '@/content/lessons';

export interface SearchDoc {
  id: string;
  type: string; // lesson | question | article | ...
  title: string;
  status?: string;
}

export interface SearchHit {
  id: string;
  type: string;
  title: string;
  snippet: string;
  href: string;
}

export interface SearchProvider {
  readonly name: string;
  /** Yayın hattı kancası: yayınlanan/emekliye ayrılan içerikler bildirilir. */
  indexContent(docs: SearchDoc[]): Promise<void>;
  search(q: string, opts?: { limit?: number }): Promise<SearchHit[]>;
}

function norm(s: string): string {
  return s
    .toLocaleLowerCase('tr')
    .replace(/[çğıöşü]/g, (c) => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' })[c] ?? c);
}

/** Yerel sağlayıcı: statik içerik üzerinde normalize tarama (harici servis yok). */
export class LocalSearchProvider implements SearchProvider {
  readonly name = 'local';
  private extra: SearchDoc[] = [];

  async indexContent(docs: SearchDoc[]): Promise<void> {
    // Yerel modda kalıcı dış indeks yok; yayınlananları oturum-içi kayda alırız.
    for (const d of docs) {
      this.extra = this.extra.filter((x) => x.id !== d.id);
      if (d.status === 'published') this.extra.push(d);
    }
  }

  async search(q: string, opts?: { limit?: number }): Promise<SearchHit[]> {
    const nq = norm(q.trim());
    const limit = opts?.limit ?? 20;
    if (nq.length < 2) return [];
    const hits: SearchHit[] = [];

    for (const l of LESSONS) {
      const hay = norm(
        l.title + ' ' + l.summary + ' ' + l.sections.map((s) => s.heading + ' ' + s.body).join(' ')
      );
      if (hay.includes(nq))
        hits.push({
          id: l.id,
          type: 'lesson',
          title: l.title,
          snippet: l.summary,
          href: `/dersler/${l.slug}`,
        });
    }
    for (const x of allQuestions()) {
      if (norm(x.stem + ' ' + x.topic + ' ' + x.explanation).includes(nq))
        hits.push({
          id: x.id,
          type: 'question',
          title: x.stem,
          snippet: `${SUBJECT_LABEL[x.subject]} · cevap: ${x.options[x.answerIndex]}`,
          href: '/calis',
        });
    }
    for (const d of this.extra) {
      if (norm(d.title).includes(nq))
        hits.push({
          id: d.id,
          type: d.type,
          title: d.title,
          snippet: 'Yayındaki içerik',
          href: '/makaleler',
        });
    }
    return hits.slice(0, limit);
  }
}

let provider: SearchProvider | null = null;

/** Fabrika: SEARCH_PROVIDER ENV'i gelecekte meili/typesense/algolia adaptörünü seçer. */
export function getSearchProvider(): SearchProvider {
  if (provider) return provider;
  // if (process.env.SEARCH_PROVIDER === 'meilisearch') provider = new MeiliProvider(...)
  provider = new LocalSearchProvider();
  return provider;
}
