# Mobile Evolution — Final Report (E1 → E13)

**Program:** Ehliyet Akademi mobil evrim programı · 13 faz · _Kapanış: 2026-07-26_
**Cihaz:** `AYXSUKIVJVPZ7HPZ` — Redmi M1908C3JGG · Android 11 · 1080×2340
**Depo:** `emredogan-cloud/ehliyet-akademi` · `main`

## Verdict: 🟢 GO (belirtilen sınırlarla)

Program 13 fazın tamamını bitirdi. Her faz kendi raporunu, testlerini ve cihaz doğrulamasını
üretti; her faz yeşil CI ile kapandı.

---

## 1. Tamamlanan iş — faz faz

| Faz     | Konu                                | Öne çıkan çıktı                                                    |
| ------- | ----------------------------------- | ------------------------------------------------------------------ |
| **E1**  | Resmî trafik işareti vektörleri     | Yordamsal çizimler yerine gerçek levha vektörleri                  |
| **E2**  | Mekanik görsel kütüphanesi          | 101 gerçek fotoğraf + fotoğraf öncelikli araç sayfaları            |
| **E3**  | Gösterge paneli ikaz ışıkları       | 60 ikon + içerik                                                   |
| **E4**  | Çoklu ehliyet temeli                | B · A · D sınıfları                                                |
| **E5**  | A/D müfredatı + sınıf kapsamı       | 10 ders (moto + otobüs), sınıfa göre işaret ağırlığı               |
| **E6**  | Onboarding zekâsı                   | Koç kartı, dönen içgörüler, kaydırmasız uyarlanır yerleşim         |
| **E7**  | Karşılama anı                       | Tek seferlik karşılama + sıralı yönlendirme zinciri                |
| **E8**  | Topluluk temeli                     | Profil · XP · sıralama · **gizlilik ve moderasyon ilk günden**     |
| **E9**  | Sosyal katman                       | Arkadaşlık · mesajlaşma · tartışma · **referansla soru paylaşımı** |
| **E10** | Çalışma grupları & meydan okumalar  | Kodla katılma · tavanlar · türetilen ilerleme · haftalık devir     |
| **E11** | Premium video oynatıcı              | Özel denetimler · altyazı · yer imi · kaldığın yerden devam        |
| **E12** | Video içerik üretimi                | Manevra seti (4) + 3 yükseltme → **7 oynatılabilir video**         |
| **E13** | Cila, varlık optimizasyonu, kapanış | Tema hatası düzeltildi · a11y · **%60 indirme küçülmesi** ölçüldü  |

## 2. Mimari — korunanlar ve eklenenler

**Program boyunca DEĞİŞMEDİ:** Riverpod + go_router + dio + drift · arayüz/uygulama ayrımı ·
tek kaynaklı tasarım token'ları → `ThemeData` · `@ea/db` çift sürücü (PGlite/Postgres) ·
`guarded`/`json`/`checkRateLimit` sunucu yardımcıları · Bearer oturum. **Yeni paket eklenmedi.**

**Eklenen kalıcı desenler:**

1. **Arayüz + sahte uygulama, platforma bağlı her şey için.** `CommunityApi`, `SocialApi`,
   `GroupsApi` ve E11'de `PlaybackController`. Sonuç: video denetimlerinin tamamı bile platform
   kanalı olmadan test edilebiliyor.
2. **Saf kural katmanı, ekrandan ayrı.** `lib/server/*.ts` (anti-hile, engelleme, tavanlar,
   devir) ve `lib/domain/video/*` (VTT, devam, bölüm). Hepsi doğrudan test ediliyor.
3. **Engelleme tek modülde** (`social-guards.ts`) → "her yolda uygulanıyor mu?" sorusu
   denetlenebilir.
4. **Türetilen içerik tek kaynaktan** (E12): video, bölüm ve altyazı aynı nesneden üretiliyor.
5. **Dürüstlük testle zorunlu** (E12/E13): etiketler, gerekçeler ve tasarım token'ları testle
   korunuyor.

## 3. İçerik

| Kapsam                | Sayı                                       |
| --------------------- | ------------------------------------------ |
| Dersler               | 19 (B) + 5 (A) + 5 (D)                     |
| Trafik işaretleri     | 121                                        |
| Araç tekniği bileşeni | 70                                         |
| İkaz ışıkları         | 60                                         |
| Kabin kumandaları     | 39                                         |
| Soru bankası          | 1534                                       |
| **Video**             | **7 oynatılabilir** + 2 dürüstçe `planned` |

