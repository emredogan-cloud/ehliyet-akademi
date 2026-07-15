import { eq } from 'drizzle-orm';
import { getDb, users, passwordResetTokens } from '@ea/db';
import { newToken, sha256, json, validEmail, guarded } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { getEmailProvider, emailConfigured, passwordResetEmail } from '@/lib/server/email';

/**
 * Parola sıfırlama talebi. E-posta servisi (RESEND_API_KEY) varsa sıfırlama bağlantısı
 * e-postayla gönderilir; yoksa token yanıtta döner (devToken — dürüst geliştirme modu).
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'forgot', limit: 5, windowMs: 60_000 });
  if (limited) return limited;

  let body: { email?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const email = (body.email ?? '').trim().toLowerCase();
  if (!validEmail(email)) return json({ error: 'Geçerli bir e-posta girin.' }, { status: 400 });

  const db = await getDb();
  const rows = await db.select({ id: users.id }).from(users).where(eq(users.email, email));
  const user = rows[0];
  // Hesap var/yok bilgisini sızdırma: her durumda "gönderildi" davran.
  if (!user) return json({ ok: true, sent: false });

  const token = newToken();
  await db.insert(passwordResetTokens).values({
    tokenHash: sha256(token),
    userId: user.id,
    expiresAt: new Date(Date.now() + 3600_000), // 1 saat
  });

  if (emailConfigured()) {
    const base = process.env.NEXT_PUBLIC_SITE_URL ?? '';
    await getEmailProvider().send(email, passwordResetEmail(`${base}/sifirla?token=${token}`));
    return json({ ok: true, sent: true });
  }
  return json({
    ok: true,
    sent: false,
    devToken: token,
    note: 'E-posta servisi yapılandırılmadı; token geliştirme amacıyla döndürüldü.',
  });
});
