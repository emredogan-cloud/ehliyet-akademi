/**
 * Beta Faz 1 — mobil uygulamaya giden bağlantıların TEK kaynağı.
 *
 * Paket adı ve derin bağlantı şeması üç yerde birbirine uymak zorundadır: burada, Android
 * manifestosunda (`apps/mobile/android/app/src/main/AndroidManifest.xml`) ve Flutter
 * yönlendiricisinde (`apps/mobile/lib/app/router.dart`). Üçünden biri kaydığında bağlantı
 * SESSİZCE tarayıcıda açılır — kullanıcı hatayı görmez, biz de göremeyiz. Bu yüzden değerler
 * kopyalanmaz; web tarafında buradan, mobil tarafta `AppConfig`'ten okunur.
 */

/** Play'e ilk yüklemeden sonra DEĞİŞTİRİLEMEZ — `AppConfig.androidPackage` ile aynı. */
export const ANDROID_PACKAGE = 'com.ehliyetegitim.ehliyet_akademi';

/** Uygulamanın özel şeması — App Links doğrulanmadığında da çalışan yedek yol. */
export const APP_SCHEME = 'ehliyetakademi';

/**
 * Özel şema URI'sindeki HOST bileşeni.
 *
 * Süs değil, zorunlu: Flutter gelen URI'yi olduğu gibi yönlendiriciye verir ve go_router yalnız
 * `uri.path` ile eşleştirir. `ehliyetakademi://davet/<KOD>` yazılsa "davet" HOST olur, path boş
 * kalır ve hiçbir rota eşleşmez. Araya bir host konunca path `/davet/<KOD>` olur — https biçimiyle
 * tam aynı yol. (Android tarafındaki karşılığı: `AndroidManifest.xml`, `android:host="app"`.)
 */
export const APP_HOST = 'app';

/** Play Store sayfası. `hl=tr` kullanıcıyı Türkçe listelemeye düşürür. */
export function playStoreUrl(referrer?: string): string {
  const base = `https://play.google.com/store/apps/details?id=${ANDROID_PACKAGE}&hl=tr`;
  // Play Install Referrer: kurulumdan SONRA uygulama bu değeri okuyabilir. Davet kodunu buraya
  // koymak, "yükledikten sonra kodu elle yaz" adımını gereksiz kılacak veriyi Play'e emanet eder.
  return referrer ? `${base}&referrer=${encodeURIComponent(referrer)}` : base;
}

/**
 * Uygulamanın içine giden özel şema bağlantısı.
 *
 * NEDEN https App Link'in yanında bir de bu var: App Links yalnız `assetlinks.json` DOĞRULANMIŞSA
 * uygulamayı açar. Doğrulama sunucu yapılandırmasına bağlıdır (bkz. `/.well-known/assetlinks.json`)
 * ve elimizde olmayan bir sebeple bozulabilir. Özel şema doğrulama gerektirmez; kurulu uygulamayı
 * her koşulda açar. Kurulu değilse hiçbir şey olmaz — bu yüzden ASLA tek başına kullanılmaz.
 */
export function appInviteScheme(code: string): string {
  return `${APP_SCHEME}://${APP_HOST}/davet/${code}`;
}

/**
 * Android'in yerel "kuruluysa uygulamayı aç, değilse şuraya git" mekanizması.
 *
 * Kararı TARAYICI verir; zamanlayıcıya dayanan JS hilelerinin yanlış pozitifleri yoktur.
 * Yol kısmı (`app/davet/<KOD>`) özel şema URI'siyle aynı olmak zorunda — bkz. [APP_HOST].
 */
export function appInviteIntent(code: string, fallbackUrl: string): string {
  return (
    `intent://${APP_HOST}/davet/${code}#Intent;scheme=${APP_SCHEME};package=${ANDROID_PACKAGE};` +
    `S.browser_fallback_url=${encodeURIComponent(fallbackUrl)};end`
  );
}

/** Paylaşılan davet bağlantısı (hem web sayfası hem Android App Link olarak çalışır). */
export function inviteUrl(base: string, code: string): string {
  return `${base.replace(/\/+$/, '')}/davet/${code}`;
}
