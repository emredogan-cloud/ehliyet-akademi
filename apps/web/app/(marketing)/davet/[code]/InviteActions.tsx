'use client';

import { useEffect, useState } from 'react';
import { Icon } from '@/components/ui/icons';
import { track } from '@/lib/analytics';

/**
 * Beta Faz 1 — davet sayfasının EYLEM bölümü.
 *
 * Tek işi şu soruyu doğru cevaplamak: **uygulama kurulu mu?**
 *
 * Bunu tarayıcıdan doğrudan sormak MÜMKÜN DEĞİLDİR (ve olmaması iyi — parmak izi çıkarılırdı).
 * Yaygın hile, özel şemaya gidip bir zamanlayıcıyla "hâlâ buradayız, demek kurulu değil" demektir.
 * O hile GÜVENİLMEZ: yavaş cihazda uygulama açılırken zamanlayıcı yanar ve kullanıcı hem
 * uygulamaya hem Play Store'a atılır.
 *
 * Doğru cevap Android'in kendi mekanizmasıdır: `intent://` URI'si + `S.browser_fallback_url`.
 * Kararı TARAYICI verir — kurulu ise uygulama, değilse doğrudan Play Store. Zamanlayıcı yok,
 * yanlış pozitif yok. Chrome/WebView/Samsung Internet bunu yerel olarak destekler.
 *
 * Android DIŞINDA (masaüstü, iOS) uygulama zaten yoktur: o zaman dürüst davranılır — kod
 * kopyalanabilir biçimde gösterilir ve web'de kayıt yolu önerilir.
 */
export function InviteActions({
  code,
  intentUrl,
  storeUrl,
  schemeUrl,
}: {
  code: string;
  intentUrl: string;
  storeUrl: string;
  schemeUrl: string;
}) {
  const [isAndroid, setIsAndroid] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    setIsAndroid(/android/i.test(navigator.userAgent));
    track({ name: 'referral_link_opened', props: { code } });
  }, [code]);

  async function copyCode() {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2200);
    } catch {
      // Pano izni yoksa kod ekranda zaten okunabilir durumda — sessizce geç.
    }
  }

  return (
    <div className="inv-actions">
      {isAndroid ? (
        <>
          {/* Android: kararı tarayıcı verir (kurulu → uygulama, değil → Play Store). */}
          <a
            className="ui-btn ui-btn--primary ui-btn--lg ui-btn--full"
            href={intentUrl}
            onClick={() => track({ name: 'referral_app_open_attempted', props: { code } })}
            data-testid="invite-open-app"
          >
            <Icon name="rocket" size={18} /> Uygulamayı aç ve kodu kullan
          </a>
          <p className="inv-actions__note muted">
            Uygulama kuruluysa doğrudan açılır; değilse Play Store’a gider. Kod orada seni bekler.
          </p>
          {/* Özel şema, App Links doğrulanmamışsa ya da intent:// desteklenmiyorsa elle çıkış. */}
          <a className="inv-actions__alt" href={schemeUrl}>
            Uygulama açılmadı mı? Buradan dene
          </a>
        </>
      ) : (
        <>
          <a
            className="ui-btn ui-btn--primary ui-btn--lg ui-btn--full"
            href={storeUrl}
            rel="noopener"
            onClick={() => track({ name: 'referral_store_opened', props: { code } })}
            data-testid="invite-store"
          >
            <Icon name="phone" size={18} /> Android uygulamasını indir
          </a>
          <p className="inv-actions__note muted">
            Uygulama Android’de. Telefonundan bu bağlantıyı açtığında kod kendiliğinden dolar.
          </p>
        </>
      )}

      <div className="inv-actions__row">
        <a
          className="ui-btn ui-btn--ghost ui-btn--md"
          href={`/giris?mod=kayit&ref=${encodeURIComponent(code)}`}
          onClick={() => track({ name: 'referral_web_signup_clicked', props: { code } })}
          data-testid="invite-web-signup"
        >
          <Icon name="user" size={16} /> Web’de hesap oluştur
        </a>
        <button
          type="button"
          className="ui-btn ui-btn--ghost ui-btn--md"
          onClick={copyCode}
          data-testid="invite-copy"
        >
          <Icon name={copied ? 'check-circle' : 'clipboard'} size={16} />{' '}
          {copied ? 'Kod kopyalandı' : 'Kodu kopyala'}
        </button>
      </div>
    </div>
  );
}
