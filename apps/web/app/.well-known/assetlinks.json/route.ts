import { ANDROID_PACKAGE } from '@/lib/app-links';

/**
 * Beta Faz 1 — Android App Links doğrulama dosyası (`/.well-known/assetlinks.json`).
 *
 * Bu dosya olmadan `https://…/davet/<KOD>` bağlantısı uygulamayı **açmaz**: Android, alan adının
 * uygulamaya izin verdiğini bu dosyadan öğrenir. Doğrulama başarısızsa bağlantı sessizce tarayıcıda
 * açılır — kullanıcı bir hata görmez, biz de göremeyiz. Bu yüzden ölçülebilir olması önemlidir.
 *
 * PARMAK İZİ UYDURULAMAZ. Play App Signing kullanıldığında imzalayan anahtar Google'ın elindedir ve
 * SHA-256 parmak izi **Play Console → Uygulama imzalama** sayfasından alınır. Ortam değişkeni
 * ayarlanmadıysa bu uç boş liste döner (`[]`): geçerli JSON'dur, Android "izin yok" der ve bağlantı
 * tarayıcıda açılır. Uydurma bir parmak izi koymak ise doğrulamayı SESSİZCE bozardı ve nedeni
 * aramak günler alırdı.
 *
 * Ayar:
 *   ANDROID_SHA256_FINGERPRINTS="AA:BB:…:FF,11:22:…:99"
 * Birden çok değer virgülle: üretim (Play imzalama) + yükleme anahtarı + hata ayıklama anahtarı
 * aynı anda geçerli olabilir; her biri ayrı bir parmak izidir.
 */

/** Ortamdan gelen parmak izlerini ayıkla. Biçimi tutmayan değer SESSİZCE ATILMAZ — atılır ve loglanır. */
export function parseFingerprints(raw: string | undefined): string[] {
  if (!raw) return [];
  const valid: string[] = [];
  for (const part of raw.split(',')) {
    const fp = part.trim().toUpperCase();
    if (!fp) continue;
    // SHA-256 = 32 bayt = iki nokta üst üste ile ayrılmış 32 onaltılık çift.
    if (/^([0-9A-F]{2}:){31}[0-9A-F]{2}$/.test(fp)) valid.push(fp);
    else console.warn('[assetlinks] geçersiz SHA-256 parmak izi atlandı:', fp.slice(0, 12) + '…');
  }
  return valid;
}

export function GET(): Response {
  const fingerprints = parseFingerprints(process.env.ANDROID_SHA256_FINGERPRINTS);
  const body =
    fingerprints.length === 0
      ? []
      : [
          {
            relation: ['delegate_permission/common.handle_all_urls'],
            target: {
              namespace: 'android_app',
              package_name: ANDROID_PACKAGE,
              sha256_cert_fingerprints: fingerprints,
            },
          },
        ];

  return new Response(JSON.stringify(body, null, 2), {
    headers: {
      'content-type': 'application/json',
      // Android doğrulamayı kurulumda ve arada bir yapar; bir saatlik önbellek yeter ve parmak izi
      // değiştiğinde (yeni imzalama anahtarı) gecikmeyi bir saatle sınırlar.
      'cache-control': 'public, max-age=3600',
    },
  });
}
