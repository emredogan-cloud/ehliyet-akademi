import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';

export const metadata: Metadata = buildMetadata({
  title: 'Kullanım Koşulları',
  description:
    'Ehliyet Akademi kullanım koşulları: hizmetin kapsamı, tek seferlik satın alma ve ömür boyu erişim modeli, dijital içerikte cayma hakkı, sorumluluk reddi ve uygulanacak hukuk.',
  path: '/kullanim-kosullari',
});

export default function KullanimKosullariPage() {
  return (
    <article
      className="legal container"
      data-testid="legal-kullanim-kosullari"
      style={{ maxWidth: 820, margin: '0 auto' }}
    >
      <h1>Kullanım Koşulları</h1>
      <p className="muted">Son güncelleme: 15 Temmuz 2026</p>

      <div className="explain" role="note">
        <strong>Taslak belge uyarısı.</strong> Bu metin bir <em>taslaktır (template)</em> ve henüz
        kuruluşu tamamlanmamış bir ürün için hazırlanmıştır. Kamuya açık yayına alınmadan önce bir
        avukat tarafından gözden geçirilmelidir. Metindeki şirket ve iletişim bilgileri —{' '}
        <code>[Şirket Ünvanı]</code>, <code>[VKN]</code>, <code>[Adres]</code>,{' '}
        <code>[KEP adresi]</code>, <code>[destek e-postası]</code> — yalnızca yer tutucudur ve
        gerçek bir tüzel kişiliği temsil etmez.
      </div>

      <h2>1. Taraflar ve Kapsam</h2>
      <p>
        Bu Kullanım Koşulları, <code>[Şirket Ünvanı]</code> (bundan sonra "Ehliyet Akademi" veya
        "biz") tarafından sunulan web uygulamasını kullanan kişilerle ("kullanıcı", "siz")
        aramızdaki sözleşmeyi düzenler. Hizmeti kullanarak bu koşulları kabul etmiş olursunuz.
      </p>

      <h2>2. Hizmetin Tanımı</h2>
      <p>
        Ehliyet Akademi, B sınıfı sürücü belgesi sınavına <strong>eğitim amaçlı hazırlık</strong>{' '}
        sunan bir platformdur; tanı denemeleri, konu çalışması, soru bankası ve hazırlık skoru gibi
        araçlar içerir.
      </p>
      <p>
        <strong>
          Bu hizmet resmî bir MEB/MTSK sınavı DEĞİLDİR ve resmî bir sınav sonucu doğurmaz.
        </strong>{' '}
        Uygulamadaki denemeler gerçek sınav formatını taklit eden hazırlık araçlarıdır. Güncel resmî
        kural, müfredat ve sınav koşulları için MEB/MTSK ve kayıtlı olduğunuz sürücü kursu esastır.
      </p>

      <h2>3. Hesap ve Kullanıcı Sorumlulukları</h2>
      <ul>
        <li>Hesap oluştururken doğru ve güncel bilgi vermekle yükümlüsünüz.</li>
        <li>
          Hesap güvenliğinizden (şifrenizin gizliliği dahil) siz sorumlusunuz; hesabınız üzerinden
          yapılan işlemlerden sorumlu tutulabilirsiniz.
        </li>
        <li>
          Hizmeti hukuka aykırı amaçlarla, başkalarının haklarını ihlal edecek şekilde veya sistemin
          güvenliğini tehdit edecek biçimde kullanamazsınız.
        </li>
        <li>
          İçeriği izinsiz kopyalayamaz, çoğaltamaz, yeniden satamaz veya toplu şekilde çekip
          (scraping) dağıtamazsınız.
        </li>
      </ul>

      <h2>4. Satın Alma Modeli: Tek Seferlik Ödeme, Ömür Boyu Erişim</h2>
      <p>
        Ehliyet Akademi premium içeriği <strong>tek seferlik satın alma</strong> ile sunulur.{' '}
        <strong>Abonelik yoktur;</strong> yinelenen (tekrar eden) ücret alınmaz. Bir premium paket
        satın aldığınızda, ilgili içeriğe <strong>ömür boyu erişim</strong> elde edersiniz.
      </p>
      <ul>
        <li>Fiyatlar satın alma anında uygulamada gösterilir ve KDV dahil belirtilir.</li>
        <li>
          Erişim, hesabınıza tanımlanır; premium içerik hizmet mevcut olduğu sürece kullanılabilir.
        </li>
        <li>
          "Ömür boyu", ürünün ve şirketin faaliyetini sürdürdüğü makul yaşam döngüsü ile sınırlıdır;
          hizmetin sonlandırılması halinde 12. madde uygulanır.
        </li>
      </ul>

      <h2>5. Dijital İçerikte Cayma Hakkı ve İstisnası</h2>
      <p>
        Sunduğumuz premium içerik, elektronik ortamda anında sunulan{' '}
        <strong>dijital içeriktir</strong>. Mesafeli Sözleşmeler Yönetmeliği uyarınca, tüketicinin
        onayıyla ifasına başlanan ve elektronik ortamda anında ifa edilen dijital içerik
        teslimatlarında <strong>cayma hakkı istisnası</strong> geçerlidir.
      </p>
      <ul>
        <li>
          Satın alma sırasında, içeriğe erişiminizin hemen başlamasını ve bu durumda{' '}
          <strong>cayma hakkınızı kaybedeceğinizi</strong> onaylamanız istenir.
        </li>
        <li>
          Bu onayı verip içeriğe erişim başladıktan sonra kural olarak cayma hakkı kullanılamaz.
        </li>
        <li>
          İçeriğin ayıplı olması (ör. teknik nedenle erişilememesi) halinde tüketici mevzuatı
          kapsamındaki haklarınız saklıdır. Bu tür durumlarda <code>[destek e-postası]</code>{' '}
          üzerinden bize ulaşın.
        </li>
      </ul>

      <h2>6. Fikri Mülkiyet</h2>
      <p>
        Uygulamadaki sorular, açıklamalar, ders içerikleri, tasarım ve yazılım{' '}
        <strong>özgün içeriktir</strong> ve fikri mülkiyet hakları Ehliyet Akademi'ye veya lisans
        verenlerine aittir. Sorular resmî müfredattan yola çıkılarak kendi ifademizle yazılmıştır.
        Size yalnızca kişisel, devredilemez ve münhasır olmayan bir kullanım hakkı tanınır; içeriği
        ticari amaçla çoğaltamaz veya dağıtamazsınız.
      </p>

      <h2>7. Sorumluluk Reddi</h2>
      <ul>
        <li>
          <strong>Sınav başarısı garanti edilmez.</strong> Hazırlık skoru ve deneme sonuçları
          tahmini araçlardır; gerçek sınavda başarıyı taahhüt etmez.
        </li>
        <li>
          İçerik "olduğu gibi" sunulur. Doğruluğu için makul özeni gösteririz; ancak güncel resmî
          kural için MEB/MTSK ve sürücü kursunuz esastır.
        </li>
        <li>
          Yürürlükteki hukukun izin verdiği ölçüde, dolaylı zararlardan ve hizmetin kesintiye
          uğramasından doğan zararlardan sorumluluğumuz sınırlıdır.
        </li>
      </ul>

      <h2>8. Hizmette Değişiklik</h2>
      <p>
        İçeriği ve özellikleri geliştirmek, güncellemek veya bazı işlevleri değiştirmek için makul
        değişiklikler yapabiliriz. Satın aldığınız premium içeriğin esaslı kapsamını haksız biçimde
        daraltmamaya özen gösteririz.
      </p>

      <h2>9. Ücretler ve Faturalandırma</h2>
      <p>
        Satın alma sonrası, geçerli mevzuata uygun olarak elektronik fatura/e-arşiv belgesi
        düzenlenir. Fatura için gerekli bilgiler satın alma sırasında talep edilebilir.
      </p>

      <h2>10. Fesih</h2>
      <p>
        Hesabınızı dilediğiniz zaman kapatabilirsiniz. Bu koşulları önemli ölçüde ihlal etmeniz
        halinde, hizmete erişiminizi askıya alabilir veya sonlandırabiliriz. Fesih halinde, dijital
        içerikte ifası tamamlanmış satın almalara ilişkin ücretler kural olarak iade edilmez; yasal
        iade hakları saklıdır.
      </p>

      <h2>11. Hizmetin Sona Ermesi</h2>
      <p>
        Hizmeti sonlandırmayı planlarsak, makul bir süre önceden bilgilendirmeye ve verilerinizi
        dışa aktarmanıza olanak tanımaya çalışırız. Bu durumda mevzuatın gerektirdiği hallerde uygun
        iade veya çözümler değerlendirilir.
      </p>

      <h2>12. Uygulanacak Hukuk ve Yetki</h2>
      <p>
        Bu koşullara <strong>Türkiye Cumhuriyeti hukuku</strong> uygulanır. Uyuşmazlıklarda,
        tüketiciler için ilgili tüketici hakem heyetleri ve tüketici mahkemeleri yetkilidir; ilgili
        parasal sınırlar geçerlidir.
      </p>

      <h2>13. İletişim</h2>
      <p>
        Sorularınız için: <code>[Şirket Ünvanı]</code>, <code>[Adres]</code>, e-posta{' '}
        <code>[destek e-postası]</code>, KEP <code>[KEP adresi]</code>.
      </p>
    </article>
  );
}
