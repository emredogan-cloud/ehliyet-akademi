import { requireRole, json, guarded } from '@/lib/server/auth';
import { listUsers, setUserRole } from '@/lib/server/cms';

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin');
  if (user instanceof Response) return user;
  return json({ items: await listUsers() });
});

export const PUT = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin');
  if (user instanceof Response) return user;
  let body: { userId?: string; role?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  if (!body.userId || !['user', 'editor', 'admin'].includes(body.role ?? ''))
    return json({ error: 'userId ve geçerli role zorunlu.' }, { status: 400 });
  if (body.userId === user.id && body.role !== 'admin')
    return json(
      { error: 'Kendi admin yetkini düşüremezsin (kilitlenme koruması).' },
      { status: 400 }
    );
  await setUserRole(user, body.userId, body.role as 'user' | 'editor' | 'admin');
  return json({ ok: true });
});