## 4. Topluluk mimarisi (E8–E10)

- **Katılım opt-in, varsayılan KAPALI.** Katılmayan kullanıcının hiçbir verisi paylaşılmaz.
- **PII yok:** e-posta/gerçek ad/konum ne modelde ne yanıtta var. Avatar = uygulama maskotu;
  **fotoğraf yükleme yok** → bütün bir moderasyon sınıfı baştan kapatıldı.
- **Engelleme çift yönlü ve sızıntısız:** engelli/yok/gizli hedef **aynı 404**.
- **Mesajlaşma yalnız arkadaşlar arasında** → rastgele kullanıcıya mesaj yüzeyi hiç yok.
- **Soru paylaşımı referansla:** sunucu soru metnini asla taşımaz; kanıtlandı — `trafik-101`
  taşıyan başlığın tam sunucu gövdesinde soru kökü **0 kez** geçiyor.
- **Anti-hile sunucuda** ve meydan okumalara **otomatik yayılıyor**: 999.999.999 XP → 2000'e
  kırpıldı; arka arkaya bildirimle meydan okuma ilerlemesi **sıfır kaldı**.
- **Sınırsız büyüme yolu yok:** 3 grup kurma / 10 katılma / 50 üye tavanı sunucuda.

Canlı doğrulama: **71/71** kontrol, üretim sunucusunda, iki gerçek hesapla.

## 5. Video deneyimi (E11–E12)

**Kütüphane kararı ölçümle verildi** (pub.dev verisi): chewie kendi görsel dilini getiriyor +
belgelenmiş arabellek hatası; `better_player_plus` 168 beğeni ve "kırıcı değişiklik" uyarısı;
`media_kit` libmpv gömüyor. **Karar: `video_player` + kendi denetim katmanımız.**

Özellikler: bölüm işaretli sürüklenebilir zaman çizgisi (arabellek + yer imi işaretleri) ·
altyazı (VTT ağdan çekilip çözümleniyor) · hız · 10 sn atlama · tam ekran + yönelim ·
bölüm listesi · yer imleri · kaldığın yerden devam · "izlendi" durumu.

Üretim hattı: 840×480@12fps → **1120×640@30fps**, adım etiketleri videoya gömülü, bölüm/altyazı
sahneyle tek kaynaktan.

## 6. Test ve CI

| Kapsam            | Program başı | Program sonu |
| ----------------- | -----------: | -----------: |
| `flutter test`    |          ~85 |      **267** |
| web `test`        |         ~330 |      **484** |
| `@ea/db`          |            4 |        **6** |
| `flutter analyze` |            0 |        **0** |

CI kapıları: `CI` (verify · lint · format · typecheck · test · build · **gitleaks**) ·
`Mobile CI` · `CodeQL` · Playwright E2E. Program boyunca **her faz yeşil CI ile kapandı.**

## 7. Cihaz doğrulaması

Her faz gerçek cihazda sürüldü ve ekran görüntüsüyle kanıtlandı. Öne çıkanlar:

- **E9:** iki gerçek hesapla arkadaşlık → kabul → mesaj → şikâyet → engelle (**sıralamadan düştü,
  sıralar yeniden hesaplandı**) → engel kaldır (**erişim geri geldi**).
- **E11:** 15 maddelik denetim doğrulaması; tam ekranda **konum ve hız korunuyor**.
- **E12:** yeni katalog, oynatma, gömülü adım etiketi, premium kapısı.
- **E13:** açık tema paritesi; soğuk açılış **451 ms**.

## 8. Ölçülen boyut ve başarım

| Ölçüt                                | Değer                                  |
| ------------------------------------ | -------------------------------------- |
| Evrensel release APK                 | 69,9 MB                                |
| **arm64-v8a APK (gerçek kullanıcı)** | **27,9 MB**                            |
| AAB (Play artefaktı)                 | 57,3 MB → Play böler, ~28 MB indirilir |
| APK içinde yerel kütüphaneler        | 63,2 MB (%90) — üç ABI yan yana        |
| Uygulama varlıkları                  | 4,2 MB (%6)                            |
| Mobil varlıklar                      | 4,7 MB · 263 dosya · tamamı WebP/SVG   |
| Yayınlanan web varlıkları            | 20 MB → **17 MB**                      |
| Soğuk açılış                         | **451 ms**                             |

## 9. Dürüstçe kalan sınırlar

**Altyapıya bağlı (uydurulmadı):**

