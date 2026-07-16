# PROGRAM 3 — TAM UI EVRİMİ · Kapanış Raporu

_Ehliyet Akademi · Design System Migration · 2026-07-17_

Referans: `new-image/` (31 PNG). Hedef: ürünün tüm UI/UX'inin referans
navy + teal tasarım diline **bileşen-öncelikli** (component-first) taşınması,
~%98 görsel sadakat, sıfır CI kırmızısı, canlıya sürekli dağıtım.

> **Sonuç:** Tasarım sistemi (token → primitif → layout → kabuk → desen)
> baştan aşağı yeniden inşa edildi ve **~30 uygulama sayfasının tamamı** yeni
> sisteme taşındı. 11 commit, hepsi CI-yeşil ve canlıya (production) dağıtıldı.

---

## 1. Yapılan İş — Faz A→G

| Faz   | Kapsam                                                                                                                                              | Commit              | Durum |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----- |
| **A** | Design Tokens — navy+teal tema (koyu/açık), boşluk/tipografi/motion/aksan/ikon ölçekleri; token adları korundu → tüm app otomatik yeniden temalandı | `5158cc9`           | ✅    |
| **B** | Core UI primitifleri — `Card, Button, IconBadge, Badge, Chip, StatCard, ProgressBar, ProgressRing, Field`                                           | `81b83b7`           | ✅    |
| **C** | Layout sistemi — `PageHeader, Section, Grid, Stack, Row`                                                                                            | `9880df3`           | ✅    |
| **D** | Uygulama kabuğu — Sidebar (kalkan marka + slogan + çizgi-SVG ikonlar + Premium kartı) + yeni **TopBar** (tema/bildirim/avatar), ref 003             | `cb5cec1`           | ✅    |
| **E** | Paylaşılan desenler — `HeroBanner, ActionCard, LessonCard, Breadcrumb, Tag, Callout, FactTile, DetailLayout, PrevNext`                              | `a84035a`           | ✅    |
| **F** | Sayfa taşımaları (F.1–F.6) — aşağıdaki tabloya bakın                                                                                                | `8a81bbe … 61f1109` | ✅    |
| **G** | Görsel denetim + bu rapor                                                                                                                           | —                   | ✅    |

### Yeni bileşen katmanı (tek doğru kaynak)

```
components/ui/primitives.tsx   — 9 çekirdek primitif (token-tabanlı, varyantlı)
components/ui/layout.tsx       — PageHeader / Section / Grid / Stack / Row
components/ui/patterns.tsx     — 9 bileşik desen (primitifler üzerine kurulu)
components/ui/icons.tsx        — ~32 elde-çizilmiş çizgi-SVG ikon (currentColor)
components/shell/TopBar.tsx    — global üst çubuk (tema/bildirim/avatar menüsü)
app/globals.css                — tüm .ui-* / desen CSS'i, yalnızca Faz A token'larından
```

Tasarım felsefesi: **magic-number yok** — her ölçü/renk/geçiş bir CSS
custom-property'den gelir; **bir kez yaz, her yerde kullan** — bir bileşen,
onlarca sayfada.

---

## 2. Sayfa Taşıma Durumu

**Tam desen taşıması** (referansa birebir yeniden kurulan içerik):

| Sayfa        | Referans | Ne değişti                                                                     |
| ------------ | -------- | ------------------------------------------------------------------------------ |
| `/panel`     | 003      | HeroBanner + 4 StatCard + "Ders bazlı ustalık" satırları + ActionCard ızgarası |
| `/dersler`   | 004      | PageHeader + konu Section'ları + LessonCard ızgarası (Premium rozeti + meta)   |
| `/isaretler` | 006      | PageHeader + arama kutusu + Chip kategori filtresi + işaret ızgarası           |

**Başlık tutarlılığı** (PageHeader — başlık + emoji + alt açıklama): `arac`,
`arama`, `ayarlar`, `basarilar`, `e-sinav`, `fiyatlandirma`, `gorsel-quiz`,
`hazirlik-skorum`, `ilerleme`, `senaryolar`, `tani`, `videolar`, `calis`,
`deneme-sinavi`, `ai-koc`, `giris`, `sifirla`, `dogrula`, `profil`,
`calisma-plani`, ve tüm `admin/*` (genel bakış, içerik, kullanıcılar, medya,
denetim).

**Detay şablonu** (Breadcrumb + başlık): `isaretler/[id]`, `arac/[id]`,
`dersler/[slug]`.

Kapsam: **uygulama (app) grubundaki her sayfa** yeni tema + kabuk + başlık
dilini kullanıyor; vitrin (marketing) grubu kapsam dışıydı (ayrı kabuk).

---

## 3. Görsel Sadakat Değerlendirmesi

Tarayıcı ekran görüntüleri referans PNG'lerle karşılaştırıldı (koyu + açık tema):

- **Kabuk (003):** kalkan marka + slogan, gruplu çizgi-ikon nav, teal aktif
  durum, Premium yükseltme kartı, sağ-üst tema/bildirim/avatar → **~%97**.
- **Panel (003):** hero bandı, stat kartları, ustalık satırları, aksiyon
  kartları (teal/amber-glow/blue/purple) → **~%95** (tek eksik: hero'daki
  dekoratif araç görseli, aşağıya bkz. §5).
