import { missingLegalEnvKeys, readLegalEntity } from '@/lib/legal-entity';

/**
 * Veri sorumlusu bloğu — yasal kimlik yapılandırılmışsa gerçek bilgileri, değilse **dürüst bir
 * "henüz yayımlanmadı" uyarısı** basar.
 *
 * Eski davranış bir "taslak belge" uyarısı ve `[Şirket Ünvanı]` gibi yer tutuculardı. Fark önemli:
 * yer tutucu, okuyucuya bir şirket varmış ama adı yazılmamış gibi gelir. Bu blok bunun yerine
 * durumu açıkça söyler ve iletişim için çalışan bir yol gösterir.
 *
 * Kurucu ortam değişkenlerini girdiği anda uyarı kaybolur; kod değişmez.
 */
export function LegalIdentity() {
  const entity = readLegalEntity();

  if (!entity) {
    const missing = missingLegalEnvKeys();
    return (
      <div className="explain" role="note" data-testid="legal-identity-pending">
        <strong>Veri sorumlusu bilgileri henüz yayımlanmadı.</strong> Bu hizmeti işleten tüzel
        kişiliğin tescil bilgileri yayımlanır yayımlanmaz bu bölümde görünecektir. Bu süre boyunca
        gizlilik ve KVKK talepleriniz için uygulama içindeki <em>Profil → Hesabımı sil</em> yolunu
        kullanabilir veya web sitesindeki iletişim kanalından bize ulaşabilirsiniz.
        {process.env.NODE_ENV !== 'production' && missing.length > 0 && (
          <>
            {' '}
            <span className="muted">
              (Geliştirme notu — eksik ortam değişkenleri: <code>{missing.join(', ')}</code>)
            </span>
          </>
        )}
      </div>
    );
  }

  return (
    <div data-testid="legal-identity">
      <p>
        Veri sorumlusu <strong>{entity.companyName}</strong> (VKN: <code>{entity.taxId}</code>,
        adres: {entity.address}) olup, bu metin kapsamındaki işlemlerden sorumludur.
      </p>
      <p>
        İletişim: <a href={`mailto:${entity.supportEmail}`}>{entity.supportEmail}</a> · KEP:{' '}
        <code>{entity.kepAddress}</code>
      </p>
    </div>
  );
}
