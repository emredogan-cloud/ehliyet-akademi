# SPRINT 2 TAMAMLAMA RAPORU — CMS, Admin & İçerik Hattı

_Tarih: 2026-07-15 · Tek doğru kaynak: `ROADMAP.md` (v3.1 — DEĞİŞTİRİLMEDİ; Faz 24 CMS / 25 Admin / 28 Arama / 14 Medya)_

> **Bu sprintin amacı içerik altyapısıdır — şimdi yüzlerce soru eklemek değil.** Platform
> binlerce içerik kalemine ölçeklenebilmeli: yönetişimli üretim, sürüm, denetim, RBAC, arama.

---

## Sonuç: ✅ TAMAMLANDI (tek kalan dış aksiyon: production DATABASE_URL — Sprint 1 ile aynı)

| Sprint 2 kriteri                  | Durum                                                                                                          |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| CMS temeli (üretime hazır)        | ✅ Şema-öncelikli özel çekirdek (ADR-007); içerik/sürüm/medya/denetim tabloları; JSONB payload + Zod doğrulama |
| İçerik hattı (yaşam döngüsü)      | ✅ taslak → uzman incelemesi → onay → yayın → emeklilik; her geçiş sunucuda zorlanır + sürüm + denetim üretir  |
| Admin panosu (aynı SaaS kabuğu)   | ✅ /admin (genel bakış · içerik · medya · kullanıcılar · denetim) — kalıcı sol sidebar kabuğunda               |
| Medya kütüphanesi                 | ✅ svg/png/jpeg/webp/lottie yükleme + halka açık servis + meta + versiyon; 2MB sınır; adaptör kapısı (Blob/S3) |
| Arama soyutlaması (takılabilir)   | ✅ `SearchProvider` arayüzü + `LocalSearchProvider`; Meilisearch/Typesense/Algolia yeniden-yazımsız takılır    |
| RBAC (rol/izin/denetim)           | ✅ user/editor/admin; sunucu-taraflı `requireRole`; kendi adminliğini düşürme kilidi; tam denetim kaydı        |
| Kalite kapıları / CI yeşil        | ✅ 81 unit/integration + 28 e2e (production build) + lint/type/build; GitHub Actions **yeşil**                 |
| Deploy (preview + production)     | ✅ `vercel deploy --prod --yes` → https://ehliyet-akademi-nine.vercel.app                                      |
| Canlı doğrulama (gerçek tarayıcı) | ✅ Arama sonuç veriyor · /admin misafirde RBAC reddi · admin API oturumsuz 401 (aşağıda kanıt)                 |

---

## Epic Özetleri

### Epic 1 — CMS (Faz 24 · ADR-007)

**Değerlendirme yapıldı** (Payload 3 / Sanity / Contentful / Strapi / özel çekirdek) → **şema-öncelikli
özel çekirdek** seçildi. Gerekçe (ADR-007): Payload üretim Postgres'ini **şimdi** ister (DATABASE_URL
hâlâ kullanıcı onayı bekliyor) ve kendi migrasyon/şema düzeni Zod sözleşmemizin yanında **ikinci gerçek
kaynak** yaratırdı. Özel çekirdek mevcut yığının (Zod şema + @ea/db + auth + SaaS kabuk) üstünde çalışır,
PGlite ile yerelde tam test edilebilir, DATABASE_URL bağlanınca üretimde aynen açılır. **Payload'a açık
kapı:** JSONB payload'lar birebir taşınabilir; API sözleşmesi (list/get/publish) değişmez.

- **Şema** (`packages/db/src/cms.ts`): `content_items` (tip+slug+dil+ehliyet-sınıfı benzersiz; status,
  version, JSONB payload, difficulty, tags, publishedAt), `content_versions`, `media_assets`, `audit_logs`.
- İçerik türleri: `lesson · question · article · seo_page · kb` — gelecekteki ehliyet sınıflarına (A1/A2/C/D)
  ve tür genişlemesine açık (`locale`, `licence` kolonları).
- Her yazım `@ea/content-schema` (Zod) ile doğrulanır — **tek doğru sözleşme** korunur.

