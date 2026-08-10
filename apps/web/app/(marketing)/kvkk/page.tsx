import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';
import { SUB_PROCESSORS } from '@/lib/legal-entity';
import { LegalIdentity } from '../_legal/LegalIdentity';

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
      <p className="muted">Son güncelleme: 10 Ağustos 2026</p>

      <h2>1. Giriş</h2>
      <p>
        Bu aydınlatma metni,{' '}
        <strong>6698 sayılı Kişisel Verilerin Korunması Kanunu ("KVKK")</strong> uyarınca, kişisel
        verilerinizin veri sorumlusu tarafından hangi amaçlarla ve hangi hukuki sebeplere
        dayanılarak işlendiği konusunda sizi bilgilendirmek amacıyla hazırlanmıştır.
      </p>

      <h2>2. Veri Sorumlusu</h2>
      <LegalIdentity />
      <p>
        Bu metinde veri sorumlusu &quot;Ehliyet Akademi&quot; olarak anılır. Metin, Ehliyet Akademi{' '}
        <strong>Android uygulamasını ve web sitesini</strong> birlikte kapsar.
      </p>

      <h2>3. İşlenen Kişisel Veriler</h2>
      <ul>
        <li>
          <strong>Kimlik/İletişim verileri:</strong> Ad (görünen ad), e-posta adresi. Google ile
          giriş yapılması hâlinde bu veriler Google tarafından iletilir.
        </li>
        <li>
          <strong>Müşteri işlem verileri:</strong> Google Play satın alma jetonu, ürün kimliği,
          satın alma tarihi. <strong>Kart ve ödeme bilgileri tarafımızca işlenmez</strong>; ödeme
          tamamen Google Play üzerinden yürür.
        </li>
        <li>
          <strong>Kullanım/İlerleme verileri:</strong> Çözülen sorular, doğruluk istatistikleri,
          hazırlık puanı ve tekrar planı. Hesap açılmadığında bu veriler{' '}
          <strong>yalnız cihazda</strong> tutulur; hesap açıldığında hesaba bağlanır.
        </li>
        <li>
          <strong>Topluluk verileri (isteğe bağlı):</strong> Seçtiğiniz görünen ad, avatar ve
          yazdığınız mesaj/tartışma içerikleri. Topluluğa katılmazsanız bu veriler hiç oluşmaz.
        </li>
        <li>
          <strong>AI Koç verileri:</strong> AI Koç&apos;a yazdığınız soru metni. Yanıt üretildikten
          sonra kalıcı olarak saklanmaz.
        </li>
        <li>
          <strong>Kimliksiz kullanım ve hata kayıtları:</strong> Ekran/akış olayları ve hata
          raporları. Cihaz başına üretilen rastgele bir kimlik taşırlar; bu kimlik{' '}
          <strong>reklam kimliği değildir</strong> ve kişiyi tanımlamaz.
        </li>
        <li>
          <strong>İşlem güvenliği verileri:</strong> Oturum bilgileri ve istek meta verisi. IP
          adresi davet sisteminde <strong>ham hâliyle saklanmaz</strong>; yalnız tuzlanmış SHA-256
          özeti tutulur.
        </li>
      </ul>
      <p>
        <strong>İşlenmeyen veriler:</strong> konum, rehber, takvim, SMS, arama kaydı, mikrofon,
        reklam kimliği ve sağlık verisi işlenmez; ilgili izinler istenmez.
      </p>

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
        Verileriniz, yalnızca hizmetin sunulması için gerekli olduğu ölçüde aşağıdaki hizmet
        sağlayıcılara ve yasal olarak yetkili kamu kurum ve kuruluşlarına, KVKK m.8 ve m.9&apos;daki
        şartlara uygun olarak aktarılır:
      </p>
      <table>
        <thead>
          <tr>
            <th>Alıcı</th>
            <th>Aktarım amacı</th>
            <th>Aktarılan veri</th>
          </tr>
        </thead>
        <tbody>
          {SUB_PROCESSORS.map((s) => (
            <tr key={s.name}>
              <td>{s.name}</td>
              <td>{s.purpose}</td>
              <td>{s.dataShared}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p>
        Bu sağlayıcıların bir kısmı <strong>yurt dışında</strong> yerleşiktir. Yurt dışı aktarımda
        KVKK m.9&apos;un öngördüğü şartlar ve güvenceler gözetilir. Verileriniz reklam amacıyla
        üçüncü taraflara satılmaz veya kiralanmaz.
      </p>

      <h2>6. Toplama Yöntemi</h2>
      <p>
        Kişisel verileriniz; <strong>Android uygulaması</strong> ve <strong>web sitesi</strong>{' '}
        üzerinden doğrudan sizin girmeniz, hizmeti kullanmanız ve web tarafında çerezler/benzeri
        teknolojiler aracılığıyla elektronik ortamda toplanır. Android uygulaması çerez kullanmaz.
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
      <p>
        Yukarıdaki haklarınızı kullanmak için taleplerinizi, §2&apos;de belirtilen KEP adresine,
        sistemimizde kayıtlı e-posta adresinizden §2&apos;deki destek e-postasına veya §2&apos;deki
        açık adrese ıslak imzalı dilekçe ile iletebilirsiniz.
      </p>
      <p>
        Hesabınızı ve verilerinizi silmek için ayrıca başvuru yapmanız gerekmez; işlemi doğrudan
        uygulama içinden yapabilirsiniz — bkz. <a href="/hesap-silme">Hesap ve Veri Silme</a>.
      </p>
      <p>
        iletebilirsiniz. Kimliğinizi tespit edici bilgilerle yaptığınız başvurular, talebin
        niteliğine göre en kısa sürede ve en geç <strong>30 (otuz) gün</strong> içinde ücretsiz
        olarak sonuçlandırılır; işlemin ayrıca bir maliyet gerektirmesi halinde Kurul'un belirlediği
        tarife uygulanabilir. Başvurunuzu yeterli bulmamanız halinde Kişisel Verileri Koruma
        Kurulu'na şikâyette bulunma hakkınız saklıdır.
      </p>

      <h2>10. İlgili Belgeler</h2>
      <p>
        Daha fazla bilgi için <a href="/gizlilik">Gizlilik Politikası</a>,{' '}
        <a href="/cerez-politikasi">Çerez Politikası</a> ve{' '}
        <a href="/hesap-silme">Hesap ve Veri Silme</a> sayfalarımıza bakabilirsiniz.
      </p>
    </article>
  );
}
