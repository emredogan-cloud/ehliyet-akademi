import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Çerez Politikası',
  description:
    'Ehliyet Akademi çerez politikası: zorunlu çerezler, tercih çerezleri, yerel depolama, opsiyonel analitik ve çerez rızasını yönetme yöntemleri.',
  path: '/cerez-politikasi',
});

export default function CerezPolitikasiPage() {
  return (
    <article
      className="legal container"
      data-testid="legal-cerez-politikasi"
      style={{ maxWidth: 820, margin: '0 auto' }}
    >
      <h1>Çerez Politikası</h1>
      <p className="muted">Son güncelleme: 15 Temmuz 2026</p>

      <div className="explain" role="note">
        <strong>Taslak belge uyarısı.</strong> Bu metin bir <em>taslaktır (template)</em> ve henüz
        kuruluşu tamamlanmamış bir ürün için hazırlanmıştır. Kamuya açık yayına alınmadan önce bir
        avukat tarafından gözden geçirilmelidir. Metindeki şirket ve iletişim bilgileri —{' '}
        <code>[Şirket Ünvanı]</code> ve <code>[destek e-postası]</code> — yalnızca yer tutucudur ve
        gerçek bir tüzel kişiliği temsil etmez.
      </div>

      <h2>1. Çerez Nedir?</h2>
      <p>
        Çerezler, bir web sitesini kullandığınızda tarayıcınıza kaydedilen küçük metin dosyalarıdır.
        Benzer teknolojiler arasında tarayıcının <strong>yerel depolama (localStorage)</strong>{' '}
        alanı da yer alır. Bu teknolojileri, hizmetin çalışması, tercihlerinizin hatırlanması ve
        (izniniz varsa) hizmeti iyileştirmek için kullanırız.
      </p>

      <h2>2. Kullandığımız Çerez Türleri</h2>

      <h3>2.1. Zorunlu Çerezler</h3>
      <p>
        Hizmetin temel işlevleri için gereklidir ve rıza gerektirmez. Bunlar olmadan oturum açma ve
        güvenlik gibi işlevler çalışmaz.
      </p>
      <ul>
        <li>
          <strong>
            <code>ea_session</code>
          </strong>{' '}
          — Oturumunuzu güvenli biçimde sürdürür. <code>httpOnly</code> olarak ayarlanır; yani
          JavaScript ile okunamaz, yalnız sunucuyla güvenli iletişimde kullanılır.
        </li>
        <li>Güvenlik ve kötüye kullanım önleme amaçlı temel teknik çerezler.</li>
      </ul>

      <h3>2.2. Tercih Çerezleri</h3>
      <p>Deneyiminizi kişiselleştirmek için ayarlarınızı hatırlar. Örneğin:</p>
      <ul>
        <li>
          <strong>Tema tercihi</strong> — Açık/koyu görünüm seçiminizi hatırlar.
        </li>
        <li>Dil ve arayüzle ilgili benzer küçük tercihler.</li>
      </ul>

      <h3>2.3. Yerel Depolama (localStorage)</h3>
      <p>
        Çalışma <strong>ilerlemenizin</strong> büyük kısmı — çözdüğünüz sorular, istatistikler ve
        tekrar planınız — çerez yerine tarayıcınızın yerel depolama alanında, yani{' '}
        <strong>cihazınızda</strong> tutulur. Bu veri sunucuya otomatik gönderilmez; tarayıcı
        verilerinizi temizleyerek istediğiniz an silebilirsiniz.
      </p>

      <h3>2.4. Analitik Çerezler (Opsiyonel)</h3>
      <p>
        Hizmeti nasıl kullandığınızı toplu ve anonim biçimde anlamak için analitik kullanabiliriz.
        Bu çerezler <strong>yalnızca açık rızanızla</strong> etkinleştirilir. Rıza vermezseniz
        çalışmaz ve hizmeti kullanmanız etkilenmez.
      </p>

      <h2>3. Çerez Özeti</h2>
      <ul>
        <li>
          <strong>Zorunlu:</strong> <code>ea_session</code> (oturum, httpOnly) — rıza gerekmez.
        </li>
        <li>
          <strong>Tercih:</strong> tema ve arayüz ayarları — rıza gerekmez, siz değiştirebilirsiniz.
        </li>
        <li>
          <strong>Yerel depolama:</strong> ilerleme verisi (cihazda) — rıza gerekmez, siz
          silebilirsiniz.
        </li>
        <li>
          <strong>Analitik:</strong> opsiyonel — yalnız açık rıza ile.
        </li>
      </ul>

      <h2>4. Rıza Yönetimi</h2>
      <p>
        Hizmeti ilk kullandığınızda bir <strong>çerez bilgilendirme bannerı</strong> ile
        karşılaşırsınız. Buradan opsiyonel (analitik) çerezleri kabul edebilir veya
        reddedebilirsiniz. Zorunlu çerezler hizmetin çalışması için her zaman gereklidir.
      </p>
      <p>
        Tercihinizi daha sonra istediğiniz zaman uygulama içindeki <strong>Ayarlar</strong>{' '}
        bölümünden değiştirebilir; verdiğiniz rızayı geri çekebilirsiniz. Ayrıca tarayıcınızın
        ayarlarından da çerezleri yönetebilir veya silebilirsiniz; ancak zorunlu çerezleri
        engellemek bazı işlevlerin çalışmamasına yol açabilir.
      </p>

      <h2>5. Üçüncü Taraf Çerezleri</h2>
      <p>
        Analitik veya ödeme gibi işlevler için çalıştığımız hizmet sağlayıcılar kendi çerezlerini
        kullanabilir. Bu sağlayıcılar yalnız ilgili amaçla ve rıza gerektiren durumlarda rızanız
        alınarak devreye girer. Ayrıntılar için <a href="/gizlilik">Gizlilik Politikası</a>{' '}
        sayfasına bakın.
      </p>

      <h2>6. Değişiklikler ve İletişim</h2>
      <p>
        Bu politikayı zaman zaman güncelleyebiliriz; güncel sürümün tarihi sayfanın üstünde
        belirtilir. Çerezlerle ilgili sorularınız için <code>[Şirket Ünvanı]</code> ile{' '}
        <code>[destek e-postası]</code> üzerinden iletişime geçebilirsiniz.
      </p>
    </article>
  );
}
