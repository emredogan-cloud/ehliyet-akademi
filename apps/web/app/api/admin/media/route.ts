import { requireRole, json, guarded } from '@/lib/server/auth';
import { uploadMedia, listMedia } from '@/lib/server/cms';

export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  return json({ items: await listMedia() });
});

export const POST = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  let body: { filename?: string; mime?: string; dataBase64?: string; alt?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Geçersiz istek gövdesi.' }, { status: 400 });
  }
  if (!body.filename || !body.mime || !body.dataBase64)
    return json({ error: 'filename, mime ve dataBase64 zorunlu.' }, { status: 400 });
  const res = await uploadMedia(user, {
    filename: body.filename,
    mime: body.mime,
    dataBase64: body.dataBase64,
    alt: body.alt,
  });
  if (!res.ok) return json({ errors: res.errors }, { status: 400 });
  return json({ ok: true, id: res.id, url: `/api/media/${res.id}` }, { status: 201 });
});
