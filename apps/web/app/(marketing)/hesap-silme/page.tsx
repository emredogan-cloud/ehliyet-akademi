import type { Metadata } from 'next';
import { buildMetadata } from '@/lib/seo/metadata';
import { DELETION_REQUEST_SLA_DAYS, retentionRules, retentionText } from '@/lib/retention';
import { LegalIdentity } from '../_legal/LegalIdentity';

export const metadata: Metadata = buildMetadata({
  title: 'Hesap ve Veri Silme',
  description:
    'Ehliyet Akademi hesabınızı ve verilerinizi nasıl silersiniz: uygulama içi adımlar, silinen veriler, veri türü başına saklama süreleri ve uygulama kurulu değilken izlenecek yol.',
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
 * ## §4 neden yeniden yazıldı
 *
 * Önceki sürüm, satın alma/fatura kayıtlarının "mevzuatın öngördüğü süre boyunca" saklandığını
 * söylüyordu. Kod bunu YAPMIYOR: `purchases.user_id` şemada `ON DELETE CASCADE` taşır, yani
 * hesap silindiğinde satın alma kaydı **aynı işlemde yok olur**. Sayfa, sunucunun yapmadığı bir
 * şeyi anlatıyordu; düzeltildi. Malî kaydın aslı zaten ödemeyi alan Google Play'de durur — bizim
 * tablomuz muhasebe defteri değil, hak sahipliği defteridir.
 *
 * Süreler artık `lib/retention.ts` dosyasından RENDER EDİLİR; burada elle yazılmış ikinci bir
 * liste yoktur. Aynı liste `app/api/cron/retention` işi tarafından uygulanır, böylece sayfadaki
 * cümle ile sunucunun davranışı tek kaynaktan gelir.
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
        sayfa, silme işleminin nasıl yapıldığını, tam olarak neyin silindiğini ve hangi verinin ne
        kadar süreyle saklandığını açıklar.
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

      <h2>4. Saklama süreleri</h2>
      <p>
        Aşağıdaki tablo, hangi verinin ne kadar süre tutulduğunu ve nasıl silindiğini gösterir.
        Tablo, sunucudaki temizleme işinin <strong>okuduğu listenin ta kendisidir</strong>: burada
        yazan süre ile uygulanan süre aynı kaynaktan gelir.
      </p>
      <div style={{ overflowX: 'auto' }}>
        <table>
          <thead>
            <tr>
              <th>Veri</th>
              <th>Saklama</th>
              <th>Nasıl silinir</th>
            </tr>
          </thead>
          <tbody>
            {retentionRules().map((rule) => (
              <tr key={rule.key}>
                <td>
                  <strong>{rule.label}</strong>
                  <br />
                  <span className="muted">{rule.what}</span>
                </td>
                <td>{retentionText(rule)}</td>
                <td>{rule.deletion}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p>
        <strong>Satın alma kayıtları hesapla birlikte silinir.</strong> Bizim tuttuğumuz kayıt bir
        fatura değil, premium erişiminizin geri yüklenmesini sağlayan hak sahipliği kaydıdır.
        Ödemenin malî kaydı, ödemeyi tahsil eden <strong>Google Play</strong> tarafında tutulur ve
        oradaki saklama süresi Google&apos;ın kendi politikasına tabidir.
      </p>
      <p className="muted">
        Kimliksiz kullanım ve hata kayıtları hesabınız silindiğinde{' '}
        <em>kullanıcı bağından koparılır</em> — kayıt kalsa bile sizi göstermez — ve yukarıdaki süre
        dolduğunda tamamen silinir. İnceleme sürecinde (<code>open</code>) olan bir topluluk
        bildirimi, inceleme kapanana kadar silinmez.
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
        <strong>{DELETION_REQUEST_SLA_DAYS} gün</strong> içinde sonuçlandırılır.
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
