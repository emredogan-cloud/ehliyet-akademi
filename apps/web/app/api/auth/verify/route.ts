import { eq } from 'drizzle-orm';
import { getDb, users, emailVerificationTokens } from '@ea/db';
import { getSessionUser, newToken, sha256, json, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { getEmailProvider, emailConfigured, verificationEmail } from '@/lib/server/email';

/**
 * E-posta doğrulama (Sprint 4).
 * - Gövdede { token } varsa: doğrulamayı TAMAMLA (users.email_verified = true).
 * - Aksi halde (oturumlu): yeni doğrulama tokenı üret + e-posta gönder. E-posta servisi
 *   yoksa token yanıtta döner (devToken — forgot ile aynı dürüst mod).
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'verify', limit: 8, windowMs: 60_000 });
  if (limited) return limited;

  let body: { token?: string };
  try {
    body = await req.json();
  } catch {
    body = {};
  }

  const db = await getDb();

  // 1) Doğrulamayı tamamla
  if (body.token) {
    const rows = await db
      .select()
      .from(emailVerificationTokens)
      .where(eq(emailVerificationTokens.tokenHash, sha256(body.token)));
    const row = rows[0];
    if (!row || row.expiresAt.getTime() < Date.now())
      return json({ error: 'Doğrulama bağlantısı geçersiz veya süresi dolmuş.' }, { status: 400 });
    await db.update(users).set({ emailVerified: true }).where(eq(users.id, row.userId));
    await db.delete(emailVerificationTokens).where(eq(emailVerificationTokens.userId, row.userId));
    return json({ ok: true, verified: true });
  }

  // 2) Yeni doğrulama e-postası gönder
  const user = await getSessionUser(req);
  if (!user) return json({ error: 'Oturum gerekli.' }, { status: 401 });

  const token = newToken();
  await db.insert(emailVerificationTokens).values({
    tokenHash: sha256(token),
    userId: user.id,
    expiresAt: new Date(Date.now() + 24 * 3600_000), // 24 saat
  });

  const base = process.env.NEXT_PUBLIC_SITE_URL ?? '';
  const link = `${base}/dogrula?token=${token}`;
  if (emailConfigured()) {
    await getEmailProvider().send(user.email, verificationEmail(link));
    return json({ ok: true, sent: true });
  }
  // GÜVENLİK (C1): token yanıtta YALNIZ geliştirmede döner. Üretimde e-posta yapılandırılmamışsa
  // token ASLA sızdırılmaz (aksi halde hesap ele geçirme). Üretimde RESEND_API_KEY zorunludur.
  if (process.env.NODE_ENV !== 'production') {
    return json({
      ok: true,
      sent: false,
      devToken: token,
      note: 'E-posta servisi yapılandırılmadı; token geliştirme amacıyla döndürüldü.',
    });
  }
  return json({ ok: true, sent: false });
});
