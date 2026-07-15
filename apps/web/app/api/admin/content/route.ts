import { requireRole, json, guarded } from '@/lib/server/auth';
import { createContent, listContent } from '@/lib/server/cms';

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  const u = new URL(req.url);
  const items = await listContent({
    type: u.searchParams.get('type') ?? undefined,
    status: u.searchParams.get('status') ?? undefined,
    q: u.searchParams.get('q') ?? undefined,
  });
  return json({ items });
});

export const POST = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const res = await createContent(user, body as Parameters<typeof createContent>[1]);
  if (!res.ok) return json({ errors: res.errors }, { status: 400 });
  return json({ ok: true, id: res.id }, { status: 201 });
});
