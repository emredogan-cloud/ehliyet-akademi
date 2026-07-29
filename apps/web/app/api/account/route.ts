import { eq } from 'drizzle-orm';
import { getDb, users } from '@ea/db';
import {
  getSessionUser,
  json,
  guarded,
  sessionClearCookie,
  verifyPassword,
} from '@/lib/server/auth';
import { logger } from '@/lib/server/logger';

/**
 * Hesabı sil (Sprint 4 — KVKK m.7 / GDPR "silme hakkı"). Kullanıcı satırı silinir;
 * FK ON DELETE CASCADE ile oturumlar, satın almalar, durum ve tokenlar da silinir.
 * Oturum çerezi temizlenir.
 *
 * ## Faz 5 — YENİDEN KİMLİK DOĞRULAMA
 *
 * Silme geri alınamaz ve oturum 30 gün açık kalıyor. Yalnız oturuma güvenmek, kilidi açık bırakılan
 * bir telefonu hesabı yok etmek için yeterli kılardı. Bu yüzden parolası OLAN hesaplarda parola
 * yeniden istenir.
 *
 * Parolası olmayan hesap da var: Google ile giren kullanıcıya `google$no-password` sentinel'i
 * yazılıyor (`api/auth/google`). Ondan parola istemek imkânsızı istemek olurdu — bu yüzden kural
 * "parola varsa zorunlu"dur, "her koşulda zorunlu" değil. O hesaplarda ikinci onay istemci
 * tarafında e-posta yazdırarak alınır (GitHub'ın kalıbı).
 */

/** Parolası gerçekten olan hesap mı? Google ile açılanlarda sentinel yazılıdır. */
function hasRealPassword(passwordHash: string): boolean {
  return passwordHash.startsWith('scrypt$');
}

/**
 * Silmeden ÖNCE: bu hesap parola ister mi?
 *
 * İstemci hangi onay adımını göstereceğini bilmek zorunda; bunu tahmin etmesi (ör. e-posta
 * alan adına bakması) yanlış ekran göstermesine yol açardı.
 */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const rows = await db
    .select({ passwordHash: users.passwordHash })
    .from(users)
    .where(eq(users.id, user.id));
  const row = rows[0];
  if (!row) return json({ error: 'Hesap bulunamadı.' }, { status: 404 });

  return json({ requiresPassword: hasRealPassword(row.passwordHash), email: user.email });
});

export const DELETE = guarded(async (req: Request): Promise<Response> => {
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const db = await getDb();
  const rows = await db
    .select({ passwordHash: users.passwordHash })
    .from(users)
    .where(eq(users.id, user.id));
  const row = rows[0];
  if (!row) return json({ error: 'Hesap bulunamadı.' }, { status: 404 });

  if (hasRealPassword(row.passwordHash)) {
    // Gövde OLMAYABİLİR (eski istemciler DELETE'i gövdesiz gönderiyordu) → çözümleme hatası
    // "parola verilmedi" ile aynı sonuca varır; ayrı bir 400 üretmeye gerek yok.
    let password = '';
    try {
      const body = (await req.json()) as { password?: unknown };
      if (typeof body?.password === 'string') password = body.password;
    } catch {
      password = '';
    }

    if (!password) {
      return json(
        { error: 'Devam etmek için parolanı gir.', requiresPassword: true },
        { status: 400 }
      );
    }
    if (!verifyPassword(password, row.passwordHash)) {
      // 403: kimlik doğrulandı (oturum geçerli) ama bu işlem için yetkilendirme başarısız.
      logger.info('account_delete_bad_password', { userId: user.id });
      return json({ error: 'Parola hatalı.', requiresPassword: true }, { status: 403 });
    }
  }

  await db.delete(users).where(eq(users.id, user.id));
  logger.info('account_deleted', { userId: user.id });
  return json({ ok: true }, { setCookie: sessionClearCookie() });
});
