# Kapalı Test Rehberi — 12 Test Kullanıcısı

**Uygulama:** Ehliyet Akademi · `com.ehliyetegitim.ehliyet_akademi`
**Hedef:** Google Play Kapalı Test kanalında 12 test kullanıcısıyla sürüm adayını doğrulamak.

---

## 1. Neden 12 kişi ve neden önemli

Google, **yeni geliştirici hesaplarının** (özellikle birey hesapların) uygulamayı genel yayına
alabilmesi için kapalı testte belirli bir katılım şartı arar: **en az 12 test kullanıcısı**,
**kesintisiz 14 gün** boyunca teste dâhil olmalı ve uygulamayı gerçekten kullanmalıdır.

Bunun pratik sonuçları:

- 12 kişi **listede durmakla yetmez**; teste **katılmış** (opt-in bağlantısını açıp uygulamayı
  kurmuş) olmalıdır.
- 14 gün **kesintisizdir**. Biri listeden çıkarsa sayaç sıfırlanabilir → **12 değil, 14–15 kişi
  davet edin**.
- Süre boyunca yeni sürüm yayınlayabilirsiniz; sayaç sıfırlanmaz.

## 2. Test kullanıcısı listesi oluşturma

Play Console → **Test → Kapalı test → Test kullanıcıları**

1. **E-posta listesi oluştur** → ad: `Ehliyet Akademi — Beta 12`.
2. Google hesabı e-postalarını ekleyin (**Gmail veya Google Workspace hesabı olmalı**; başka
   sağlayıcının adresi çalışmaz).
3. Listeyi sürüme bağlayın.

> Test kullanıcılarını `GOOGLE_AUTH_SETUP.md` §5'teki **OAuth onay ekranı test kullanıcıları**
> listesine de ekleyin. Onay ekranı "Test" modundayken oraya eklenmemiş bir hesap Google ile
> giriş yapamaz.

### Takip tablosu şablonu

| #   | Ad  | E-posta (Google) | Davet | Katıldı | Kurdu | Not |
| --- | --- | ---------------- | ----- | ------- | ----- | --- |
| 1   |     |                  | ☐     | ☐       | ☐     |     |
| …   |     |                  |       |         |       |     |
| 15  |     |                  |       |         |       |     |

## 3. Katılım bağlantısı

Kapalı test sürümü yayınlandıktan sonra Play Console **opt-in URL** verir:

```
https://play.google.com/apps/testing/com.ehliyetegitim.ehliyet_akademi
```

Test kullanıcısına gönderilecek metin:

> **Ehliyet Akademi beta testine davetlisin.**
>
> 1. Aşağıdaki bağlantıyı **davet edildiğin Google hesabıyla** aç:
>    https://play.google.com/apps/testing/com.ehliyetegitim.ehliyet_akademi
> 2. **"Become a tester" / "Test kullanıcısı ol"** düğmesine bas.
> 3. Aynı sayfadaki Play Store bağlantısından uygulamayı kur.
> 4. Lütfen **14 gün boyunca testten çıkma** — Google'ın şartı bu.
>
> Sorun yaşarsan: <destek e-postası>

**Sık karşılaşılan sorunlar:**

| Belirti                                | Neden                                                 |
| -------------------------------------- | ----------------------------------------------------- |
| "Bu uygulama cihazınızla uyumlu değil" | Farklı Google hesabıyla giriş yapılmış                |
| Bağlantı 404                           | Sürüm henüz **yayınlanmamış** (taslak durumda)        |
| Play'de uygulama görünmüyor            | Katılım sonrası yayılma **birkaç saat** sürebilir     |
| Güncelleme gelmiyor                    | Play Store → uygulama sayfası → aşağı çekip yenileyin |

## 4. Test kullanıcılarının sınaması istenen akışlar

Beta testinin amacı "uygulama açılıyor mu" değil; **sürüm adayının gerçek kullanımda ayakta
kalması**. Aşağıdaki senaryolar test kullanıcılarına açıkça verilir.

### 4.1 İlk açılış

- [ ] Tanıtım (onboarding) akıcı mı, görseller ekrana sığıyor mu, **kaydırma gerekmiyor** mu
- [ ] Karşılama/AI tanıtımı anlaşılır mı
- [ ] Ana Sayfa'ya inildiğinde ne yapılacağı belli mi

