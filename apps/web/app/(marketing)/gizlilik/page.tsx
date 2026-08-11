import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';
import { SUB_PROCESSORS } from '@/lib/legal-entity';
import { retentionRules, retentionText } from '@/lib/retention';
import { LegalIdentity } from '../_legal/LegalIdentity';

export const metadata: Metadata = buildMetadata({
  title: 'Gizlilik Politikası',
  description:
    'Ehliyet Akademi gizlilik politikası: Android uygulaması ve web sitesinde hangi kişisel verileri işliyoruz, hangi amaçla, kimlerle paylaşıyoruz, ne kadar süreyle saklıyoruz ve haklarınızı nasıl kullanırsınız.',
  path: '/gizlilik',
});

/**
 * Gizlilik Politikası — **Android uygulaması + web sitesi** için tek metin.
 *
 * Bu sayfa 10 Ağustos 2026'da baştan yazıldı. Önceki sürüm yalnız web uygulamasını anlatıyor,
 * ilerlemenin "tarayıcının localStorage alanında" tutulduğunu söylüyor ve analitik, çökme raporu,
 * AI Koç, Google ile giriş, Play Faturalandırma, topluluk ve bildirimlerden hiç söz etmiyordu.
 * Ayrıca "yaklaşık konum düzeyinde IP kaydı" ifadesi, Play Veri Güvenliği formundaki
 * "konum toplanmıyor" beyanıyla çelişiyordu.
 *
 * KURAL: buradaki her cümle koddaki bir akışa karşılık gelir. Yeni bir veri akışı eklendiğinde bu
 * sayfa aynı değişiklikte güncellenir — beyan ile gerçek ayrılırsa ikisi de değersizleşir.
 */
