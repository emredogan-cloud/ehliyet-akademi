import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'KVKK Aydınlatma Metni',
  description:
    '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında Ehliyet Akademi aydınlatma metni: veri sorumlusu, işlenen veriler, hukuki sebepler, aktarım, saklama ve ilgili kişi hakları.',
  path: '/kvkk',
});

export default function KvkkPage() {
  return (
    <article
      className="legal container"
      data-testid="legal-kvkk"
      style={{ maxWidth: 820, margin: '0 auto' }}
    >
      <h1>KVKK Aydınlatma Metni</h1>
      <p className="muted">Son güncelleme: 15 Temmuz 2026</p>

      <div className="explain" role="note">
        <strong>Taslak belge uyarısı.</strong> Bu metin bir <em>taslaktır (template)</em> ve henüz
        kuruluşu tamamlanmamış bir ürün için hazırlanmıştır. Kamuya açık yayına alınmadan önce bir
        avukat tarafından gözden geçirilmelidir. Metindeki veri sorumlusu ve iletişim bilgileri —{' '}
        <code>[Şirket Ünvanı]</code>, <code>[VKN]</code>, <code>[Adres]</code>,{' '}
        <code>[KEP adresi]</code>, <code>[destek e-postası]</code> — yalnızca yer tutucudur ve
        gerçek bir tüzel kişiliği temsil etmez.
      </div>

      <h2>1. Giriş</h2>
      <p>
        Bu aydınlatma metni,{' '}
        <strong>6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK")</strong> uyarınca, kişisel
        verilerinizin veri sorumlusu tarafından hangi amaçlarla ve hangi hukuki sebeplere
        dayanılarak işlendiği konusunda sizi bilgilendirmek amacıyla hazırlanmıştır.
      </p>

      <h2>2. Veri Sorumlusu</h2>
      <p>
        Veri sorumlusu <code>[Şirket Ünvanı]</code> (VKN: <code>[VKN]</code>, adres:{' '}
        <code>[Adres]</code>) olup, bu metinde "Ehliyet Akademi" olarak anılır. İletişim:{' '}
        <code>[destek e-postası]</code> — KEP: <code>[KEP adresi]</code>.
      </p>

      <h2>3. İşlenen Kişisel Veriler</h2>
      <ul>
        <li>
          <strong>Kimlik/İletişim verileri:</strong> Ad (görünen ad), e-posta adresi.
        </li>
        <li>
          <strong>Müşteri işlem verileri:</strong> Satın alma kaydı, sipariş numarası, tutar, tarih,
          ödeme sağlayıcı işlem referansı (kart bilgileri tarafımızca işlenmez).
        </li>
        <li>
          <strong>Kullanım/İlerleme verileri:</strong> Çözülen sorular ve istatistikler (büyük kısmı
          cihazınızda tutulur).
        </li>
        <li>
          <strong>İşlem güvenliği verileri:</strong> Oturum bilgileri, IP kaydı, temel
          cihaz/tarayıcı bilgileri.
        </li>
      </ul>

      <h2>4. İşleme Amaçları ve Hukuki Sebepler (KVKK m.5)</h2>
      <p>
        Kişisel verileriniz, KVKK m.5'te sayılan hukuki sebeplere dayanılarak aşağıdaki amaçlarla
        işlenir:
      </p>
      <ul>
        <li>
          <strong>Sözleşmenin kurulması/ifası (m.5/2-c):</strong> Hesabın oluşturulması, hizmetin
          sunulması ve premium satın alımın gerçekleştirilmesi.
        </li>
        <li>
          <strong>Hukuki yükümlülük (m.5/2-ç):</strong> Fatura/muhasebe ve mevzuattan doğan saklama
          yükümlülükleri.
        </li>
        <li>
          <strong>Meşru menfaat (m.5/2-f):</strong> Güvenliğin sağlanması, kötüye kullanımın
          önlenmesi ve hizmetin iyileştirilmesi.
        </li>
        <li>
          <strong>Açık rıza (m.5/1):</strong> Opsiyonel analitik ve rıza gerektiren diğer işlemler.
          Rızanızı dilediğiniz zaman geri çekebilirsiniz.
        </li>
      </ul>

      <h2>5. Kişisel Verilerin Aktarılması</h2>
      <p>
        Verileriniz, yalnızca hizmetin sunulması için gerekli olduğu ölçüde; ödeme sağlayıcısı,
        e-posta sağlayıcısı ve barındırma (hosting) sağlayıcısı gibi hizmet sağlayıcılara ve yasal
        olarak yetkili kamu kurum ve kuruluşlarına, KVKK m.8 ve m.9'daki şartlara uygun olarak
        aktarılabilir. Yurt dışı aktarım söz konusu olduğunda mevzuatın öngördüğü güvenceler
        sağlanır.
      </p>

      <h2>6. Toplama Yöntemi</h2>
      <p>
        Kişisel verileriniz; web uygulaması üzerinden doğrudan sizin girmeniz, hizmeti kullanmanız
        ve çerezler/benzeri teknolojiler aracılığıyla elektronik ortamda toplanır.
      </p>

      <h2>7. Saklama Süresi</h2>
      <p>
        Kişisel verileriniz, işleme amacının gerektirdiği süre ile ilgili mevzuatta öngörülen
        süreler boyunca saklanır; bu sürelerin sona ermesiyle silinir, yok edilir veya anonim hale
        getirilir. Fatura ve ticari kayıtlar mevzuattaki (genellikle 10 yıla kadar) zorunlu süre
        boyunca tutulur.
      </p>

      <h2>8. İlgili Kişinin Hakları (KVKK m.11)</h2>
      <p>
        KVKK'nın 11. maddesi uyarınca, veri sorumlusuna başvurarak aşağıdaki haklara sahipsiniz:
      </p>
      <ul>
        <li>Kişisel verilerinizin işlenip işlenmediğini öğrenme.</li>
        <li>İşlenmişse buna ilişkin bilgi talep etme.</li>
        <li>İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme.</li>
        <li>Yurt içinde/yurt dışında aktarıldığı üçüncü kişileri bilme.</li>
        <li>Eksik veya yanlış işlenmişse düzeltilmesini isteme.</li>
        <li>KVKK'da öngörülen şartlarla silinmesini veya yok edilmesini isteme.</li>
        <li>Düzeltme/silme işlemlerinin aktarıldığı üçüncü kişilere bildirilmesini isteme.</li>
        <li>
          Münhasıran otomatik sistemlerle analiz sonucu aleyhinize bir sonuç ortaya çıkmasına itiraz
          etme.
        </li>
        <li>
          Kanuna aykırı işleme nedeniyle zarara uğramanız halinde zararın giderilmesini talep etme.
        </li>
      </ul>

      <h2>9. Veri Sorumlusuna Başvuru Yöntemi</h2>
      <p>Yukarıdaki haklarınızı kullanmak için taleplerinizi;</p>
      <ul>
        <li>
          <strong>KEP:</strong> <code>[KEP adresi]</code> adresine,
        </li>
        <li>
          <strong>E-posta:</strong> sistemimizde kayıtlı e-posta adresinizden{' '}
          <code>[destek e-postası]</code> adresine,
        </li>
        <li>
          <strong>Yazılı olarak:</strong> <code>[Adres]</code> adresine ıslak imzalı dilekçe ile
        </li>
      </ul>
      <p>
        iletebilirsiniz. Kimliğinizi tespit edici bilgilerle yaptığınız başvurular, talebin
        niteliğine göre en kısa sürede ve en geç <strong>30 (otuz) gün</strong> içinde ücretsiz
        olarak sonuçlandırılır; işlemin ayrıca bir maliyet gerektirmesi halinde Kurul'un belirlediği
        tarife uygulanabilir. Başvurunuzu yeterli bulmamanız halinde Kişisel Verileri Koruma
        Kurulu'na şikâyette bulunma hakkınız saklıdır.
      </p>

      <h2>10. İlgili Belgeler</h2>
      <p>
        Daha fazla bilgi için <a href="/gizlilik">Gizlilik Politikası</a> ve{' '}
        <a href="/cerez-politikasi">Çerez Politikası</a> sayfalarımıza bakabilirsiniz.
      </p>
    </article>
  );
}
