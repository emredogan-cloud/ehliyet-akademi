/**
 * Saklama temizleme işi — sınır davranışı.
 *
 * ## Neden bu test var
 *
 * `/gizlilik` ve `/hesap-silme` artık **sayı** veriyor: "kimliksiz kullanım olayları 365 gün".
 * Yayımlanmış bir sayfada süre yazıp uygulamamak, hiç süre yazmamaktan daha kötüdür — ilki yanlış
 * beyandır. Bu test, sayfadaki cümlenin sunucuda gerçekten karşılığı olduğunu kanıtlar.
 *
 * Sınav edilen asıl şey **eşiğin iki yanı**: süresi dolan kayıt silinmeli, dolmayan KALMALI.
 * Yalnız "silme çalışıyor" testi, eşiği 0'a çeken bir hatayı yakalayamazdı.
 */
import { describe, it, expect } from 'vitest';
import { eq } from 'drizzle-orm';
import { analyticsEvents, communityReports, errorReports, getDb, users } from '@ea/db';
import { newId } from '@/lib/server/auth';
import { purgeExpiredData, retentionBacklog } from './retention-purge';
import { RETENTION_DEFAULT_DAYS } from '@/lib/retention';

const NOW = new Date('2026-08-11T00:00:00.000Z');
const day = 24 * 60 * 60 * 1000;
const ago = (days: number): Date => new Date(NOW.getTime() - days * day);

async function seedUser(db: Awaited<ReturnType<typeof getDb>>): Promise<string> {
  const id = newId();
  await db.insert(users).values({
    id,
    email: `retention-${id}@ea.dev`,
    name: 'Saklama',
    passwordHash: 'scrypt$x$y',
  });
  return id;
}

describe('purgeExpiredData', () => {
  it('süresi dolan analitik olayı siler, dolmayanı KORUR', async () => {
    const db = await getDb();
    const oldId = newId();
    const freshId = newId();
    const d = RETENTION_DEFAULT_DAYS.analytics;

    await db.insert(analyticsEvents).values([
      { id: oldId, name: 'eski', at: ago(d + 1), receivedAt: ago(d + 1) },
      { id: freshId, name: 'yeni', at: ago(d - 1), receivedAt: ago(d - 1) },
    ]);

    await purgeExpiredData(db, NOW, {});

    const remaining = await db
      .select({ id: analyticsEvents.id })
      .from(analyticsEvents)
      .where(eq(analyticsEvents.id, oldId));
    const kept = await db
      .select({ id: analyticsEvents.id })
      .from(analyticsEvents)
      .where(eq(analyticsEvents.id, freshId));

    expect(remaining).toHaveLength(0);
    expect(kept).toHaveLength(1);
  });

  it('süresi dolan hata kaydını siler, dolmayanı KORUR', async () => {
    const db = await getDb();
    const oldId = newId();
    const freshId = newId();
    const d = RETENTION_DEFAULT_DAYS.errorReports;

    await db.insert(errorReports).values([
      {
        id: oldId,
        kind: 'flutter',
        fingerprint: 'f1',
        message: 'eski',
        at: ago(d + 1),
        receivedAt: ago(d + 1),
      },
      {
        id: freshId,
        kind: 'flutter',
        fingerprint: 'f2',
        message: 'yeni',
        at: ago(d - 1),
        receivedAt: ago(d - 1),
      },
    ]);

    await purgeExpiredData(db, NOW, {});

    expect(
      await db.select({ id: errorReports.id }).from(errorReports).where(eq(errorReports.id, oldId))
    ).toHaveLength(0);
    expect(
      await db
        .select({ id: errorReports.id })
        .from(errorReports)
        .where(eq(errorReports.id, freshId))
    ).toHaveLength(1);
  });

  // İnceleme bitmeden silmek, moderasyon kaydını incelemenin ortasında yok etmek olurdu.
  it('İNCELEMEDEKİ şikâyeti süresi dolsa bile silmez', async () => {
    const db = await getDb();
    const reporter = await seedUser(db);
    const target = await seedUser(db);
    const openId = newId();
    const closedId = newId();
    const d = RETENTION_DEFAULT_DAYS.moderation;

    await db.insert(communityReports).values([
      {
        id: openId,
        reporterId: reporter,
        targetUserId: target,
        reason: 'spam',
        status: 'open',
        createdAt: ago(d + 10),
      },
      {
        id: closedId,
        reporterId: reporter,
        targetUserId: target,
        reason: 'spam',
        status: 'reviewed',
        createdAt: ago(d + 10),
      },
    ]);

    await purgeExpiredData(db, NOW, {});

    expect(
      await db
        .select({ id: communityReports.id })
        .from(communityReports)
        .where(eq(communityReports.id, openId))
    ).toHaveLength(1);
    expect(
      await db
        .select({ id: communityReports.id })
        .from(communityReports)
        .where(eq(communityReports.id, closedId))
    ).toHaveLength(0);
  });

  it('ortam değişkeniyle kısaltılan süre hemen uygulanır', async () => {
    const db = await getDb();
    const id = newId();
    // Varsayılan 365 gün olsaydı KALIRDI; 30 güne çekilince silinmeli.
    await db
      .insert(analyticsEvents)
      .values({ id, name: 'ayarli', at: ago(45), receivedAt: ago(45) });

    await purgeExpiredData(db, NOW, { RETENTION_ANALYTICS_DAYS: '30' });

    expect(
      await db
        .select({ id: analyticsEvents.id })
        .from(analyticsEvents)
        .where(eq(analyticsEvents.id, id))
    ).toHaveLength(0);
  });

  it('iş idempotenttir — ikinci çalıştırma silecek yeni kayıt bulmaz', async () => {
    const db = await getDb();
    await db.insert(analyticsEvents).values({
      id: newId(),
      name: 'tekrar',
      at: ago(400),
      receivedAt: ago(400),
    });

    const first = await purgeExpiredData(db, NOW, {});
    const second = await purgeExpiredData(db, NOW, {});

    expect(first.analyticsEvents).toBeGreaterThan(0);
    expect(second.analyticsEvents).toBe(0);
  });
});

describe('retentionBacklog', () => {
  it('temizlenmeyi bekleyen kayıt sayısını bildirir ve silmeden sonra sıfırlanır', async () => {
    const db = await getDb();
    await db.insert(analyticsEvents).values({
      id: newId(),
      name: 'birikmis',
      at: ago(500),
      receivedAt: ago(500),
    });

    const before = await retentionBacklog(db, NOW, {});
    expect(before.analyticsEvents).toBeGreaterThan(0);

    await purgeExpiredData(db, NOW, {});

    const after = await retentionBacklog(db, NOW, {});
    expect(after.analyticsEvents).toBe(0);
  });
});
