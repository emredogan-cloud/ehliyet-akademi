# SPRINT 3 TAMAMLAMA RAPORU — İçerik Genişletme & Öğrenme Deneyimi

_Tarih: 2026-07-15 · Tek doğru kaynak: `ROADMAP.md` (v3.1 — DEĞİŞTİRİLMEDİ; Faz 9/10 öğrenme, 11/12 soru bankası, 14 görsel, 22 AI, 35 zekâ)_

> Bu sprint **eğitimsel değere** odaklandı: içerik, öğrenme sistemleri ve pedagojik kalite —
> altyapı değil. Amaç: en kapsamlı Türkçe B sınıfı ehliyet öğrenme deneyimi.

---

## Sonuç: ✅ TAMAMLANDI

| Sprint 3 deliverable                      | Durum                                                                                                    |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Teorik Akademi anlamlı biçimde genişledi  | ✅ 5 → **14 teorik ders** (trafik 8 · ilk yardım 3 · araç tekniği 2 + çekirdek adab); tümü zengin yapıda |
| Sürüş Akademisi anlamlı biçimde genişledi | ✅ **5 direksiyon dersi** (araç hazırlık, debriyaj/rampa, park, kavşak uygulama, sınav stratejisi)       |
| Büyük özgün soru bankası dolduruldu       | ✅ 53 → **198 özgün soru** (3.7×); **82 farklı konu**; zenginleştirilmiş metaveri                        |
| Eğitimsel görsel sistem entegre edildi    | ✅ LessonFigure 4 → **12 erişilebilir SVG** (role=img + aria-label); ders sayfalarına gömülü             |
| AI Koç grounded eğitim rehberliği sunuyor | ✅ zayıf konu, çalışma planı, kişisel tekrar, yanlış-açıklama — **kullanıcının kendi verisinden**        |
| CI yeşil                                  | ✅ 94 unit/integration + 32 e2e + typecheck + build + gitleaks + CodeQL — GitHub Actions **yeşil**       |
| Production deploy doğrulandı              | ✅ canlı + **gerçek tarayıcı** doğrulaması (ders/soru/AI/plan/görsel — aşağıda kanıt)                    |

---

## Epic 1 — Teorik Akademi (14 ders)

Çekirdek 5 ders korunup **zenginleştirildi** (figureId, özet, tekrar kartları, alıştırma) + **9 yeni
derin ders** eklendi. Kapsanan konular: trafik işaretleri, kavşak/geçiş önceliği, **hız & takip mesafesi**,
**sollama & şerit**, **far & gece sürüşü**, **yaya & geçit**, **çevre & ekonomik sürüş**, **yasal
sorumluluklar**, ilk yardım temelleri, **kanama & şok**, **temel yaşam desteği (kalp masajı)**, araç tekniği,
**gösterge ikazları**, trafik adabı.

**Her ders şu yapıyı taşır** (ADR-005 şeması, `LessonInput`):
kazanımlar · rozetli anlatım bölümleri · sık yapılan hatalar + çözüm · **hafıza teknikleri** ·
**sınav stratejisi** · **özet (key takeaways)** · **tekrar kartları (aktif hatırlama, çevrilir)** ·
**alıştırma soruları (anında geri bildirim)** · görsel · SRS entegrasyonu · AI Koç giriş noktası.

## Epic 2 — Sürüş Akademisi (5 direksiyon dersi)

Pratik direksiyon konuları derinlemesine: **araç kontrolü & sürüşe hazırlık** (koltuk/ayna/kemer,
motor çalıştırma), **debriyaj kontrolü & rampada kalkış** (kavrama noktası, geri kaymayı önleme),
**park manevraları** (paralel/geri park, kör nokta), **kavşak & dönel kavşak uygulaması**, **sınav
stratejisi** (hata mantığı: güvenliği tehlikeye atan hareket = ağır/elemeli; kemer/ayna/sinyal atlaması
= puan kaybı; sınav psikolojisi). Sınav puanlaması **mantık olarak** anlatıldı — uydurma resmî puan
tablosu YOK.

## Epic 3 — Soru Bankası (53 → 198 özgün soru)

| Ders         | Önce | Sonra             | e-Sınav gereksinimi |
| ------------ | ---- | ----------------- | ------------------- |
| Trafik       | 23   | **63**            | 23                  |
| İlk Yardım   | 12   | **42**            | 12                  |
| Araç Tekniği | 9    | **39**            | 9                   |
| Trafik Adabı | 6    | **26**            | 6                   |
| Direksiyon   | 3    | **28**            | —                   |
| **Toplam**   | 53   | **198** (82 konu) | 50/sınav            |

**Her soru zenginleştirilmiş metaveri taşır:** açıklama · doğru cevap · **çeldiricilerin neden yanlış
olduğu (whyWrong)** · zorluk · **etiketler (tags)** · konu · **öğrenme kazanımı (objective)** · SRS
metaverisi (kart difficulty). Banka **yükleme anında Zod ile parse edilir** — bozuk içerik build'i kırar.

**Özgünlük & hukuk (ROADMAP C.4/E.6):** tüm sorular kendi ifademizle, resmî MEB/ODSGM müfredatı +
Karayolları mevzuatı + resmî ilk yardım bilgisine dayalı; **hiçbir uygulama/site kopyalanmadı**. Tümü
`review: 'draft'` — yayın öncesi alan uzmanı (özellikle ilk yardım) onayı gerekir.

> **Dürüst kapsam notu:** direktifteki "konu başına 100+ soru" **ölçekleme hedefidir**; Sprint 2'nin
> CMS + içerik hattı + şeması bu ölçeği destekler. Sprint 3, tam metaverili **3.7× özgün genişletme**
> (198 soru / 82 konu) ile bankayı çeşitlilik için sağlam bir tabana taşıdı; 100+/konu, uzman onay
> döngüsüyle sürdürülecek üretim işidir (kalite > ham sayı; özellikle güvenlik-kritik ilk yardım).

