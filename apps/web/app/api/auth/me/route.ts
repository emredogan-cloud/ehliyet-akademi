import { getSessionUser, json, guarded } from '@/lib/server/auth';

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ user: null }, { status: 401 });
  return json({ user });
});
