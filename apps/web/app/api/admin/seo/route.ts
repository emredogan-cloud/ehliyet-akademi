import { requireRole, json, guarded } from '@/lib/server/auth';
import { auditSeo } from '@/lib/seo/audit';
import { submitToIndexNow, indexNowKeyLocation } from '@/lib/seo/indexnow';
import { SITE_URL } from '@/lib/seo/site';

/** SEO denetim raporu (admin/editor). */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin', 'editor');
  if (user instanceof Response) return user;
  return json({ audit: auditSeo(), indexNow: { keyLocation: indexNowKeyLocation() } });
});

/**
 * IndexNow'a ana URL'leri gönder (admin). Gövde: { urls?: string[] } — verilmezse çekirdek
 * halka açık sayfalar gönderilir. Gerçek gönderim yalnız üretim origin'inde anlamlıdır.
 */
export const POST = guarded(async (req: Request): Promise<Response> => {
  const user = await requireRole(req, 'admin');
  if (user instanceof Response) return user;

  let urls: string[] = [];
  try {
    const body = (await req.json()) as { urls?: string[] };
    urls = Array.isArray(body.urls) ? body.urls : [];
  } catch {
    /* boş gövde → varsayılan çekirdek URL seti */
  }
  if (!urls.length) {
    urls = ['/', '/dersler', '/isaretler', '/arac', '/e-sinav', '/deneme-sinavi'].map(
      (p) => `${SITE_URL}${p === '/' ? '' : p}`
    );
  }
  const result = await submitToIndexNow(urls);
  return json({ submitted: urls.length, ...result });
});
