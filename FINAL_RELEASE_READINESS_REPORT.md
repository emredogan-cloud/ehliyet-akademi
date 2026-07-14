# FINAL RELEASE READINESS REPORT — Ehliyet Akademi

_Tarih: 2026-07-15 · Değerlendiren: otonom yürütme · Tek doğru kaynak: `ROADMAP.md` (v3.1)_

---

## Sonuç: 🟡 KOŞULLU GO (Önizleme/MVP) · 🔴 NO-GO (tam ticari lansman)

- **🟢 GO —** çekirdek öğrenme ürününün **önizleme/MVP deploy'u** (tanı denemesi → hazırlık skoru, dersler, e-Sınav yapısı). Kod test edilmiş, güvenli, statik ve hızlı.
- **🔴 NO-GO —** tam ticari lansman: monetizasyon, hesap/DB kalıcılığı (sunucu), AI, CMS, admin, mobil-mağaza ve tam güvenlik sertleştirmesi henüz üretimde değil (ROADMAP Faz 15–35 planlı).

Gerekçe: Çekirdek döngü production-kalite ve doğrulanmış; ancak "en gelişmiş platform"
hedefinin gelir/ölçek/operasyon katmanları henüz kurulmadı. Önizleme yayını, gerçek
kullanıcıyla PMF sinyali toplamak için doğru ve güvenli adımdır (ROADMAP E.1: web-first).

---

## Alan Bazlı Kontroller

### Production Readiness

| Alan             | Durum | Not                                                                  |
| ---------------- | ----- | -------------------------------------------------------------------- |
| Build            | 🟢    | `next build` yeşil, 14 sayfa (SSG)                                   |
| Çalışma zamanı   | 🟢    | RSC/SSG; harici servis olmadan çalışır (mock/local)                  |
| Hesap kalıcılığı | 🟡    | Şimdilik LocalStorage; sunucu auth+DB (Faz 4 omurgası/ADR) takılacak |
| Ölçek            | 🟡    | İçerik statik ölçeklenir; DB/arama/analitik prod servisleri ENV ile  |

### ENV Kontrolü — 🟢

`ENV_SETUP_GUIDE.md` tüm ENV'leri kapsar; **hiçbiri zorunlu değil** (mock/local varsayılan).
Üretimde `DATABASE_URL`, `AUTH_SECRET` + istenen servis anahtarları girilir. `.env` repoda değil.

### Security Kontrolü — 🟡

- 🟢 Güvenlik başlıkları (nosniff, DENY, referrer, permissions-policy).
- 🟢 Repoda sır yok (gitleaks kapısı + CodeQL + Dependabot); proprietary lisans.
- 🟡 Tam sertleştirme (CSP, auth/ödeme/PII akışı, RBAC, pen-test, KVKK veri-silme) → **Faz 30 planlı**.

### Performance Kontrolü — 🟢

Statik (SSG) sayfalar, minimal JS (~103 kB paylaşımlı), CWV-dostu mimari. Lighthouse CI eşiği CI'da tanımlı (billing sonrası aktif).

### Accessibility Kontrolü — 🟢 (temel)

Semantik HTML, skip-link, görünür odak, ARIA/`aria-live`, koyu/açık tema, ≥44px dokunma hedefleri. Tam eksiksiz axe/manuel regresyon Faz 20'de genişletilir.

### SEO Kontrolü — 🟡

- 🟢 sitemap.xml, robots.txt, OG/metadata, crawl'lanabilir URL'ler, SSG (indekslenebilir).
- 🟡 schema.org (Course/Quiz/FAQ/HowTo), topic-cluster, programatik SEO → **Faz 15 planlı**.

### AI Kontrolü — 🔴 (planlı)

AI platformu (koç/açıklama/hazırlık tahmini) **Faz 22 planlı**. Soyutlama + `AI_PROVIDER=mock`
politikası hazır; grounding + anti-halüsinasyon + maliyet tavanı orada uygulanacak.

### CMS Kontrolü — 🔴 (planlı)

İçerik şu an tipli TS (şema-doğrulamalı). CMS (Payload) **Faz 24 planlı**; şema-uyumlu geçiş.

### Admin Kontrolü — 🔴 (planlı)

Yönetim paneli **Faz 25 planlı** (RBAC, moderasyon, ödeme, feature flags, audit log).

### Test Özeti — 🟢

30 birim + 4 e2e (gerçek tarayıcı) + build; hepsi yeşil. Görsel/perf/a11y regresyon paketleri Faz 20'de eklenecek.

### CI Özeti — 🟡

Workflow'lar hazır (quality/e2e/gitleaks/CodeQL/commitlint). **Dış engel:** GitHub Actions
faturalandırma kilidi nedeniyle hosted koşum başlamıyor. **Telafi:** yerel `pnpm gates` + e2e
her faz çalıştırıldı (CI'ın birebir muadili). **Aksiyon (kullanıcı):** GitHub Billing'i düzelt
**veya** repo'yu public yap → Actions + CodeQL + branch protection açılır.

---

## Açık Riskler

1. **Hosted CI kapalı (dış/billing)** — orta. Telafi: yerel kapılar. Aksiyon kullanıcıda.
2. **Branch protection yok** (Pro/public gerektiriyor) — düşük. Telafi: trunk disiplini + yerel kapılar.
3. **İçerik hacmi** — orta. 22 soru/3 ders MVP kanıtı; sınav güveni için konu başına 100+ ve 4 dersin tümü gerekir (Faz 11–12; uzman onayı — E.6).
4. **Sunucu kalıcılığı yok** — orta. Çok-cihaz/senkron için auth+DB devreye alınmalı (omurga/ADR hazır).
5. **İlk yardım içeriği** — yüksek hassasiyet. Yayından önce **ilk yardım eğitmeni onayı** zorunlu (şemada `review` alanı `draft`).

## Bilinen Kısıtlar

- Monetizasyon, AI, CMS, admin, topluluk, mobil-native, tam gözlemlenebilirlik henüz üretimde değil (ROADMAP sırasıyla planlı).
- Soru bankası ve dersler başlangıç kümesidir (özgün; genişletilecek).
- Hazırlık skoru tahmini kalibre bir modeldir; gerçek geçme oranıyla doğrulanınca ayarlanacaktır (Faz 35).

---

## Deploy Önerisi (önizleme)

1. Repo'yu public yap **veya** GitHub Billing'i düzelt → CI/CodeQL/branch protection aktifleşir.
2. Vercel'e bağla (`apps/web`); `NEXT_PUBLIC_SITE_URL` set et; ENV'siz de çalışır.
3. Önizleme URL'sinde çekirdek akışı doğrula (e2e zaten yeşil).
4. Faz 15 (SEO schema) + içerik genişletme + auth/DB ile ticari-hazırlığa doğru ilerle.

**Özet:** Sağlam, test edilmiş, güvenli bir temel ve çalışan çekirdek ürün hazır →
**önizleme için GO**. Tam ticari lansman, ROADMAP Faz 15–35 tamamlandıkça **GO**'a döner.
