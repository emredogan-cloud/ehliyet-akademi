import { requireRole, json, guarded } from '@/lib/server/auth';
import { listAudit } from '@/lib/server/cms';

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin');
  if (user instanceof Response) return user;
  return json({ items: await listAudit(100) });
});
