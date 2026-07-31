# Play Console — Veri Güvenliği (Data Safety) Beyanı

**Beta Faz 9** · 31 Temmuz 2026 · Uygulama: `com.ehliyetegitim.ehliyet_akademi`

Bu belge, Play Console'daki **Veri güvenliği** formunun her sorusuna verilecek cevabı ve o cevabın
**koddaki karşılığını** kayda geçer.

> **Neden bu belge var.** Veri güvenliği formu Google'a verilen bir BEYANDIR ve yanlış doldurulması
> politika ihlalidir — uygulamanın kaldırılmasına kadar gidebilir. Form, geliştiricinin hatırladığına
> göre değil, **kodun gerçekte ne yaptığına** göre doldurulmalı. Aşağıdaki her satırın yanında
> dosya adı var; beyan doğrulanabilir olsun diye.
>
> **Bu beyan Beta Faz 3 ve 4'te DEĞİŞTİ.** Uygulama artık analitik olayları ve hata raporları
> topluyor. Önceki (toplama yapılmayan) beyanla yayına çıkmak yanlış beyan olurdu.

---

## 1. Veri toplanıyor mu? **EVET**

| Play kategorisi              | Toplanıyor | Paylaşılıyor | Zorunlu mu    | Amaç                      | Kod                                                 |
| ---------------------------- | ---------- | ------------ | ------------- | ------------------------- | --------------------------------------------------- |
| **E-posta adresi**           | Evet       | Hayır        | İsteğe bağlı¹ | Hesap yönetimi            | `auth_api.dart` · `api/auth/register`               |
| **Ad**                       | Evet       | Hayır        | İsteğe bağlı¹ | Hesap yönetimi            | aynı                                                |
| **Uygulama etkileşimleri**   | Evet       | Hayır        | İsteğe bağlı² | Analitik, ürün geliştirme | `core/analytics/*` · `api/analytics/collect`        |
| **Çökme günlükleri**         | Evet       | Hayır        | İsteğe bağlı² | Hata ayıklama             | `core/observability/*` · `api/errors/report`        |
| **Satın alma geçmişi**       | Evet       | Hayır        | Zorunlu       | Uygulama işlevi (premium) | `entitlements_repository.dart` · `api/iap/validate` |
| **Diğer kullanıcı içeriği**³ | Evet       | Hayır        | İsteğe bağlı  | Uygulama işlevi (AI Koç)  | `coach_api.dart` · `api/ai/ask`                     |

¹ **Hesap ZORUNLU DEĞİL.** Uygulama misafir olarak tam çalışır; e-posta yalnız hesap açan
kullanıcıdan alınır. Formda "Bu veriler toplanması zorunlu mu?" sorusuna **Hayır** denmeli.

² Analitik ve çökme raporları uygulamanın çalışması için gerekli değildir; kullanıcı hesap açmasa
da toplanır ama **kimliksizdir** (§3).

³ AI Koç'a yazılan soru metni sunucuya gider. Kullanıcı serbest metin yazabildiği için Play bunu
"diğer kullanıcı içeriği" sayar. **Saklanmıyor**: yanıt üretildikten sonra istek gövdesi kalıcı
bir tabloya yazılmaz.

---

## 2. TOPLANMAYANLAR — açıkça

Formda "Hayır" işaretlenecekler ve bunun koddaki kanıtı:

| Kategori                 | Neden hayır                                                                         |
| ------------------------ | ----------------------------------------------------------------------------------- |
| Konum (kaba/hassas)      | Konum izni MANİFESTODA YOK (`AndroidManifest.xml`)                                  |
| Kişiler / rehber         | İzin yok                                                                            |
| Fotoğraf / video         | `image_picker` YALNIZ avatar için ve **kullanıcı seçerse**; cihaz galerisi taranmaz |
| Ses kaydı                | Mikrofon izni yok                                                                   |
| Takvim, SMS, arama kaydı | İzin yok                                                                            |
| Cihaz kimliği (reklam)   | **Reklam kimliği KULLANILMIYOR.** Reklam SDK'sı yok, reklam yok                     |
| Sağlık / fitness         | Yok                                                                                 |
| Finansal bilgi           | Ödeme **tamamen Google Play** üzerinden; uygulama kart bilgisi görmez               |
| Ham IP adresi            | Saklanmıyor — yalnız tuzlanmış SHA-256 (§4)                                         |

