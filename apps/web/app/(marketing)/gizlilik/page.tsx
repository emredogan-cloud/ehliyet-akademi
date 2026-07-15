import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Gizlilik Politikası',
  description:
    'Ehliyet Akademi gizlilik politikası: hangi kişisel verileri işliyoruz, hangi amaçla, ne kadar süreyle saklıyoruz ve haklarınızı nasıl kullanabilirsiniz.',
};

export default function GizlilikPage() {
  return (
    <article
      className="legal container"
      data-testid="legal-gizlilik"
      style={{ maxWidth: 820, margin: '0 auto' }}
    >
      <h1>Gizlilik Politikası</h1>
      <p className="muted">Son güncelleme: 15 Temmuz 2026</p>

      <div className="explain" role="note">
        <strong>Taslak belge uyarısı.</strong> Bu metin bir <em>taslaktır (template)</em> ve henüz
        kuruluşu tamamlanmamış bir ürün için hazırlanmıştır. Kamuya açık yayına alınmadan önce bir
        avukat tarafından gözden geçirilmelidir. Metindeki şirket ve iletişim bilgileri —{' '}
        <code>[Şirket Ünvanı]</code>, <code>[VKN]</code>, <code>[Adres]</code>,{' '}
        <code>[KEP adresi]</code>, <code>[destek e-postası]</code> — yalnızca yer tutucudur ve
        gerçek bir tüzel kişiliği temsil etmez.
      </div>

      <h2>1. Kısaca</h2>
      <p>
        Ehliyet Akademi, B sınıfı sürücü belgesi sınavına eğitim amaçlı hazırlık sunan bir web
        uygulamasıdır. Kişisel verilerinizi mümkün olduğunca az toplamayı ilke ediniyoruz. Çalışma
        ilerlemenizin büyük kısmı hesabınıza değil, doğrudan <strong>kendi cihazınızda</strong>{' '}
        (tarayıcının localStorage alanında) tutulur. Bu politika, hangi verileri neden işlediğimizi
        ve haklarınızı açıklar. KVKK kapsamındaki resmî aydınlatma metni için{' '}
        <a href="/kvkk">KVKK Aydınlatma Metni</a> sayfamıza bakabilirsiniz.
      </p>

      <h2>2. Veri Sorumlusu</h2>
      <p>
        Veri sorumlusu <code>[Şirket Ünvanı]</code> (VKN: <code>[VKN]</code>, adres:{' '}
        <code>[Adres]</code>) olup, bu politika kapsamındaki işlemlerden sorumludur. Sorularınız
        için <code>[destek e-postası]</code> adresi üzerinden bize ulaşabilirsiniz.
      </p>

      <h2>3. İşlediğimiz Kişisel Veriler</h2>
      <ul>
        <li>
          <strong>Hesap verileri:</strong> Bir hesap oluşturursanız e-posta adresiniz ve adınız
          (görünen ad). Şifreniz güvenli biçimde özetlenerek (hash) saklanır; açık metin şifre
          tutulmaz.
        </li>
        <li>
          <strong>İlerleme verisi:</strong> Çözdüğünüz sorular, doğru/yanlış istatistikleri,
          hazırlık skorunuz ve tekrar planınız. Bu veri{' '}
          <strong>çoğunlukla cihazınızda (localStorage)</strong> saklanır. Hesapla senkronizasyonu
          açıkça tercih etmediğiniz sürece sunucularımıza gönderilmez.
        </li>
        <li>
          <strong>Satın alma kaydı:</strong> Bir premium paket satın alırsanız; sipariş numarası,
          satın alınan paket, tutar, tarih ve ödeme sağlayıcının döndürdüğü işlem referansı. Kart
          numarası gibi ödeme bilgileri bize ulaşmaz; bunlar doğrudan ödeme sağlayıcıda işlenir.
        </li>
        <li>
          <strong>Teknik veriler:</strong> Hizmetin güvenliği ve çalışması için oturum bilgileri,
          yaklaşık konum düzeyinde IP kaydı ve temel cihaz/tarayıcı bilgileri. Ayrıntılar için{' '}
          <a href="/cerez-politikasi">Çerez Politikası</a> sayfasına bakın.
        </li>
        <li>
          <strong>Destek yazışmaları:</strong> Bize e-posta ile ulaşırsanız, talebinizi
          yanıtlayabilmek için mesaj içeriğiniz ve iletişim bilgileriniz.
        </li>
      </ul>

      <h2>4. İşleme Amaçları</h2>
      <ul>
        <li>Hizmeti sunmak, hesabınızı oluşturmak ve oturumunuzu yönetmek.</li>
        <li>Çalışma ilerlemenizi ve hazırlık skorunuzu göstermek.</li>
        <li>Premium paket satın alımını gerçekleştirmek ve erişimi tanımlamak.</li>
        <li>Güvenliği sağlamak, kötüye kullanımı ve dolandırıcılığı önlemek.</li>
        <li>Destek taleplerini yanıtlamak ve yasal yükümlülükleri yerine getirmek.</li>
        <li>İzin verdiğiniz ölçüde hizmeti iyileştirmek için toplu (anonim) analiz yapmak.</li>
      </ul>

      <h2>5. Saklama Süreleri</h2>
      <ul>
        <li>
          <strong>Hesap verileri:</strong> Hesabınız aktif olduğu sürece; hesabınızı silerseniz
          makul bir süre içinde (ör. 30 gün) kalıcı olarak silinir veya anonimleştirilir.
        </li>
        <li>
          <strong>Cihazdaki ilerleme verisi:</strong> Siz silene kadar cihazınızda kalır; tarayıcı
          verilerini temizleyerek istediğiniz an kaldırabilirsiniz.
        </li>
        <li>
          <strong>Satın alma / fatura kayıtları:</strong> İlgili vergi ve ticaret mevzuatının
          öngördüğü süre boyunca (genellikle 10 yıla kadar) saklanır.
        </li>
      </ul>

      <h2>6. Üçüncü Taraflar</h2>
      <p>
        Hizmeti sunabilmek için sınırlı sayıda hizmet sağlayıcıyla çalışırız. Bu sağlayıcılara
        yalnız gerekli veriler, gerektiği kadar aktarılır:
      </p>
      <ul>
        <li>
          <strong>Ödeme sağlayıcısı:</strong> Satın alma işlemini güvenli biçimde tamamlamak için.
          Kart bilgileriniz doğrudan sağlayıcıda işlenir.
        </li>
        <li>
          <strong>E-posta sağlayıcısı:</strong> Hesap doğrulama, satın alma onayı ve destek
          e-postalarını iletmek için.
        </li>
        <li>
          <strong>Barındırma (hosting) sağlayıcısı:</strong> Uygulamayı ve verileri güvenli
          sunucularda çalıştırmak için.
        </li>
      </ul>
      <p>
        Bu sağlayıcılarla veri işleme sözleşmeleri yaparız ve verileri yalnız bizim adımıza, bu
        politikadaki amaçlarla işlemelerini isteriz.
      </p>

      <h2>7. Çerezler</h2>
      <p>
        Zorunlu çerezler, tercih çerezleri, yerel depolama ve (rızanıza bağlı) analitik hakkında
        ayrıntılı bilgi ayrı bir belgede yer alır. Lütfen{' '}
        <a href="/cerez-politikasi">Çerez Politikası</a> sayfasını inceleyin.
      </p>

      <h2>8. Haklarınız</h2>
      <p>
        Kişisel verilerinizle ilgili olarak; verilerinize erişme, düzeltilmesini isteme, silinmesini
        talep etme, işlemeye itiraz etme ve mümkün olduğunda verilerinizin taşınmasını isteme
        haklarına sahipsiniz. KVKK kapsamındaki ayrıntılı haklar ve başvuru yöntemi için{' '}
        <a href="/kvkk">KVKK Aydınlatma Metni</a> sayfasına bakabilirsiniz. Taleplerinizi{' '}
        <code>[destek e-postası]</code> veya <code>[KEP adresi]</code> üzerinden iletebilirsiniz.
      </p>

      <h2>9. Veri Güvenliği</h2>
      <p>
        Verilerinizi korumak için aktarımda şifreleme (HTTPS), erişim kısıtlamaları, şifrelerin
        özetlenerek saklanması ve düzenli güncellemeler gibi teknik ve idari tedbirler alırız.
        Hiçbir yöntem yüzde yüz güvenli olmasa da, riski azaltmak için makul özeni gösteririz.
      </p>

      <h2>10. Çocukların Gizliliği</h2>
      <p>
        Hizmet, sürücü belgesi sınavına hazırlanan yetişkinlere ve ilgili yaş aralığındaki adaylara
        yöneliktir. Reşit olmayan kullanıcıların hizmeti veli/vasi bilgisi ve onayı dahilinde
        kullanması beklenir.
      </p>

      <h2>11. Bu Politikadaki Değişiklikler</h2>
      <p>
        Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişikliklerde uygulama içinde veya
        e-posta ile bilgilendirme yaparız. Yürürlükteki sürümün tarihi sayfanın üstünde belirtilir.
      </p>

      <h2>12. İletişim</h2>
      <p>
        Gizlilikle ilgili her türlü soru ve talep için: <code>[Şirket Ünvanı]</code>,{' '}
        <code>[Adres]</code>, e-posta <code>[destek e-postası]</code>, KEP <code>[KEP adresi]</code>
        .
      </p>
    </article>
  );
}
