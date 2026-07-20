import { requireRole, json, guarded } from '@/lib/server/auth';
import { listReports, updateReportStatus, isReportStatus } from '@/lib/server/reports';

/** Soru bildirimleri moderasyon kuyruğu (admin/editor). BANK_QUESTİON Part 13. */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  const status = new URL(req.url).searchParams.get('status');
  const reports = await listReports(isReportStatus(status) ? status : undefined);
  return json({ reports });
});

/** Bir bildirimi çöz/reddet (admin/editor). Gövde: { id, status }. */
export const PATCH = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  let body: { id?: unknown; status?: unknown } = {};
  try {
    body = (await req.json()) as typeof body;
  } catch {
    /* boş gövde → doğrulama reddeder */
  }
  if (typeof body.id !== 'string' || !isReportStatus(body.status)) {
    return json({ error: 'geçersiz (id + status gerekli)' }, { status: 400 });
  }
  const ok = await updateReportStatus(body.id, body.status);
  return json({ ok });
});