## Epic 4 — Görsel Sistem (12 erişilebilir SVG)

`LessonFigure` 4 → **12 tema-uyumlu inline SVG**: işaret grupları, ABC, gösterge, kavşak (mevcut) +
**takip mesafesi (2 sn), sollama, yaya geçidi, kalp masajı (100–120/dk · 5cm · 30:2), araç hazırlık,
rampada kalkış, paralel park, dönel kavşak** (yeni). Hepsi `role="img"` + `aria-label` (erişilebilir),
telifsiz, offline, `figureId` ile derse eşlenir. Ölçekte CMS medya hattı (Sprint 2) admin görselleri için hazır.

## Epic 5 — AI Öğrenme Deneyimi (grounded)

`lib/study.ts` (saf, test edilebilir çekirdek) + AI Koç entegrasyonu:

- **explainWrongAnswer** — yanlış cevabı sorunun açıklaması + whyWrong + ders bağlantısıyla açıklar.
- **weakTopics** — cevap geçmişinden en zayıf konuları çıkarır (ustalık artan sırada).
- **nextStudySuggestion / buildStudyPlan** — uyarlanabilir sıralı plan: vadesi gelen SRS tekrarları →
  en zayıf dersler (ders + alıştırma) → deneme sınavı. Aktif başarısızlık, hiç çalışılmamış dersten önce gelir.
- **personalizedReview** — SRS `selectNext` ile vadesi gelen kartlar + zayıf konu sorularından set üretir.

**Yüzeyler:** AI Koç'a 3 grounded aksiyon (Ne çalışmalıyım / Zayıf konularım / Kişisel tekrar) +
yeni **`/calisma-plani`** sayfası (adımlar + **ders ustalığı radar grafiği**). Tüm çıktılar
kullanıcının KENDİ verisinden türetilir; her mesaj "resmî kural için MEB/MTSK esastır" uyarısı taşır.
Gerçek model adaptörü hâlâ ENV ile takılabilir (grounding + Faz 22 korunur).

## UI & UX

Ders sayfası zenginleştirildi (özet/hafıza/strateji kartları, **çevrilir tekrar kartları**, **anında
geri bildirimli alıştırma**, AI giriş noktası). Dersler dizini ** derse göre gruplandı**. Yeni
görselleştirme: **ustalık radarı**. Yeni CSS: plan adımları, flip-card 3D animasyon, alıştırma
seçenek durumları, `prefers-reduced-motion` desteği (erişilebilirlik).

## Şema (geriye dönük uyumlu)

`@ea/content-schema`: `Question` + `whyWrong`/`objective`/`tags`; `Lesson` + `memoryTips`/`examStrategy`/
`keyTakeaways`/`reviewCards`/`practiceQuestionIds`/`figureId` + `ReviewCard`. Yazım tipleri `QuestionInput`/
`LessonInput` (`z.input`) — mevcut 53 soru + 5 ders değişmeden geçerli kaldı; banka/dersler yüklemede parse edilir.

## Test Kanıtı

- **94 unit/integration** (web 59 + paket 35: content-schema 9 · srs 12 · question-bank 10 · db 4).
  Yeni: `lib/study.test.ts` (11 test — zayıf konu, adaptif plan, kişisel tekrar, yanlış-açıklama,
  biçimlendiriciler); soru bankası +2 gate (≥150 soru & dağılım derinliği; ≥140 zenginleştirilmiş metaveri).
- **32 e2e** (6 spec; +4 Sprint 3): zengin ders (görsel + özet + tekrar kartı çevir + alıştırma geri
  bildirimi) · Sürüş Akademisi dersi görselle · çalışma planı (adımlar + ustalık radar) · AI Koç kişisel
  rehberlik grounded. Hepsi **production build** üzerinde, CI'da yeşil.
- typecheck (9 paket) · production build (23 sayfa) · gitleaks · **CodeQL** — yeşil.

## Production Canlı Doğrulama (gerçek tarayıcı, 2026-07-15)

| Yüzey                              | Kanıt                                                                                                            |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Zengin ders (`/dersler/hiz-takip`) | ✅ Takip-mesafesi SVG + kazanımlar + rozetli bölümler (50/90/110/120) + özet + hafıza/strateji + tekrar kartları |
| Alıştırma geri bildirimi           | ✅ "110" seçildi → **✅ Doğru** + açıklama + çeldirici notları (90/120 neden yanlış) — canlı grounded            |
| Çalışma planı (`/calisma-plani`)   | ✅ Grounded odak özeti + **ders ustalığı radar** SVG + uyarlanabilir adımlar (Ders→Alıştırma→Deneme)             |
| AI Koç kişisel rehberlik           | ✅ "Ne çalışmalıyım?" → 5 adımlı grounded plan (kendi verisinden) + MEB/MTSK uyarısı                             |
| Kabuk & konsol                     | ✅ Tüm sayfalar kalıcı sol sidebar SaaS kabuğunda ("Çalışma Planım" eklendi); konsol 0 hata                      |

## Kalan İş (ROADMAP sırası — Sprint 4 BAŞLATILMADI)

İçerik: 100+/konu hedefine uzman onay döngüsüyle devam (hat + şema hazır) · ilk yardım içeriği uzman
onayı · gerçek AI model adaptörü (Faz 22) · gerçek tahsilat adaptörü · Faz 30 güvenlik sertleştirme ·
Faz 31 gözlemlenebilirlik. **Sprint 3 sonrası durduruldu — direktif gereği Sprint 4 başlatılmadı.**
