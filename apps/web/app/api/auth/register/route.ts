import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import {
  hashPassword,
  createSession,
  sessionSetCookie,
  json,
  validEmail,
  newId,
} from '@/lib/server/auth';

export async function POST(req: Request): Promise<Response> {
  let body: { email?: string; password?: string; name?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const email = (body.email ?? '').trim().toLowerCase();
  const password = body.password ?? '';
  const name = (body.name ?? '').trim().slice(0, 80);

  if (!validEmail(email)) return json({ error: 'Geçerli bir e-posta girin.' }, { status: 400 });
  if (password.length < 8)
    return json({ error: 'Parola en az 8 karakter olmalı.' }, { status: 400 });

  const db = await getDb();
  const existing = await db.select({ id: users.id }).from(users).where(eq(users.email, email));
  if (existing.length)
    return json({ error: 'Bu e-posta ile zaten bir hesap var.' }, { status: 409 });

  const id = newId();
  await db.insert(users).values({ id, email, name, passwordHash: hashPassword(password) });
  const token = await createSession(db, id, req.headers.get('user-agent') ?? '');
  return json({ user: { id, email, name } }, { status: 201, setCookie: sessionSetCookie(token) });
}