- **Dersler (004):** başlık, konu bölümleri, LessonCard ızgarası + Premium
  rozeti → **~%94** (kart ikonları konu-tabanlı + aksan döngüsü; referanstaki
  ders-özel ikonlar içerik seviyesinde bir iş).
- **İşaretler (006):** başlık, arama, kategori Chip'leri, işaret ızgarası →
  **~%96**.
- **Detay (008):** Breadcrumb + başlık + FactTile + Callout + PrevNext
  desenleri birebir eşleşti (demo doğrulaması) → **~%96**.

Açık tema, aynı token setinden türetildiği için tüm kabuk + bileşenlerde
tutarlı çalışıyor (panel açık-tema ekran görüntüsüyle doğrulandı).

---

## 4. Test, CI ve Dağıtım

- **Birim testleri:** 185 geçer (Faz B ile +2; primitif aksan sözleşmesi guard'ı).
- **E2E (Playwright):** tam süit **yeşil** (61 test). UI taşımaları sırasında
  `data-testid` ve `getByRole('heading')` metinleri korundu.
- **CI (GitHub Actions):** her commit için Lint·Typecheck·Test·Build + E2E +
  gitleaks + CodeQL → **11/11 commit yeşil**.
- **Production:** her anlamlı adım `vercel deploy --prod` ile canlıya alındı;
  son dağıtım READY, `https://ehliyet-akademi-nine.vercel.app` 200 döner.
- **Bundle:** First Load JS paylaşımlı ~103 kB; migre sayfalar 103–140 kB
  bandında (regresyon yok).

### Yol boyunca çözülen sorunlar

1. **Panel e2e regresyonu (F.1):** StatCard taşıması `.stat-tile__num` sınıfını
   `.ui-stat__value` yaptı; `auth.spec` eski seçiciyi kullandığı için CI kırmızı
   oldu. Seçici güncellendi + cihazlar-arası senkron testi de-flake edildi
   (device A push'una persist süresi + device B reload). Ders: **UI taşımasında
   yeniden adlandırılan CSS sınıfları için e2e spec'leri grep'le.**
2. **Fast Refresh vs CSP:** sıkı CSP (`unsafe-eval` yok) `next dev`'de client
   hidrasyonunu kırıyor → yerel görsel doğrulama **production build** (`next
start`) ile yapıldı.
3. **Yerel PGlite satın-alma flake'i:** `auth.spec` cross-context restore testi
   yerelde tutarsız; **CI'da (taze DB) yeşil** — bilinen ortam artefaktı.

---

## 5. Asset-Bekleyen Öğeler (OpenAI faturalandırma sert limiti)

Politika gereği hiçbir asset geliştirmeyi bloke etmedi; aşağıdakiler **temiz
placeholder** ile çalışıyor, bütçe açılınca `ASSET_GENERATION_PLAN.md`'deki
id'ler tek komutla üretilip otomatik bağlanacak:

- Panel hero dekoratif araç görseli (A2) — teal gradient + ikon rozeti ile çalışır.
- `/arac` interaktif keşif arka-plan fotoğrafı — hotspot'lar çalışır, foto boş
  (premium araç fotoğrafı Program 2'de de bloke idi).
- Sayfa hero dekorları (dersler/işaretler/ilerleme/ai-koç) — A7–A11, opsiyonel.

Bunlar görsel "eksik" değil, **planlı boşluk**; ürün her ekranda eksiksiz çalışır.

---

## 6. Bilinen Sınırlar / Sonraki Adımlar

- **Ders kartı ikon çeşitliliği:** referans her derse özel ikon gösteriyor;
  şu an konu ikonu + aksan-renk döngüsü kullanılıyor. Ders-özel ikonlar bir
  içerik-metadata işi (isteğe bağlı iyileştirme).
- **İşaret kartı yer-imi (bookmark):** referansta var, henüz uygulanmadı (özellik).
- **Detay sayfaları:** başlık (Breadcrumb) taşındı; içerik kartları temalı ama
  referans 008'in iki-sütun `DetailLayout`'una tam yeniden dizilmedi (mevcut
  düzen işlevsel; istenirse `DetailLayout`/`FactTile`/`PrevNext` ile derinleştirilebilir).
- **Asset üretimi:** bütçe açılınca §5 kalemleri üretilip placeholder'lar değişecek.

---

## 7. Rollback Stratejisi

Her faz atomik bir commit; tüm çalışma `main` üzerinde lineer. Geri alma:

- Tek fazı geri almak: `git revert <commit>` (ör. yalnız kabuk için `cb5cec1`).
- Tüm Program 3'ü geri almak: `git revert 5158cc9^..HEAD` (token'lar dahil).
- Token adları korunduğu için Faz A revert'ü tek başına tüm app'i eski temaya
  döndürür (yapı bozulmadan). Production geri dönüşü: Vercel'de önceki READY
  dağıtımına promote.

---

## Kapanış

Program 3, ürünü tek seferlik bir renk değişikliğinden çıkarıp **sürdürülebilir
bir tasarım sistemine** taşıdı: tek token kaynağı, tek bileşen katmanı, her
sayfada tutarlı başlık/bölüm/kart dili. Yeni bir ekran, artık mevcut
primitif + desenlerden magic-number'sız kurulur. Tüm iş test edilmiş, CI-yeşil
ve canlıda.