---

## 3. Anonim kimlik (`anonId`) — formda ne denecek

Uygulama, oturumsuz kullanımı birbirine bağlamak için cihaz başına rastgele bir dize üretir
(`core/analytics/analytics.dart`).

- **Reklam kimliği DEĞİLDİR** (AAID/GAID okunmuyor).
- Kişiyi tanımlamaz; başka bir veriyle birleştirilerek kimliğe çevrilmez.
- Uygulama silinince kaybolur.

Play formunda ayrı bir "anonim kimlik" kategorisi yoktur; bu değer **"Uygulama etkileşimleri"**
başlığı altında beyan edilen verinin bir alanıdır ve ayrıca "Cihaz veya diğer kimlikler" olarak
işaretlenmesi **gerekmez** — çünkü kalıcı bir cihaz kimliği (IMEI, AAID, Android ID) okunmuyor.

---

## 4. Güvenlik uygulamaları — formdaki sorular

| Soru                                            | Cevap | Dayanak                                                           |
| ----------------------------------------------- | ----- | ----------------------------------------------------------------- |
| Veriler aktarım sırasında şifreleniyor mu?      | Evet  | Tüm uçlar HTTPS (`AppConfig.apiBaseUrl`)                          |
| Kullanıcı verisinin silinmesini isteyebilir mi? | Evet  | Uygulama içi **hesap silme** (`account_api.dart` · `api/account`) |
| Play Aileler politikasına tabi mi?              | Hayır | Hedef kitle 18+ (sürücü belgesi adayları)                         |

**Silme yolu (form bir URL istiyor):** uygulama içinde Profil → Hesabı sil. Web'de aynı işlem
Ayarlar üzerinden yapılabilir. Formda uygulama-içi yol beyan edilmeli; Google ayrıca harici bir
silme talebi URL'si de ister — bu, sahibin sağlaması gereken bir sayfadır (**bkz. §6 açık iş**).

---

## 5. KVKK ile ilişki

Veri güvenliği formu Google'ın istediği bir beyandır; KVKK ise Türkiye'deki yasal yükümlülük.
İkisi ayrı ama **çelişmemeli**. Uygulamadaki KVKK metni `/kvkk`, gizlilik politikası `/gizlilik`
adresinde. Formda gizlilik politikası URL'si olarak **`https://www.ehliyetegitim.com/gizlilik`**
verilecek.

Veri minimizasyonu kararlarının koddaki karşılıkları:

- **Ham IP saklanmıyor**: davet sahteciliği tespiti için yalnız tuzlu SHA-256 tutulur
  (`lib/server/referrals.ts` → `hashIp`). Tuz ortamdan gelir; tuzsuz bir hash IPv4 uzayında kaba
  kuvvetle geri çevrilebilirdi.
- **Analitik boyutlarında kişisel veri yok**: olay sözlüğü yalnız sayı/bayrak/kısa kimlik taşır ve
  bu bir testle korunuyor (`test/analytics_test.dart` → "boyutlar YALNIZ ilkel değer taşır").
- **İstemcinin gönderdiği `userId` yok sayılır**: olay, sunucudaki oturumdan bağlanır
  (`lib/server/telemetry.ts`). Aksi hâlde herkes başkasının kimliğine olay yazabilirdi.

---

## 6. AÇIK İŞLER — yayından önce sahibin yapması gerekenler

| #   | İş                                                                               | Durum |
| --- | -------------------------------------------------------------------------------- | ----- |
| 1   | Play Console → Veri güvenliği formunu bu belgeye göre **doldurmak**              | ❌    |
| 2   | **Hesap silme talebi URL'si** — Google harici bir sayfa ister                    | ❌    |
| 3   | Gizlilik politikasına analitik/çökme raporu bölümü eklemek (form ile tutarlılık) | ❌    |

> Bu üçü tamamlanmadan yayına çıkılamaz. Birincisi ve üçüncüsü birbirini doğrulamak zorundadır:
> formda beyan edilip gizlilik politikasında yazmayan bir toplama, incelemede tutarsızlık olarak
> döner.
