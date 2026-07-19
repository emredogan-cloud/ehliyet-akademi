import { eq } from 'drizzle-orm';
import { getDb, userState } from '@ea/db';
import { getSessionUser, json, guarded } from '@/lib/server/auth';

/** Senkronlanabilir anahtarlar (Epic 4) — istemci ea:* deposunun sunucu yansıması. */
const ALLOWED_KEYS = new Set([
  'ea:answers:v1',
  'ea:cards:v1',
  'ea:streak:v1',
  'ea:readiness:v1',
  'ea:entitlements:v1',
  'ea:examQuota:v1',
  'ea:aiQuota:v1',
  'ea:counters:v1',
  'ea:lessonsViewed:v1',
  'ea:avatar:v1',
  'ea:theme',
]);
const MAX_VALUE_BYTES = 512 * 1024; // kayıt başına üst sınır

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });
  const db = await getDb();
  const rows = await db
    .select({ key: userState.key, value: userState.value, updatedAt: userState.updatedAt })
    .from(userState)
    .where(eq(userState.userId, user.id));
  return json({ items: rows });
});

export const PUT = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  let body: { items?: Array<{ key: string; value: unknown }> };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const items = (body.items ?? []).filter(
    (it) =>
      it &&
      typeof it.key === 'string' &&
      ALLOWED_KEYS.has(it.key) &&
      JSON.stringify(it.value ?? null).length <= MAX_VALUE_BYTES
  );
  if (!items.length) return json({ ok: true, saved: 0 });

  const db = await getDb();
  for (const it of items) {
    await db
      .insert(userState)
      .values({ userId: user.id, key: it.key, value: it.value as object })
      .onConflictDoUpdate({
        target: [userState.userId, userState.key],
        set: { value: it.value as object, updatedAt: new Date() },
      });
  }
  return json({ ok: true, saved: items.length });
});
