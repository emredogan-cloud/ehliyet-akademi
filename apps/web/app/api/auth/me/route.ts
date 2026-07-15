import { getSessionUser, json } from '@/lib/server/auth';

export async function GET(req: Request): Promise<Response> {
  const user = await getSessionUser(req);
  if (!user) return json({ user: null }, { status: 401 });
  return json({ user });
}
