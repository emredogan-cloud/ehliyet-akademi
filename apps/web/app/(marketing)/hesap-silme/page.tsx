import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';
import { LegalIdentity } from '../_legal/LegalIdentity';

export const metadata: Metadata = buildMetadata({
  title: 'Hesap ve Veri Silme',
  description:
    'Ehliyet Akademi hesabınızı ve verilerinizi nasıl silersiniz: uygulama içi adımlar, silinen veriler, yasal olarak saklanması gereken kayıtlar ve uygulama kurulu değilken izlenecek yol.',
  path: '/hesap-silme',
});

/**
 * Google Play, hesap oluşturulmasına izin veren uygulamalar için **harici (web) bir silme talebi
 * adresi** ister: uygulamayı kaldırmış bir kullanıcı da silme talep edebilmelidir. Bu sayfa o
 * adrestir ve Play Console → Veri güvenliği → Veri silme alanına girilir.
 *
 * İÇERİK KURALI: buradaki her cümle koddaki gerçek davranışa karşılık gelir.
 * · Uygulama içi yol      → `apps/mobile/lib/features/profile/profile_screen.dart` (Hesabımı sil)
 * · Sunucu ucu            → `apps/web/app/api/account/route.ts` (DELETE, şifre ile onay)
 * · Basamaklı silme       → `packages/db/src/index.ts` — users(id) üzerine ON DELETE CASCADE
 *
 * Yasal saklama SÜRELERİ burada SAYI olarak verilmez: mevzuata dayalı süreyi belirlemek hukuki bir
 * karardır ve uydurulamaz. Süre, kurucunun hukuk danışmanıyla belirlediği değerle güncellenecektir
 * (bkz. FOUNDER_RELEASE_HANDOOK.md → F-06).
 */
export default function HesapSilmePage() {
  return (
    <article
      className="legal container"
      data-testid="legal-hesap-silme"
      style={{ maxWidth: 820, margin: '0 auto' }}
    >
      <h1>Hesap ve Veri Silme</h1>
      <p className="muted">Son güncelleme: 10 Ağustos 2026</p>

      <p>
        Ehliyet Akademi hesabınızı ve hesabınıza bağlı verileri istediğiniz zaman silebilirsiniz. Bu
        sayfa, silme işleminin nasıl yapıldığını, tam olarak neyin silindiğini ve hangi kayıtların
        yasal olarak saklanmak zorunda olduğunu açıklar.
      </p>

      <h2>1. Uygulama içinden silme (önerilen yol)</h2>
      <ol>
        <li>Ehliyet Akademi uygulamasını açın.</li>
        <li>
          Alt gezinme çubuğundan <strong>Profil</strong> sekmesine gidin.
        </li>
        <li>
          Listenin en altındaki <strong>Hesabımı sil</strong> satırına dokunun.
        </li>
        <li>
          Açılan pencerede işlemi onaylayın. Güvenlik için <strong>şifrenizi</strong> girmeniz
          istenir.
        </li>
      </ol>
      <p>
        Onaydan sonra hesabınız ve ilişkili kayıtlar <strong>aynı işlemde</strong> silinir. İşlem
        geri alınamaz.
      </p>

      <h2>2. Hesabınız yoksa</h2>
      <p>
        Uygulamayı <strong>hesap açmadan</strong> kullandıysanız sunucularımızda size ait bir hesap
        kaydı <strong>hiç oluşmamıştır</strong>. Bu durumda çalışma verileriniz yalnız cihazınızda
        tutulur; uygulamayı kaldırmanız veya sistem ayarlarından uygulama verilerini temizlemeniz bu
        verileri siler.
      </p>

      <h2>3. Silinen veriler</h2>
      <p>Hesabınızı sildiğinizde aşağıdakiler kalıcı olarak silinir:</p>
      <ul>
        <li>Hesap kaydınız: e-posta adresiniz, adınız ve şifre özetiniz</li>
        <li>Oturumlarınız ve oturum jetonlarınız</li>
        <li>Çalışma ilerlemeniz: çözdüğünüz sorular, istatistikleriniz, hazırlık puanınız</li>
        <li>Tekrar planınız ve koleksiyonlarınız</li>
        <li>Rozetleriniz, seviyeniz ve seri kayıtlarınız</li>
        <li>Topluluk profiliniz: görünen adınız, avatarınız ve katılım durumunuz</li>
        <li>Gönderdiğiniz mesajlar, tartışma gönderileriniz ve grup üyelikleriniz</li>
        <li>Arkadaşlık bağlantılarınız, engelleme listeniz ve davet kayıtlarınız</li>
        <li>Premium erişim kaydınız</li>
      </ul>

      <h2>4. Saklanmaya devam eden kayıtlar</h2>
      <ul>
        <li>
          <strong>Satın alma ve fatura kayıtları.</strong> Vergi ve ticaret mevzuatı, satın alma
          kayıtlarının belirli bir süre saklanmasını zorunlu kılar. Bu kayıtlar hesabınız silinse de
          mevzuatın öngördüğü süre boyunca tutulur ve yalnız bu yasal yükümlülük için kullanılır.
        </li>
        <li>
          <strong>Kimliksiz kullanım ve hata kayıtları.</strong> Bu kayıtlar hesabınızla
          ilişkilendirilmez ve kimliğinizi taşımaz; bu nedenle hesap silindikten sonra da kimliksiz
          biçimde kalabilir. Sizi tanımlamak için kullanılamazlar.
        </li>
        <li>
          <strong>Topluluk bildirimleri.</strong> Hakkınızda veya sizin tarafınızdan yapılmış bir
          içerik bildirimi inceleme sürecindeyse, incelemenin tamamlanabilmesi için ilgili kayıt
          süreç boyunca saklanabilir.
        </li>
      </ul>
      <p className="muted">
        Yasal saklama sürelerinin kesin değerleri, veri sorumlusunun mevzuat değerlendirmesine göre
        bu sayfada yayımlanacaktır.
      </p>

      <h2>5. Google Play satın alımları</h2>
      <p>
        Hesabınızı silmek, Google Play üzerinden yaptığınız bir satın alımı{' '}
        <strong>iptal etmez ve iade etmez</strong>. Abonelik iptali ve iade talepleri Google Play
        üzerinden yürütülür. Ömür boyu paket satın aldıysanız, hesabınızı sildikten sonra yeni bir
        hesapla erişimi geri yüklemek mümkün olmayabilir.
      </p>

      <h2>6. Uygulama kurulu değilse</h2>
      <p>
        Uygulamayı kaldırdıysanız ve hesabınızı silmek istiyorsanız, §7&apos;de belirtilen destek
        adresine <strong>hesabınıza kayıtlı e-posta adresinden</strong> bir silme talebi
        gönderebilirsiniz. Talebiniz kimliğiniz doğrulandıktan sonra en geç{' '}
        <strong>30 (otuz) gün</strong> içinde sonuçlandırılır.
      </p>

      <h2>7. İletişim</h2>
      <LegalIdentity />

      <h2>8. İlgili belgeler</h2>
      <p>
        <a href="/gizlilik">Gizlilik Politikası</a> · <a href="/kvkk">KVKK Aydınlatma Metni</a> ·{' '}
        <a href="/cerez-politikasi">Çerez Politikası</a>
      </p>
    </article>
  );
}