### 4.2 Hesap

- [ ] **Google ile giriş** çalışıyor mu
- [ ] E-posta + parola ile kayıt/giriş çalışıyor mu
- [ ] Misafir olarak kullanmaya devam edilebiliyor mu
- [ ] Çıkış → yeniden giriş → ilerleme korunuyor mu

### 4.3 Öğrenme

- [ ] Dersler açılıyor, okunabiliyor mu
- [ ] Trafik işaretleri galerisi akıcı mı
- [ ] Araç tekniği ve **kabin kumandaları** detayları açılıyor mu
- [ ] Videolar oynuyor mu; altyazı, bölümler, tam ekran çalışıyor mu

### 4.4 Pratik

- [ ] Soru çözme, deneme sınavı, sonuç ekranı
- [ ] İlerleme kaydediliyor mu (uygulamayı kapatıp açınca)

### 4.5 AI Koç

- [ ] Yanıtlar **akarak** geliyor mu (Faz 9)
- [ ] Yanlış/uygunsuz yanıt bildirilebiliyor mu

### 4.6 Topluluk (isteğe bağlı katılım)

- [ ] Topluluğa katılma açıkça isteğe bağlı mı
- [ ] Sıralama, arkadaşlık, mesajlaşma, gruplar çalışıyor mu
- [ ] **Engelleme ve şikâyet** çalışıyor mu
- [ ] **Profil fotoğrafı** yükleme çalışıyor mu (Faz 7)

### 4.7 Premium

- [ ] Ödeme ekranı fiyatı doğru gösteriyor mu
- [ ] Satın alma tamamlanıyor mu (**lisans test hesabı** ile)
- [ ] **"Satın Alımı Geri Yükle"** çalışıyor mu (uygulamayı silip kurduktan sonra)

### 4.8 Dayanıklılık

- [ ] Uçak modunda uygulama **çökmüyor**, dürüst hata gösteriyor mu
- [ ] Arka plandan dönünce video/oturum durumu korunuyor mu
- [ ] Ekranı döndürünce yerleşim bozulmuyor mu
- [ ] Açık tema ile koyu tema arasında geçiş sorunsuz mu

## 5. Geri bildirim toplama

**Play'in kendi kanalı:** Play Console → Kapalı test → **Geri bildirim** sekmesi. Test
kullanıcıları Play Store uygulama sayfasından geri bildirim gönderebilir (bu yorumlar **herkese
açık değildir**).

**Doğrudan kanal (önerilir):** destek e-postası veya basit bir form. İstenen bilgiler:

```
Cihaz modeli / Android sürümü:
Uygulama sürümü (Profil → Hakkında):
Ne yapıyordum:
Ne bekliyordum:
Ne oldu:
Ekran görüntüsü:
```

**Çökme raporları:** Play Console → **Kalite → Android vitals → Çökmeler ve ANR'ler**. Test
sürümünde bile toplanır ve düzeltilmesi gereken ilk şeydir.

## 6. Sürüm döngüsü

```
Düzeltme → versionCode artır (pubspec `1.0.0+N`) → AAB derle → kapalı teste yükle
   → test kullanıcıları güncellemeyi otomatik alır → geri bildirim → tekrar
```

- Küçük düzeltmelerde `versionName` sabit kalabilir, **versionCode her zaman artar**.
- Sürüm notlarını Türkçe ve **somut** yazın ("Giriş ekranı yenilendi", "Video altyazısı düzeltildi").

## 7. Kapalı testten çıkış ölçütleri

Genel yayına (veya açık teste) geçmeden önce hepsi sağlanmalı:

- [ ] 12+ test kullanıcısı **14 gün kesintisiz** katılımı tamamladı
- [ ] Android vitals'ta **çökme oranı < %1**, ANR **< %0,5**
- [ ] §4'teki senaryoların tamamı en az iki farklı cihazda geçti
- [ ] Google girişi **Play'den kurulan** yapıda çalıştı (Play App Signing SHA'sı eklenmiş)
- [ ] Satın alma **ve** geri yükleme gerçek Play akışında çalıştı
- [ ] Veri Güvenliği formu **koddaki gerçek davranışla** birebir
- [ ] `RELEASE_AUDIT_REPORT.md` (Faz 13) **GO** diyor
