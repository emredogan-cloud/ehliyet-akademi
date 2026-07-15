import { json, guarded, validEmail } from '@/lib/server/auth';
import { checkRateLimit } from '@/lib/server/rate-limit';
import { getEmailProvider, supportRequestEmail } from '@/lib/server/email';
import { logger } from '@/lib/server/logger';

/** Destek talebi (Sprint 4). Destek kutusuna e-posta gönderir (yoksa loglanır). */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const limited = checkRateLimit(req, { bucket: 'support', limit: 5, windowMs: 300_000 });
  if (limited) return limited;

  let body: { email?: string; message?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  const email = (body.email ?? '').trim();
  const message = (body.message ?? '').trim();
  if (!validEmail(email)) return json({ error: 'Geçerli bir e-posta girin.' }, { status: 400 });
  if (message.length < 10)
    return json({ error: 'Mesaj en az 10 karakter olmalı.' }, { status: 400 });

  const inbox = process.env.SUPPORT_EMAIL ?? 'destek@ehliyetakademi.app';
  try {
    await getEmailProvider().send(inbox, supportRequestEmail(email, message.slice(0, 4000)));
  } catch (e) {
    logger.warn('support_email_failed', { err: String(e) });
  }
  return json({ ok: true });
});
