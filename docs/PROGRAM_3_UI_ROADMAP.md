# PROGRAM 3 — UI EVRİMİ / Design System Migration Roadmap

_Ehliyet Akademi · 2026-07-16 · **Onay bekliyor** — uygulama, bu roadmap onaylandıktan sonra başlar._

> Referans tasarımlar: `new-image/` (31 PNG). Bunlar **tek doğru referanstır**; hedef **%98+
> görsel doğruluk**. Bu bir renk değişimi değil, tam bir **Design System Migration**'dır.
> Kural: mimari bozulmaz, mevcut sistemler (auth/CMS/AI/ödeme/içerik) korunur; yalnızca sunum
> katmanı (UI/UX/tokens/components/spacing/typography/motion) yenilenir.

---

## 1. Current UI Analysis

**Tema:** yeşil-tonlu koyu tema. `apps/web/app/globals.css` (2098 satır, ~274 sınıf) merkezi
tokenları tutar:

- Renkler (dark): `--bg:#071614` (yeşilimsi koyu), `--surface:#0e2320`, `--primary:#2dd4bf`,
  border `#1d3f39`; light tema de var. Aksan renkleri dağınık (`--accent/--red/--yellow/--blue`).
- Radius: `--radius:16px`, `--radius-sm:10px`. Gölge: `--shadow-1/2`. Font: Segoe UI stack.
- **Eksikler:** `blur`, `motion-duration`, `opacity`, `icon-size`, `font-scale` tokenları YOK
  (magic number'lar bileşenlere gömülü). Aksan renkleri (amber/purple/blue kartlar) token değil.

**Kabuk:** `components/Sidebar.tsx` — gruplu nav (Öğren/Pratik/İlerleme/Hesap), teal aktif durum,
mobil çekmece; `.appbar` üst bar (marka + streak). `.shell` grid (264px + 1fr).

**Mevcut bileşenler (29):** Sidebar, Dashboard, Callout, CompareTable, EmptyState, AssetImage,
LessonPhotos, Reveal, MasteryRadar, StudyHeatmap, NudgeBanner, Practice, ExamSimulator,
AICoach, Diagnostic, Pricing, PremiumBadge, PurchaseDialog, LessonFigure, LessonPractice,
components/media/_, components/scenario/_, components/anim/_, components/signs/_,
components/vehicle/*.

**Sayfalar (~37):** (marketing) landing + legal; (app) panel, dersler(+[slug]), isaretler(+[id]),
arac(+[id]), videolar, e-sinav, gorsel-quiz, senaryolar, deneme-sinavi, tani, calis, ai-koc,
ilerleme, hazirlik-skorum, calisma-plani, basarilar, arama, fiyatlandirma, giris, profil,
ayarlar, dogrula, sifirla, admin/*.

**Değerlendirme:** yapı (sidebar + kart + progress + teal) yeni tasarıma yakın; fark **görsel
rafine**: navy tema, glassmorphism/glow, aksan-renkli kartlar, header (arama+bildirim+avatar),
zengin ikon dili, daha yumuşak spacing/typography.

---

## 2. New UI Analysis

`new-image/` referanslarından çıkarılan tasarım dili:

- **Tema:** koyu **lacivert/charcoal** (`~#0a0e17` bg, `~#0e1626`/`~#131c2e` yüzeyler), parlak
  **teal** birincil (`~#2dd4bf`→`~#14b8a6` gradient). Kart-başına **aksan renkleri**: teal,
  amber/turuncu, mavi, mor, kırmızı, yeşil.
- **Kabuk:** ~285px sidebar; **kalkan logo** + "Güvenli sürüş, aydınlık gelecek." sloganı; gruplu
  nav, aktif öğe **teal-tint yuvarlak pill**; altta **"Premium'a geç" kart** (taç). Üstte **arama
  çubuğu (⌘K)** + **bildirim zili** + **avatar dropdown (EA)**.
- **Kartlar:** ~16–20px radius, ince border, koyu yüzey, bazıları **renkli glow/gradient border**;
  içerik: renkli **daire ikon** + başlık + açıklama + meta/CTA.
- **Hero banner'lar:** cam efektli, glow'lu araç/şehir görselleri + teal ışık izleri.
- **Progress:** teal gradient, yuvarlak; **stat kartları** (halka/ikon + büyük sayı + etiket + chevron).
- **Detay şablonu (008):** breadcrumb + başlık + kategori pill + iki kolon (carousel + özet kart +
  mini bilgi tile'ları + amber "Önemli" callout + "Bankadan sorular" satırları) + önceki/sonraki.
- **Typography:** kalın büyük başlıklar, orta gövde; ikonlar renkli/emoji-benzeri; bol nefes alanı.
- **Motion:** hover-lift, fade/reveal, progress fill, kart glow, sidebar geçişi, skeleton.

---

## 3. Page Mapping (referans PNG → route)

| Referans PNG         | Route / dosya                                                                    | Not                                               |
| -------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------- |
| 001, 002             | `(marketing)/page.tsx` `/`                                                       | Landing (hero + scroll)                           |
| 003                  | `(app)/panel`                                                                    | App shell + dashboard (kabuk kaynağı)             |
| 004, 005             | `(app)/dersler`                                                                  | Ders listesi (konu grupları + ders kartı)         |
| 006, 007             | `(app)/isaretler`                                                                | İşaret galerisi (filtre + grid)                   |
| 008                  | `(app)/isaretler/[id]` **+** `(app)/arac/[id]`                                   | Genel **detay şablonu** (hem işaret hem bileşen)  |
| 009                  | `(app)/gorsel-quiz`                                                              | Görsel quiz                                       |
| 010                  | `(app)/e-sinav`                                                                  | Teorik e-Sınav bilgi sayfası                      |
| 011                  | `(app)/tani`                                                                     | Tanı denemesi                                     |
| 012                  | `(app)/calis`                                                                    | Akıllı çalışma (SRS)                              |
| 013, 014             | `(app)/senaryolar`                                                               | Senaryo listesi + koşucu                          |
| 015, 016, 018, 019   | `(app)/deneme-sinavi`                                                            | Sınav: giriş / soru anı / fail / win durumları    |
| 020                  | `(app)/ai-koc`                                                                   | AI Koç sohbet + robot avatar                      |
| 021, 022             | `(app)/ilerleme`                                                                 | İlerleme (XP) panosu                              |
| 023, 024             | `(app)/calisma-plani`                                                            | Çalışma planı                                     |
| 025                  | `(app)/basarilar`                                                                | Başarılar/rozetler                                |
| 026                  | `(app)/arama`                                                                    | Arama                                             |
| 027                  | `(app)/giris`                                                                    | Giriş/kayıt (auth form)                           |
| 028                  | `(app)/fiyatlandirma`                                                            | Premium (referans "güncellenecek" notlu)          |
| 029                  | `(app)/ayarlar`                                                                  | Ayarlar (tüm özellikler uygulanacak)              |
| 030, 031             | `(app)/dersler/[slug]`                                                           | Ders detay + şablon                               |
| —                    | `(app)/hazirlik-skorum`, `/videolar`, `/profil`, `/dogrula`, `/sifirla`, admin/* | Referans YOK → tasarım dilini uygula (türetilmiş) |
| generated_openaı.png | —                                                                                | Örnek üretilmiş asset (referans değil)            |

---

## 4. Component Mapping (Old → New)

| Old                             | New                                                     | Değişim                                                        |
| ------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------- |
| `.shell` + `Sidebar`            | `AppShell` + `Sidebar` (yeniden stillendirilir)         | Kalkan logo+slogan, teal aktif pill, Premium kartı, gruplar    |
| `.appbar` (üst bar)             | `TopBar` (yeni)                                         | Arama (⌘K) + bildirim zili + avatar dropdown                   |
| `.card`                         | `Card` (variant: `plain`/`accent`/`glow`)               | Radius/border/glow token'lı; aksan varyantları                 |
| `.btn` / `.btn--ghost`          | `Button` (`primary` teal-gradient / `ghost` / `accent`) | Gradient + hover/motion token'lı                               |
| İç içe stat div'leri            | `StatCard`                                              | İkon/halka + büyük sayı + etiket + chevron                     |
| Feature/aksiyon kartları        | `ActionCard` (accent prop)                              | teal/amber/blue/purple glow                                    |
| Ders kartları (dersler)         | `LessonCard`                                            | Daire ikon + meta footer + bookmark + Premium badge            |
| Progress bar'lar                | `ProgressBar` / `ProgressRing`                          | Teal gradient, token'lı                                        |
| `Callout`                       | `Callout` (restyle)                                     | Amber "Önemli" / info / danger tonları referansa göre          |
| İşaret/araç detay sayfaları     | `DetailTemplate` (008)                                  | Breadcrumb + carousel + info tile + soru satırları + prev/next |
| `EmptyState` / skeleton         | restyle                                                 | Yeni tema                                                      |
| `TrafficSign` / `VehicleFigure` | korunur (içerik)                                        | Yalnız çerçeve/kart sunumu yenilenir                           |
| Sohbet (`AICoach`)              | `ChatShell` restyle                                     | Robot avatar + baloncuklar + öneri çipleri                     |
| Sınav (`ExamSimulator`)         | restyle                                                 | Soru kartı, soru haritası, timer, sonuç (win/fail) ekranları   |

**Design tokens (merkezi, magic-number YOK):** `--c-*` renkler (bg/surface katmanları, teal
skalası, accent-amber/blue/purple/red/green), `--space-*` (4/8/12/16/20/24/32…), `--radius-*`,
`--shadow-*`, `--blur-*`, `--motion-fast/base/slow`, `--ease-*`, `--opacity-*`, `--fs-*` (font
skalası), `--icon-*` (ikon boyutları). Dark **ve** light için tanımlanır (referans dark; light
türetilir, tutarlı).

---

## 5. Asset List (eksik assetler)

Yeni tasarım bazı ekranlarda zengin görsel ister. Detaylar: `ASSET_GENERATION_PLAN.md`.

> **OpenAI ASLA geliştirmeyi bloke etmez (kural).** Her görsel ihtiyacında sıra:
> **(1)** asset zaten varsa → kullan · **(2)** eşdeğer mevcut asset varsa → yeniden kullan ·
> **(3)** yoksa → **temiz placeholder** (SVG/gradient/skeleton) kullan ve geliştirmeye devam et ·
> **(4)** OpenAI sonradan uygun olursa → placeholder'ları üretilen asset'lerle değiştir.
> Program 2 Faz 7'de faturalandırma sert limiti aşılmıştı; bu iş akışı sayesinde uygulama
> bundan bağımsız ilerler. Tüm assetler `ASSET_GENERATION_PLAN.md`'de üretim-hazır prompt'larla
> planlıdır; hiçbir ekran asset yüzünden yarım kalmaz.

İhtiyaç duyulan yeni assetler (detay plan dosyada):

- Landing hero fotogerçekçi yol sahnesi (glow'lu; mevcut `HeroArt` SVG geçici).
- Panel hero banner araç görseli (glow + kalkan).
- Dersler/işaretler başlık dekoratif illüstrasyonu (şehir/yol silüeti).
- AI Koç robot avatar (mor gradient).
- Ders/özellik **daire ikon** seti (renkli, kategori-başına).
- Şablon detay sayfası carousel görselleri (mevcut premium fotoğraflar kullanılabilir).

---

## 6. Implementation Order — **COMPONENT-FIRST**

Paylaşılan design system **önce** tamamlanır; sayfalar sonra o sisteme geçer. Bu, çift işi
önler ve her ekranda tutarlılığı garanti eder.

**Design Tokens → Core UI Components → Layout System → Application Shell → Shared Patterns →
Individual Pages → Final Polish**

- **Faz A — Design Tokens:** globals.css yeniden yapılandırma (geriye dönük uyumlu alias'larla);
  merkezi renk/space/radius/shadow/blur/motion/opacity/font-scale/icon tokenları. Magic-number YOK.
- **Faz B — Core UI Components:** `components/ui/` primitive katmanı — `Card`, `Button`, `StatCard`,
  `ProgressBar`/`ProgressRing`, `Badge`, `Chip`, `IconBadge`, `Field/Input`, `Callout` (restyle).
  Her biri varyant + token temelli; bir kez yazılır, her yerde kullanılır.
- **Faz C — Layout System:** grid/spacing yardımcıları, sayfa `PageHeader`, iki-kolon/kart-ızgara
  düzenleri, responsive kırılım yardımcıları.
- **Faz D — Application Shell:** `AppShell` + `Sidebar` + `TopBar` (003 referansı) → tüm app
  sayfalarını etkiler; ayrı commit + tam e2e + tarayıcı doğrulaması.
- **Faz E — Shared Patterns:** `DetailTemplate` (008), `LessonCard`, `ActionCard`, `HeroBanner`,
  gallery grid + filtre çipleri, sınav/sohbet kabukları, empty/loading/skeleton.
- **Faz F — Individual Pages:** primitifler + kalıplarla her sayfa (referans PNG'siyle doğrulanır):
  Landing(001/002) · Panel(003) · Öğren [dersler 004/005, dersler/[slug] 030/031, isaretler
  006/007, detay şablonu 008 → isaretler/[id]+arac/[id], arac, videolar] · Pratik [calis 012,
  gorsel-quiz 009, senaryolar 013/014, deneme-sinavi 015/016/018/019, tani 011, e-sinav 010,
  ai-koc 020] · İlerleme [ilerleme 021/022, calisma-plani 023/024, basarilar 025, hazirlik-skorum,
  arama 026] · Hesap [giris 027, fiyatlandirma 028, ayarlar 029, profil, admin türetilmiş].
- **Faz G — Final Polish:** global görsel denetim (eski component/renk/spacing/ikon/typography/motion
  kalıntısı taraması) + `PROGRAM_3_UI_REPORT.md`.

Her ekran sonunda: build + tarayıcı doğrulaması + responsive + erişilebilirlik + production deploy +
CI doğrulaması. Her faz sonunda CI (lint/typecheck/test/build/e2e/CodeQL) yeşil.

---

## 7. QA Strategy

- **Birim/e2e:** mevcut testler yeşil kalmalı; `data-testid`'ler korunur (UI değişse de seçiciler
  bozulmaz). Yeni bileşenlere token/varyant birim testleri; kritik ekranlara e2e görünürlük testi.
- **Regresyon:** her faz push'unda tam suite; kırmızı → anında düzelt.
- **Erişilebilirlik:** kontrast (WCAG AA), focus-visible, ARIA, `prefers-reduced-motion`,
  klavye navigasyonu her ekranda.

---

## 8. Pixel Accuracy Strategy

Her ekran için döngü: (1) referans PNG'yi incele + renk/spacing/radius/typography ölç →
(2) uygula → (3) gerçek tarayıcıda aç → (4) referansla **yan yana** karşılaştır → (5) fark listele
(typography, spacing, radius, ikon boyutu, padding/margin, shadow/blur/opacity, kart/sidebar/
buton/progress/form, arka plan, animasyon) → (6) düzelt → tekrar. **%98+** elde edilene dek sürer.
Ölçüm: PNG'den doğrudan renk örnekleme (globals.css token değerleri buradan sabitlenir), 8px
spacing ızgarası, referans başlık/gövde ölçekleri.

---

## 9. Browser Validation Strategy

Her ekran tamam olunca gerçek Chrome ile: masaüstü + laptop + tablet + mobil genişlikler; kontrol:
0 konsol hatası, 0 kritik network hatası (self-host, 3P yok), erişilebilirlik (focus/kontrast),
dark **ve** light tema, hover/motion/transition, responsive kırılımlar. Referans PNG ile
görsel karşılaştırma ekran görüntüsüyle belgelenir.

---

## 10. Rollback Strategy

- **Git:** her faz ayrı commit(ler); sorun → `git revert <sha>` ile tek fazlık geri alma.
- **Token-katmanlı geçiş:** yeni tokenlar eski isimlerle **alias**'lanır; bir bileşen bozulursa
  eski değere düşürmek tek satır.
- **Bileşen-bazlı:** her yeni primitive eskisinin yanında tanıtılır; sayfa-sayfa geçiş, "büyük
  patlama" yok. Herhangi bir sayfa yeni bileşene geçmeden çalışmaya devam eder.
- **CI kapısı:** yeşil olmayan faz production'a gitmez; production her zaman son yeşil commit'te.
- **Feature-flag gerekmez** (görsel-only); ama kabuk (Faz B) riskli olduğundan ayrı commit +
  tam e2e + tarayıcı doğrulaması sonrası merge.

---

## Onay

Bu roadmap onaylandığında **Faz A (Design System temeli)** ile başlanacaktır. Asset üretimi
`ASSET_GENERATION_PLAN.md`'ye göre (bütçe açıldığında) yapılacak; o ana dek UI, SVG/mevcut
varlıklarla eksiksiz çalışır. Hiçbir eksik "tamamlandı" olarak işaretlenmeyecek; kod kalitesi ve
görsel doğruluk birlikte korunacaktır.