### Epic 2 — İçerik Hattı (yaşam döngüsü + yönetişim)

- **Durum makinesi** (`@ea/content-schema` WORKFLOW): `draft → in_review → approved → published → retired`
  (+ geri dönüşler). `canTransition(from,to)` sunucuda zorlanır — **onaysız yayın reddedilir** (test kanıtı).
- Her değişiklik ve her geçiş **bir sürüm satırı** (geri dönüş + iz) ve **bir denetim satırı** üretir.
- Yayın/emeklilik → **arama indeksleme kancası** tetiklenir (Epic 5). Böylece yalnız `published` içerik
  halka açık yüzeye ve indekse girer.
- `listPublished(type)` — dersler/makaleler gibi halka açık yüzeyler yalnız yayınlanmış içeriği okur.

### Epic 3 — Admin Panosu (Faz 25 · aynı SaaS kabuğu)

- `/admin` **kalıcı sol sidebar kabuğunda** (marketing değil): Genel Bakış · İçerik · Medya · Kullanıcılar · Denetim.
- **İstemci koruması:** `me()` → admin/editör değilse `admin-denied` kartı ("Giriş yap"); Sidebar'daki
  "Yönetim" linki yalnız yetkiliye görünür. **Sunucu koruması:** her `/api/admin/*` ucunda `requireRole`.
- İçerik tablosu (filtre + hızlı makale oluştur) · JSON payload editörü + **NEXT geçiş düğmeleri** + sürüm
  geçmişi · medya yükleme ızgarası · rol atama · denetim tablosu · istatistik kutucukları.

### Epic 4 — Medya Kütüphanesi (Faz 14 altyapısı)

- Yükleme: `image/svg+xml · png · jpeg · webp · application/json(lottie)`; **2MB temel sınır**;
  desteklenmeyen mime (ör. `.exe`) reddedilir (test kanıtı).
- Temelde veri DB'de base64; **halka açık servis** `/api/media/[id]` doğru `content-type` + değişmez cache.
- Meta (alt, tags, bytes, versiyon). **Adaptör kapısı:** ölçekte Vercel Blob/S3 aynı tablo meta'sıyla takılır.

### Epic 5 — Arama Soyutlaması (Faz 28 · takılabilir)

- `SearchProvider` arayüzü: `{ name, indexContent(docs), search(q) }`. Bugün `LocalSearchProvider`
  (TR-normalize, bellek-içi yayınlanmış-içerik kaydı; yayın ekler, emeklilik çıkarır).
- `getSearchProvider()` fabrikası + `SEARCH_PROVIDER` env → **Meilisearch/Typesense/Algolia yeniden-yazımsız**
  takılır. `/arama` sayfası artık bu soyutlamayı kullanır ("Sağlayıcı: local" etiketi).

### RBAC & Denetim (Faz 25/30 kesişimi)

- `users.role`: `user | editor | admin`. **Rol bootstrap** (`api/auth/register`): `ADMIN_EMAILS` listesi
  → `ADMIN_EMAIL_PATTERN` regex → yönetici yoksa ilk-kullanıcı-admin.
- `requireRole(req, ...roles)` → oturumsuz **401**, yetkisiz **403**. Admin kendi adminliğini **düşüremez**
  (kilitlenme koruması — test kanıtı). Her ayrıcalıklı işlem `audit_logs`'a yazılır.

---

## Test Kanıtı

- **81 unit/integration** (48 web + 33 paket) — Sprint 2 eklemeleri:
  - `content-schema`: WORKFLOW/`canTransition`/`validatePayload`/Article şeması (7 → **9** test).
  - `api.admin.integration.test.ts` (**9 test / ~20 assertion**): RBAC bootstrap (ilk-admin, ikinci-user),
    normal kullanıcı 403 / oturumsuz 401, geçersiz payload 400 + hata listesi, create → v2 güncelleme →
    **onaysız yayın reddi** → in_review → approved → published, sürümler ≥ 4, SVG medya round-trip (doğru mime),
    `.exe` reddi, rol atama (editor kilidi açar), **öz-düşürme reddi**, denetim aksiyonları, istatistik tutarlılığı.
