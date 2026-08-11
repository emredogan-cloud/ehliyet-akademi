import { guarded, json, getSessionUser } from '@/lib/server/auth';
import { createReport, isReportKind, isReportSource } from '@/lib/server/reports';

/**
 * İçerik bildirimi gönder (BANK_QUESTİON Part 13). Oturum varsa kullanıcı iliştirilir; **anonim de
 * olur** — bu uç misafir kullanıcıya da açıktır.
 *
 * Gövde: `{ questionId, kind, message?, source? }`
 * · `kind`   ∈ wrong-answer | unclear | typo | suggestion | harmful | other
 * · `source` ∈ question (varsayılan) | ai-reply
 *
 * ## Neden AI Koç bildirimleri de buradan geçiyor
 *
 * Play'in üretken yapay zekâ politikası, kullanıcının rahatsız edici AI çıktısını **uygulamadan
 * çıkmadan** bildirebilmesini bekliyor. Topluluk bildirimi ucu bu iş için uygun değildi: hedef bir
 * KULLANICI kimliği istiyor (AI yanıtının sahibi yok) ve topluluğa katılmış olmayı gerektiriyor —
 * oysa AI Koç hesapsız kullanılabiliyor. Bu uç ise anonim çalışıyor ve zaten bir insan inceleme
 * kuyruğuna (`/api/admin/reports`) düşüyor. Yeni bir moderasyon sistemi kurmak yerine var olan
 * kuyruk tek bir `source` sütunuyla ikiye ayrıldı.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  let body: { questionId?: unknown; kind?: unknown; message?: unknown; source?: unknown } = {};
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
    // Bilinmeyen/eksik değer sessizce 'question'a düşer — istemci eski sürümse davranış değişmez.
    source: isReportSource(body.source) ? body.source : 'question',
  });
  return json({ ok: true, id });
});
