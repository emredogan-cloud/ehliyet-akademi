import { destroySession, sessionClearCookie, json } from '@/lib/server/auth';

export async function POST(req: Request): Promise<Response> {
  await destroySession(req);
  return json({ ok: true }, { setCookie: sessionClearCookie() });
}
