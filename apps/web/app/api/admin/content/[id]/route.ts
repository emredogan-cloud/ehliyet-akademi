import { requireRole, json, guarded } from '@/lib/server/auth';
import { getContent, updateContent, transitionContent } from '@/lib/server/cms';
import type { ContentStatus } from '@ea/db';

function idOf(req: Request): string {
  const parts = new URL(req.url).pathname.split('/');
  return parts[parts.length - 1] ?? '';
}

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  const item = await getContent(idOf(req));
  if (!item) return json({ error: 'Bulunamadı.' }, { status: 404 });
  return json({ item });
});

export const PUT = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const res = await updateContent(user, idOf(req), body as Parameters<typeof updateContent>[2]);
  if (!res.ok) return json({ errors: res.errors }, { status: 400 });
  return json({ ok: true, version: res.version });
});

/** İş-akışı geçişi: { to: 'in_review' | 'approved' | 'published' | 'retired' | 'draft' } */
export const PATCH = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  let body: { to?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const res = await transitionContent(user, idOf(req), (body.to ?? '') as ContentStatus);
  if (!res.ok) return json({ errors: res.errors }, { status: 400 });
  return json({ ok: true, status: res.status });
});
