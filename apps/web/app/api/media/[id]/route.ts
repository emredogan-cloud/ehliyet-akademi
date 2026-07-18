import { guarded } from '@/lib/server/auth';
import { getMedia } from '@/lib/server/cms';

/** Halka açık medya servisi — yüklü varlığı doğru content-type ile döndürür. */
export const GET = guarded(async (req: Request): Promise<Response> => {
  const parts = new URL(req.url).pathname.split('/');
  const id = parts[parts.length - 1] ?? '';
  const m = await getMedia(id);
  if (!m) return new Response('Bulunamadı', { status: 404 });
  const buf = Buffer.from(m.dataBase64, 'base64');
  return new Response(buf, {
    headers: {
      'content-type': m.mime,
      'content-length': String(buf.length),
      'cache-control': 'public, max-age=31536000, immutable',
      // GÜVENLİK (M4): yüklü SVG/JSON aynı origin'de doğrudan açılırsa gömülü script çalışabilir.
      // `sandbox` CSP + nosniff: <img> gömmeyi bozmaz ama üst-düzey gezinmede script'i etkisizleştirir.
      'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; sandbox",
      'x-content-type-options': 'nosniff',
      'content-disposition': 'inline',
    },
  });
});
