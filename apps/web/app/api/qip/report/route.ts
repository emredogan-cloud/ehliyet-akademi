import { guarded, json, getSessionUser } from '@/lib/server/auth';
import { createReport, isReportKind } from '@/lib/server/reports';

/**
 * Soru bildirimi gönder (BANK_QUESTİON Part 13). Oturum varsa kullanıcı iliştirilir; anonim de olur.
 * Gövde: { questionId, kind, message? }. kind ∈ wrong-answer|unclear|typo|suggestion|other.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  let body: { questionId?: unknown; kind?: unknown; message?: unknown } = {};
  try {
    body = (await req.json()) as typeof body;
  } catch {
    /* boş gövde → doğrulama reddeder */
  }
  const questionId = typeof body.questionId === 'string' ? body.questionId.trim() : '';
  if (!questionId || !isReportKind(body.kind)) {
    return json(
      { error: 'geçersiz bildirim (questionId + geçerli kind gerekli)' },
      { status: 400 }
    );
  }
  const user = await getSessionUser(req);
  const { id } = await createReport({
    questionId,
    kind: body.kind,
    message: typeof body.message === 'string' ? body.message : '',
    userId: user?.id ?? null,
  });
  return json({ ok: true, id });
});