1. **Gerçek zamanlı yok.** Vercel sunucusuzda kalıcı WebSocket yok; sohbet/tartışma kısa
   yoklamayla tazeleniyor. "Canlı" iddia edilmiyor.
2. **Push bildirimi yok.** FCM sağlanmadı; hatırlatmalar cihazda yerel planlanıyor.
3. **iOS derlemesi N/A** — macOS yok. `ios/` yapılandırması geçerli tutuldu, sahte iOS derlemesi
   yapılmadı.
4. **Gerçek Play içi satın alma** yalnız Play'den yüklenmiş sürümde çalışır.
5. **Haftalık devir tembel:** cron sağlanmadığı için hafta döndükten sonraki ilk okumada alınır.
6. **Meydan okumalar otomatik dönmez**, yönetici arayüzü yok.

**Kapsam kararı (bilinçli):**

7. **PiP yapılmadı** — Flutter'da bütün görünümü küçültür, istenen deneyim değil.
8. **Çevrimdışı video indirme yok** — ağdan akıtma + platform önbelleği var.
9. **Video sesi yok**; anlatım altyazı ve adım etiketiyle.
10. **İki video `planned`** — gerçek çekim gerektiriyor (sınav yürüyüşü, araç kontrolü).
11. **Moderasyon reaktif** — otomatik metin filtresi yok, arayüz bunu açıkça yazıyor.
12. **Golden test yok**; görsel doğrulama cihaz ekran görüntüleriyle.

**Ölçülemeyen:**

13. **Kare düzeyinde jank ölçülemedi** — `gfxinfo` Flutter'ı görmüyor, `SurfaceFlinger --latency`
    sıfır döndü. Uydurma sayı raporlanmadı.

**Yayın öncesi yapılacak:**

14. **Üretim veritabanındaki doğrulama artıkları temizlenmeli** (`AyseE9`, `BurakE9`, `CemE9`,
    `E8 Dogrulama`, `Cihaz Dogrulama Ekibi`). Bunlar gerçek kullanıcı gelmeden silinmeli —
    geri alınamaz bir üretim işlemi olduğu için onay bekliyor.
15. **LemonSqueezy ürün görseli** mağaza paneline elle yüklenmeli.

## 10. Program boyunca öğrenilen üç ders

1. **CI yeşil olması üretimin ayakta olduğu anlamına gelmiyor.** E10'da bir SQL yorumundaki
   noktalı virgül üretimi ~65 dakika düşürdü; bütün test paketi yeşildi çünkü testler PGlite
   kullanıyordu ve o yol bölme mantığını hiç çalıştırmıyordu. **Çift sürücülü kodda sürücüye
   özgü her yol doğrudan test edilmeli; şemaya dokunan her yayından sonra canlı uç çağrılmalı.**
2. **Cihaz, testin göremediğini gösteriyor.** Taşan yerleşimler, rozetle çakışan etiket,
   "tam ekran"da kalan sekme çubuğu, yanlış temadaki altın — hiçbiri testte görünmedi.
3. **Dürüstlük testle korunabilir.** Etiketlerin ("(Animasyon)"), gerekçelerin ve tasarım
   token'larının doğruluğu artık insan dikkatine değil, teste bağlı.

## 11. Launch readiness

| Alan                      | Durum                                               |
| ------------------------- | --------------------------------------------------- |
| Android release artefaktı | ✅ APK · split-APK ×3 · **AAB** üretildi            |
| CI / CodeQL / gitleaks    | ✅ yeşil                                            |
| Gizlilik & moderasyon     | ✅ opt-in, PII yok, engelle/şikâyet, sızıntısız 404 |
| İçerik dürüstlüğü         | ✅ testle zorunlu                                   |
| Erişilebilirlik           | ✅ 26/26 düğme etiketli, Semantics mevcut           |
| Açık/koyu tema            | ✅ parite doğrulandı, token testi koruyor           |
| iOS                       | ⛔ N/A (macOS yok)                                  |
| Push / gerçek zamanlı     | ⛔ altyapı sağlanmadı — dürüstçe belgelendi         |
| Üretim veri temizliği     | ⚠️ **yapılacak** (§9.14)                            |

**Sonuç:** Android tarafında yayına hazır; §9.14'teki üretim temizliği ve §9.15'teki mağaza
görseli yüklemesi yayından önce tamamlanmalı. Eksik bırakılan her şey bu raporda ve
`MOBILE_PROJECT_MEMORY.md`'de nedeniyle birlikte kayıtlı — hiçbiri sahte bir "tamamlandı" ile
kapatılmadı.
