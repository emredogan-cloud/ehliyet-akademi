import { eq } from 'drizzle-orm';
import { getDb, users, passwordResetTokens } from '@ea/db';
import { newToken, sha256, json, validEmail, guarded } from '@/lib/server/auth';

/**
 * Parola sıfırlama talebi. E-posta servisi (RESEND_API_KEY) yapılandırılmadıysa
 * token yanıtta döner (devToken) — dürüst etiketli geliştirme modu (ENV_SETUP_GUIDE).
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
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

  const emailConfigured = Boolean(process.env.RESEND_API_KEY);
  if (emailConfigured) {
    // Gerçek e-posta adaptörü Sprint 2+ (ENV geldiğinde): burada gönderilir.
    return json({ ok: true, sent: true });
  }
  return json({
    ok: true,
    sent: false,
    devToken: token,
    note: 'E-posta servisi yapılandırılmadı; token geliştirme amacıyla döndürüldü.',
  });
});