export default function GizlilikPage() {
  return (
    <article
      className="legal container"
      data-testid="legal-gizlilik"
      style={{ maxWidth: 820, margin: '0 auto' }}
    >
      <h1>Gizlilik Politikası</h1>
      <p className="muted">Son güncelleme: 10 Ağustos 2026</p>

      <h2>1. Kısaca</h2>
      <p>
        Ehliyet Akademi, A, B ve D sınıfı sürücü belgesi sınavına hazırlık sunan bir{' '}
        <strong>Android uygulaması</strong> ve bir <strong>web sitesidir</strong>. Bu politika her
        ikisini de kapsar.
      </p>
      <p>
        Uygulamanın tamamı <strong>hesap açmadan</strong> kullanılabilir. Hesap açmazsanız
        ilerlemeniz yalnız cihazınızda kalır. Hesap açarsanız ilerlemeniz sunucularımıza
        senkronlanır. Bunun dışında, hesabınız olsun olmasın, uygulama{' '}
        <strong>kimliksiz kullanım istatistikleri ve hata raporları</strong> gönderir; bunlar
        aşağıda ayrıntılı anlatılmıştır. KVKK kapsamındaki resmî aydınlatma metni için{' '}
        <a href="/kvkk">KVKK Aydınlatma Metni</a> sayfasına bakın.
      </p>

      <h2>2. Veri Sorumlusu</h2>
      <LegalIdentity />

      <h2>3. İşlediğimiz Kişisel Veriler</h2>

      <h3>3.1 Hesap verileri — yalnız hesap açarsanız</h3>
      <ul>
        <li>
          <strong>E-posta adresiniz ve adınız.</strong> Şifreniz özetlenerek (hash) saklanır; açık
          metin şifre tutulmaz.
        </li>
        <li>
          <strong>Google ile giriş.</strong> Bu yolu seçerseniz Google bize e-posta adresinizi ve
          adınızı iletir. Google hesabınızın şifresi bize ulaşmaz.
        </li>
        <li>
          <strong>Oturum kayıtları.</strong> Giriş yaptığınızda bir oturum jetonu üretilir ve
          cihazınızla ilişkilendirilir.
        </li>
      </ul>

      <h3>3.2 Çalışma ve ilerleme verisi</h3>
      <ul>
        <li>
          <strong>Hesapsız kullanımda</strong> çözdüğünüz sorular, doğru/yanlış istatistikleri,
          hazırlık puanınız ve tekrar planınız <strong>yalnız cihazınızda</strong> tutulur.
        </li>
        <li>
          <strong>Hesap açtığınızda</strong> bu veriler hesabınıza bağlanır ve sunucularımıza
          senkronlanır; böylece başka bir cihazda kaldığınız yerden devam edebilirsiniz.
        </li>
      </ul>

      <h3>3.3 Kullanım istatistikleri (analitik)</h3>
      <p>
        Uygulama, hangi ekranların kullanıldığını ve hangi akışların yarıda kaldığını anlamak için
        olay kayıtları gönderir. Bu kayıtlar <strong>kendi sunucularımıza</strong> gider; üçüncü
        taraf bir analitik SDK&apos;sı kullanılmaz.
      </p>
      <ul>
        <li>
          Olayların yanında cihaz başına bir kez üretilen <strong>rastgele bir kimlik</strong>{' '}
          taşınır. Bu kimlik <strong>reklam kimliği değildir</strong>, sizi tanımlamaz ve uygulamayı
          kaldırdığınızda kaybolur.
        </li>
        <li>
          Olayların içine <strong>kişisel veri konmaz</strong>: e-posta, ad, serbest metin veya
          verdiğiniz cevaplar gönderilmez. Yalnız sayılar, bayraklar ve kısa kimlikler taşınır.
        </li>
      </ul>

      <h3>3.4 Hata ve çökme raporları</h3>
      <p>
        Uygulama beklenmedik bir hatayla karşılaştığında, hatanın türünü ve oluştuğu yeri anlatan
        bir rapor <strong>kendi sunucularımıza</strong> gönderilir. Crashlytics, Sentry gibi üçüncü
        taraf bir çökme raporlama aracı kullanılmaz.
      </p>

      <h3>3.5 AI Koç</h3>
      <ul>
        <li>
          AI Koç&apos;a yazdığınız <strong>soru metni</strong> sunucularımıza, oradan da yanıtı
          üreten model sağlayıcısına (Anthropic) iletilir.
        </li>
        <li>
          Soru metniniz <strong>kalıcı bir tabloya yazılmaz</strong>; yanıt üretildikten sonra
          saklanmaz.
        </li>
        <li>
          Yanıtlar bir <strong>yapay zekâ modeli</strong> tarafından üretilir ve uygulamanın ders ve
          soru içeriğine dayandırılır. Kesin ve güncel kural için MEB/MTSK mevzuatı esastır.
        </li>
      </ul>

      <h3>3.6 Satın alma</h3>
      <ul>
        <li>
          Premium satın alma <strong>tamamen Google Play üzerinden</strong> yapılır. Kart numaranız
          veya ödeme bilgileriniz <strong>bize hiç ulaşmaz</strong>.
        </li>
        <li>
          Google Play&apos;in döndürdüğü <strong>satın alma jetonu</strong>, ürün kimliği ve satın
          alma tarihi hesabınıza bağlı olarak saklanır; erişiminizi tanımlamak ve başka bir cihazda
          geri yüklemek için gereklidir.
        </li>
      </ul>

      <h3>3.7 Topluluk — tamamen isteğe bağlı</h3>
      <ul>
        <li>
          Topluluğa <strong>katılmazsanız hiçbir bilginiz paylaşılmaz.</strong>
        </li>
        <li>
          Katılırsanız yalnız{' '}
          <strong>seçtiğiniz görünen ad, avatarınız ve çalışma istatistikleriniz</strong> diğer
          kullanıcılara görünür. <strong>E-posta adresiniz ve gerçek adınız asla görünmez.</strong>
        </li>
        <li>
          Yazdığınız mesajlar, tartışma gönderileri ve grup içerikleri, diğer kullanıcıların
          okuyabilmesi ve bildirimlerin incelenebilmesi için saklanır.
        </li>
        <li>
          Avatar olarak bir görsel seçerseniz, seçtiğiniz <strong>tek görsel</strong> yüklenir.
          Uygulama galerinizi taramaz ve depolama izni istemez.
        </li>
      </ul>

      <h3>3.8 Bildirimler</h3>
      <p>
        Çalışma hatırlatmaları <strong>cihazınızda yerel olarak</strong> planlanır. Uzaktan anlık
        bildirim (push) altyapısı kullanılmaz; bu nedenle bir bildirim jetonu toplanmaz.
      </p>

      <h3>3.9 Teknik veriler</h3>
      <p>
        Hizmetin çalışması ve güvenliği için isteklerinize ait teknik veriler (oturum bilgisi, istek
        zamanı, IP adresi) barındırma sağlayıcımızın işlem günlüklerinde geçici olarak yer alır.
        Davet sistemindeki kötüye kullanımı tespit etmek için IP adresi{' '}
        <strong>ham hâliyle saklanmaz</strong>; yalnız geri çevrilemez biçimde özetlenmiş (tuzlu
        SHA-256) hâli tutulur.
      </p>

      <h2>4. Toplamadığımız Veriler</h2>
      <p>Aşağıdakiler uygulama tarafından toplanmaz ve ilgili izinler istenmez:</p>
      <ul>
        <li>
          <strong>Konum.</strong> Uygulama konum izni istemez ve konum verisi işlemez.
        </li>
        <li>
          <strong>Rehber, takvim, SMS, arama kayıtları, mikrofon.</strong>
        </li>
        <li>
          <strong>Reklam kimliği (AAID/GAID).</strong> Uygulamada reklam yoktur ve reklam kimliği
          okunmaz.
        </li>
        <li>
          <strong>Sağlık verisi.</strong> İlk yardım içeriği bir sınav konusudur, sağlık kaydı
          değildir.
        </li>
      </ul>

      <h2>5. İşleme Amaçları</h2>
      <ul>
        <li>Hizmeti sunmak, hesabınızı oluşturmak ve oturumunuzu yönetmek.</li>
        <li>Çalışma ilerlemenizi göstermek ve cihazlar arasında senkronlamak.</li>
        <li>Premium erişimi tanımlamak ve geri yüklemek.</li>
        <li>AI Koç yanıtlarını üretmek.</li>
        <li>Topluluk özelliklerini çalıştırmak ve bildirilen içerikleri incelemek.</li>
        <li>Hataları teşhis etmek ve ürünü geliştirmek.</li>
        <li>Güvenliği sağlamak, kötüye kullanımı ve dolandırıcılığı önlemek.</li>
        <li>Yasal yükümlülükleri yerine getirmek.</li>
      </ul>

      <h2>6. Alt İşleyiciler</h2>
      <p>
        Hizmeti sunabilmek için aşağıdaki sağlayıcılarla çalışırız. Her birine yalnız gerekli veri,
        gerektiği kadar aktarılır:
      </p>
      <table>
        <thead>
          <tr>
            <th>Sağlayıcı</th>
            <th>Amaç</th>
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
        Bu sağlayıcılar verileri <strong>yalnız bizim adımıza</strong> ve bu politikadaki amaçlarla
        işler. Verilerinizi reklam amacıyla üçüncü taraflara satmayız veya kiralamayız.
      </p>

      <h2>7. Saklama Süreleri</h2>
      <p>
        Aşağıdaki süreler, sunucudaki günlük temizleme işinin uyguladığı sürelerin
        <strong> aynısıdır</strong> — sayfa ile davranış tek kaynaktan (
        <code>lib/retention.ts</code>) gelir. Hiçbiri &quot;kanun şu kadar diyor&quot; iddiası
        taşımaz; her biri, veriyi işleme amacı için gereken en kısa makul süredir ve ortam
        değişkeniyle değiştirilebilir.
      </p>
      <div style={{ overflowX: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>Veri</th>
              <th>Neden</th>
              <th>Saklama</th>
            </tr>
          </thead>
          <tbody>
            {retentionRules().map((rule) => (
              <tr key={rule.key}>
                <td>
                  <strong>{rule.label}</strong>
                </td>
                <td>{rule.why}</td>
                <td>{retentionText(rule)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <ul>
        <li>
          <strong>Cihazdaki ilerleme verisi:</strong> siz uygulamayı kaldırana veya verileri
          temizleyene kadar cihazınızda kalır; sunucuya hiç gitmemiş olabilir.
        </li>
        <li>
          <strong>AI Koç soru metni:</strong> kalıcı olarak saklanmaz.
        </li>
        <li>
          <strong>Satın alma kayıtları hesapla birlikte silinir.</strong> Tuttuğumuz kayıt fatura
          değil, erişiminizi geri yüklemeye yarayan hak sahipliği kaydıdır; ödemenin malî kaydı
          Google Play tarafında durur.
        </li>
      </ul>

      <h2>8. Hesabınızı ve Verilerinizi Silme</h2>
      <p>
        Hesabınızı <strong>uygulama içinden</strong> silebilirsiniz: <em>Profil → Hesabımı sil</em>.
        İşlem şifrenizle onaylanır ve hesabınıza bağlı ilerleme, topluluk profili, mesajlar ve
        erişim kayıtları aynı işlemde silinir.
      </p>
      <p>
        Uygulama kurulu değilse veya ayrıntılı bilgi istiyorsanız{' '}
        <a href="/hesap-silme">Hesap ve Veri Silme</a> sayfasına bakın.
      </p>

      <h2>9. Haklarınız</h2>
      <p>
        Verilerinize erişme, düzeltilmesini isteme, silinmesini talep etme, işlemeye itiraz etme ve
        mümkün olduğunda taşınmasını isteme haklarına sahipsiniz. KVKK kapsamındaki ayrıntılı haklar
        ve başvuru yöntemi için <a href="/kvkk">KVKK Aydınlatma Metni</a> sayfasına bakın.
      </p>

      <h2>10. Veri Güvenliği</h2>
      <p>
        Tüm ağ trafiği <strong>HTTPS</strong> ile şifrelenir. Şifreler özetlenerek saklanır, erişim
        yetkileri kısıtlıdır ve bağımlılıklar düzenli olarak güncellenir. Hiçbir yöntem mutlak
        güvenlik sağlamaz; riski azaltmak için makul teknik ve idari tedbirleri alırız.
      </p>

      <h2>11. Çocukların Gizliliği</h2>
      <p>
        Hizmet, sürücü belgesi sınavına hazırlanan <strong>18 yaş ve üzeri</strong> adaylara
        yöneliktir. Bilerek 13 yaş altı kullanıcılardan veri toplamayız.
      </p>

      <h2>12. Çerezler</h2>
      <p>
        Web sitesindeki çerezler ve yerel depolama hakkında ayrıntı için{' '}
        <a href="/cerez-politikasi">Çerez Politikası</a> sayfasına bakın. Android uygulaması çerez
        kullanmaz.
      </p>

      <h2>13. Bu Politikadaki Değişiklikler</h2>
      <p>
        Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişikliklerde uygulama içinde veya
        e-posta ile bilgilendirme yaparız. Yürürlükteki sürümün tarihi sayfanın üstünde belirtilir.
      </p>
    </article>
  );
}
