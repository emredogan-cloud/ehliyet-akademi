import { describe, it, expect } from 'vitest';
import { eq, and } from 'drizzle-orm';
import { freshTestDb, users, sessions, userState, purchases } from './index';

const U = { id: 'u-1', email: 'test@ea.dev', name: 'Test', passwordHash: 'h' };

describe('@ea/db (PGlite üzerinde CRUD)', () => {
  it('bootstrap + kullanıcı oluştur/oku; email benzersiz', async () => {
    const db = await freshTestDb();
    await db.insert(users).values(U);
    const got = await db.select().from(users).where(eq(users.email, U.email));
    expect(got[0]?.id).toBe('u-1');
    await expect(db.insert(users).values({ ...U, id: 'u-2' })).rejects.toThrow(); // unique email
  });

  it('oturum: çok-cihaz (2 satır) + cascade delete', async () => {
    const db = await freshTestDb();
    await db.insert(users).values(U);
    const exp = new Date(Date.now() + 86400000);
    await db.insert(sessions).values([
      { tokenHash: 't1', userId: 'u-1', expiresAt: exp, userAgent: 'cihaz-1' },
      { tokenHash: 't2', userId: 'u-1', expiresAt: exp, userAgent: 'cihaz-2' },
    ]);
    const s = await db.select().from(sessions).where(eq(sessions.userId, 'u-1'));
    expect(s.length).toBe(2);
    await db.delete(users).where(eq(users.id, 'u-1'));
    expect((await db.select().from(sessions)).length).toBe(0);
  });

  it('user_state: upsert + jsonb değer', async () => {
    const db = await freshTestDb();
    await db.insert(users).values(U);
    const val = { current: 3, best: 5, lastDay: '2026-07-15' };
    await db.insert(userState).values({ userId: 'u-1', key: 'ea:streak:v1', value: val });
    await db
      .insert(userState)
      .values({ userId: 'u-1', key: 'ea:streak:v1', value: { ...val, current: 4 } })
      .onConflictDoUpdate({
        target: [userState.userId, userState.key],
        set: { value: { ...val, current: 4 }, updatedAt: new Date() },
      });
    const got = await db
      .select()
      .from(userState)
      .where(and(eq(userState.userId, 'u-1'), eq(userState.key, 'ea:streak:v1')));
    expect((got[0]?.value as { current: number }).current).toBe(4);
  });

  it('purchases: tek-seferlik sahiplik; aynı ürün ikinci kez eklenemez (unique)', async () => {
    const db = await freshTestDb();
    await db.insert(users).values(U);
    await db
      .insert(purchases)
      .values({ id: 'p1', userId: 'u-1', productId: 'komple-b', priceTRY: 449 });
    await expect(
      db.insert(purchases).values({ id: 'p2', userId: 'u-1', productId: 'komple-b', priceTRY: 449 })
    ).rejects.toThrow();
    const list = await db.select().from(purchases).where(eq(purchases.userId, 'u-1'));
    expect(list.length).toBe(1);
    expect(list[0]?.provider).toBe('mock');
  });
});
