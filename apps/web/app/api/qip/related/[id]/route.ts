import { guarded, json } from '@/lib/server/auth';
import { relatedContent } from '@/lib/qip';

/**
 * Grafik-güdümlü ilgili içerik (öneri) — bir soru için bağlı ders/işaret/parça/senaryo + kardeş
 * sorular. BANK_QUESTİON Part 3 ("supports future recommendations"). Yalnız halka açık içerik
 * referansları döner → kimlik doğrulaması gerekmez.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const parts = new URL(req.url).pathname.split('/');
  const id = decodeURIComponent(parts[parts.length - 1] ?? '');
  const rc = relatedContent(id);
  const map = (ns: { ref: string; label: string }[]) =>
    ns.map((n) => ({ ref: n.ref, label: n.label }));
  return json({
    id,
    lessons: map(rc.lessons),
    signs: map(rc.signs),
    parts: map(rc.parts),
    scenarios: map(rc.scenarios),
    questions: map(rc.questions),
  });
});
