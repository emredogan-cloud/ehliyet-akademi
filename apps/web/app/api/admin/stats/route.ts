import { requireRole, json, guarded } from '@/lib/server/auth';
import { adminStats } from '@/lib/server/cms';

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  return json({ stats: await adminStats() });
});
