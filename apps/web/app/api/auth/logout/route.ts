import { destroySession, sessionClearCookie, json, guarded } from '@/lib/server/auth';

export const POST = guarded(async (req: Request): Promise<Response> => {
  await destroySession(req);
  return json({ ok: true }, { setCookie: sessionClearCookie() });
});
