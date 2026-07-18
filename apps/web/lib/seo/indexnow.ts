/**
 * PROGRAM SEO — IndexNow (Bing, Yandex, Seznam vb. anında bildirim protokolü).
 * Anahtar dosyası: `public/<KEY>.txt` (içeriği anahtarın kendisi) → site kökünden servis edilir.
 * Anahtar env ile override edilebilir (owner kendi anahtarını koyabilir), yoksa repodaki sabit.
 */
import { SITE_URL } from './site';

/** Repodaki IndexNow anahtarı (public/<KEY>.txt ile eşleşmeli). Owner env ile değiştirebilir. */
export const INDEXNOW_KEY = process.env.INDEXNOW_KEY ?? 'dcb5de91fc6aa6d1d1ba4966dd1c355f';

export function indexNowKeyLocation(): string {
  return `${SITE_URL}/${INDEXNOW_KEY}.txt`;
}

/**
 * Bir URL listesini IndexNow'a gönderir. Sunucuda çağrılır (admin panelinden tetiklenebilir).
 * Başarısızlıkta sessiz false döner — SEO bildirimi kritik yol değildir.
 */
export async function submitToIndexNow(urls: string[]): Promise<{ ok: boolean; status: number }> {
  if (!urls.length) return { ok: true, status: 204 };
  const host = new URL(SITE_URL).host;
  try {
    const res = await fetch('https://api.indexnow.org/indexnow', {
      method: 'POST',
      headers: { 'content-type': 'application/json; charset=utf-8' },
      body: JSON.stringify({
        host,
        key: INDEXNOW_KEY,
        keyLocation: indexNowKeyLocation(),
        urlList: urls.slice(0, 10000),
      }),
    });
    return { ok: res.ok, status: res.status };
  } catch {
    return { ok: false, status: 0 };
  }
}