- **28 e2e** (6 spec) — `admin.spec.ts` (**5 test**): içerik hattı UI, geçersiz payload, medya yükleme
  (`setInputFiles`), misafir/`user-e2e-*` için **RBAC reddi**, arama soyutlaması. Hepsi **production build** üzerinde.
- Kapılar: lint + typecheck + build (22 sayfa + 15 API rotası) — hepsi yeşil. **GitHub Actions yeşil.**

## Production Canlı Doğrulama (gerçek tarayıcı, 2026-07-15)

| Yüzey                            | Kanıt                                                                                                    |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Arama (`/arama`)                 | ✅ "hız" → `LocalSearchProvider` ilgili soruları döndürdü (ders + cevap kartları); "Sağlayıcı: local"    |
| Admin RBAC (`/admin`)            | ✅ Misafirde `admin-denied` kartı: "Bu alan yönetici/editör yetkisi gerektirir"; Sidebar "Yönetim" gizli |
| Admin API (`/api/admin/content`) | ✅ Oturumsuz → **401** (RBAC canlıda; curl ile doğrulandı)                                               |
| Kabuk bütünlüğü                  | ✅ /admin ve /arama aynı kalıcı sol sidebar SaaS kabuğunda; konsol 0 hata                                |

## Değişen/Eklenen Başlıca Dosyalar

- **Şema/DB:** `packages/db/src/cms.ts` (4 tablo) · `packages/db/src/schema.ts` (`users.role`) ·
  `packages/db/src/index.ts` (bootstrap DDL + CMS tabloları + role kolonu).
- **Sözleşme:** `packages/content-schema/src/index.ts` (`Article`, `WORKFLOW`, `canTransition`, `validatePayload`).
- **Servis:** `apps/web/lib/server/cms.ts` (içerik hattı) · `apps/web/lib/server/auth.ts` (`requireRole`, `guarded`).
- **API:** `app/api/admin/{content,content/[id],media,users,audit,stats}` · `app/api/media/[id]`.
- **UI:** `app/(app)/admin/*` (layout + 6 sayfa) · `app/(app)/arama/page.tsx` (yeniden yazıldı) ·
  `lib/search.ts` (SearchProvider) · `components/Sidebar.tsx` (Yönetim linki) · `lib/authClient.ts` (`role`).
- **Test:** `lib/server/api.admin.integration.test.ts` · `lib/search.test.ts` · `e2e/admin.spec.ts`.
- **Karar:** `docs/adr/007-cms.md`.

## Production Durumu ve TEK Kalan Dış Aksiyon (Sprint 1 ile aynı)

Kod production'da; misafir deneyimi + arama + admin RBAC reddi canlıda çalışıyor. CMS/admin'in
**veri yazan** uçları (içerik oluştur/yayınla, medya yükle, rol ata) **Postgres** gerektirir. Neon
entegrasyonu CLI'dan başlatıldı; **marketplace şartlarının kabulü** kullanıcı onayı gerektirdiğinden
(hukuki sözleşme — otonom kabul edilmedi) tek adım kaldı:

1. Aç ve kabul et: https://vercel.com/emre30283-4955s-projects/~/integrations/accept-terms/neon?source=cli
2. `vercel integration add neon` (DATABASE_URL otomatik bağlanır)
3. `vercel deploy --prod --yes`

Şema ilk bağlantıda idempotent bootstrap ile kendini kurar (CMS tabloları dahil). Şartlar kabul edilene
dek admin/CMS yazma uçları üretimde **bilinçli 503** (`DB_NOT_CONFIGURED`) döner; okuma/misafir akışları tam çalışır.

## Sprint 3 Adaylığı (ROADMAP sırası — BAŞLATILMADI)

Gerçek tahsilat adaptörü (LemonSqueezy/Stripe one-time + webhook) · içerik derinleştirme (100+/konu +
uzman onay döngüsü — artık hat hazır) · Faz 22 gerçek AI adaptörü · Faz 30 güvenlik sertleştirme
(CSP/pen-test/KVKK) · Faz 31 gözlemlenebilirlik (Sentry). **Bu sprintte başlatılmadı** — direktif gereği
Sprint 2'de durduruldu.
