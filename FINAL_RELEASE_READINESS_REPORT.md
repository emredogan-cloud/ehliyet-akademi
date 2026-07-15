# FINAL RELEASE READINESS REPORT — Ehliyet Akademi

_Tarih: 2026-07-15 (v8 — Sprint 5 sonrası) · Tek doğru kaynak: `ROADMAP.md` (v3.1)_

---

## Sonuç: 🟢 GO — Public Beta (canlı) · 🟡 KOŞULLU — gerçek tahsilat · 🔴 NO-GO — "tam kurumsal platform" iddiası

- **🟢 GO (yayında):** Ürün **production'da canlı**: https://ehliyet-akademi-nine.vercel.app — **SaaS kabuk (sidebar+panel)**, tanı→hazırlık skoru, 5 ders+görseller, AI koç (mock), başarılar, arama, tema, SRS pratiği+seri, **gerçek formatlı e-Sınav simülatörü**, tek-seferlik paket vitrini (demo ödeme), PWA. CI yeşil, tarayıcı doğrulaması eksiksiz. **Public beta olarak kullanıcı almaya hazır.**
- **🟡 KOŞULLU (para almadan önce):** ödeme **mimarisi Sprint 4'te tamamlandı** (ADR-008 LemonSqueezy adaptörü + HMAC webhook + makbuz doğrulaması + idempotency; yasal taslak metinler + çerez rızası + hesap silme hazır) — ancak canlı satış için **kullanıcı aksiyonu** gerekir: `LEMONSQUEEZY_*` + `RESEND_API_KEY` + prod `DATABASE_URL` ENV'leri ve yasal metinlerin **hukukçu onayı**. O gelene dek satın alma **demo modda** (etiketli).
- **🔴 NO-GO:** ROADMAP'in kalan vizyonu (ASO/mağaza, topluluk, platform zekâsı — Faz 17/32/33/35 vb.) henüz üretimde değil; "Türkiye'nin en gelişmiş platformu" iddiasıyla pazarlama bu fazlar sonrası. **(Faz 22 AI · 23 analitik · 24 CMS · 25 Admin · 26/27 Auth-DB · 28 Arama · 30 güvenlik · 31 gözlemlenebilirlik çekirdekleri artık tamam.)**

## Alan Bazlı Kontroller

| Alan                        | Durum                         | Not                                                                                                                                                                                                                |
| --------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Production Readiness**    | 🟢                            | Vercel prod canlı; SSG+ISR-hazır; 0 konsol hatası; deploy tek komut                                                                                                                                                |
| **ENV**                     | 🟢                            | Rehber güncel (deploy bölümü eklendi); tek zorunlu env yok; `NEXT_PUBLIC_SITE_URL` prod'da set                                                                                                                     |
| **Security / Uyum**         | 🟢                            | **Sprint 5:** CSP + tam güvenlik başlığı seti (HSTS/nosniff/DENY/…) + CSRF middleware + secrets validation + OWASP review (SECURITY_REVIEW.md) · (+Sprint 4 rate-limit/KVKK/rıza/hesap silme) · WAF/pen-test kalan |
| **Performance**             | 🟢                            | SSG, ~103 kB paylaşımlı JS; prod hızlı (CWV-dostu); Lighthouse CI eşiği sonraki hijyen turu                                                                                                                        |
| **Accessibility**           | 🟢 (temel)                    | Semantik, skip-link, odak, aria-live, kontrast; tam axe-regresyon Faz 20 genişletmesi                                                                                                                              |
| **SEO**                     | 🟢 (temel)                    | Crawl'lanabilir URL + sitemap(prod URL) + robots + **JSON-LD canlıda** · programatik/pillar içerik Faz 15 devamı                                                                                                   |
| **AI**                      | 🟢 (mimari)/🟡 (gerçek model) | **Sprint 5:** sunucu grounded AI (`/api/ai/ask` + halüsinasyon kapısı + model soyutlaması + fallback + eval %100) canlıda; gerçek model `ANTHROPIC_API_KEY` ENV bekliyor (yoksa mock, 0 halüsinasyon)              |
| **Analitik**                | 🟢 (mimari)                   | **Sprint 5:** rıza-kapılı GA4/Clarity/PostHog katmanı; gizlilik-öncelikli no-op; gerçek anahtarlar `NEXT_PUBLIC_*` ENV bekliyor                                                                                    |
| **Gözlemlenebilirlik**      | 🟢 (temel)                    | **Sprint 5:** /api/health + captureException (Sentry-hazır) + instrumentation + yapısal logger; `SENTRY_DSN` ENV ile tam izleme                                                                                    |
| **CMS / Admin**             | 🟢 (temel)                    | **Sprint 2:** özel CMS çekirdeği + içerik hattı (durum makinesi + sürüm + denetim) + /admin RBAC — canlı (yazma uçları DATABASE_URL bekliyor); zengin blok-editör sonraki tur                                      |
| **RBAC / Denetim**          | 🟢                            | user/editor/admin; `requireRole` (401/403); rol bootstrap; öz-adminlik kilidi; tam `audit_logs`                                                                                                                    |
| **Arama**                   | 🟢 (temel)                    | `SearchProvider` soyutlaması + LocalSearchProvider canlıda; Meili/Typesense/Algolia yeniden-yazımsız takılır                                                                                                       |
| **Payments (tek-seferlik)** | 🟢 (mimari)/🟡 (canlı)        | **Sprint 4:** LemonSqueezy adaptörü + HMAC webhook + makbuz + idempotency + premium erişim kontrolü **hazır**; gerçek tahsilat `LEMONSQUEEZY_*` ENV bekliyor (o gelene dek demo, etiketli)                         |
| **E-posta**                 | 🟢 (mimari)                   | **Sprint 4:** Resend adaptörü + 5 şablon + doğrulama/reset/onay/destek akışları; gerçek gönderim `RESEND_API_KEY` bekliyor (yoksa console/devToken)                                                                |
| **Yasal / KVKK**            | 🟡 (taslak)                   | **Sprint 4:** 4 yasal sayfa + rıza + veri dışa aktarma + hesap silme **hazır**; metinler **hukukçu onayı** + gerçek şirket bilgisi bekliyor                                                                        |
| **Test**                    | 🟢                            | 148 unit/integration + 41 e2e; **CI'da** koşuyor                                                                                                                                                                   |
| **İçerik derinliği**        | 🟢 (temel)                    | **Sprint 3:** 198 özgün soru (82 konu) + 19 zengin ders + 12 SVG; 100+/konu ölçekleme sürüyor; ilk yardım uzman onayı bekliyor                                                                                     |
| **Öğrenme deneyimi**        | 🟢                            | Grounded AI asistanı (çalışma planı/zayıf konu/kişisel tekrar) + tekrar kartları + alıştırma + ustalık radarı — canlı                                                                                              |
| **CI**                      | 🟢                            | Actions yeşil (quality/e2e/gitleaks/CodeQL); kırmızı→düzelt→yeşil disiplini uygulandı                                                                                                                              |
| **Deploy doğrulaması**      | 🟢                            | Preview + Production; canlıda tarayıcı ile 8 akış doğrulandı (geliştirme raporu §5)                                                                                                                                |

## Açık Riskler

1. **Demo ödeme yanlış anlaşılması** — düşük: Sprint 4'te ödeme mimarisi (webhook/makbuz/idempotency) tamam; UI'da açık "demo modda — gerçek tahsilat yapılmaz" etiketi. Gerçek satış için yalnız `LEMONSQUEEZY_*` ENV + yasal metin onayı kaldı.
2. ~~Entitlement/ilerleme yalnız cihazda~~ → **ÇÖZÜLDÜ (Sprint 1):** hesapla giriş → sunucu senkronu + restore. Kalan: prod DATABASE_URL (Neon şartları — kullanıcı kabulü; link SPRINT_1_REPORT.md).
3. ~~İçerik hacmi (53 soru)~~ → **AZALDI (Sprint 3):** 198 özgün soru (82 konu) + 19 ders; çeşitlilik belirgin arttı. Kalan: 100+/konu ölçekleme + `review: approved` (şu an tümü draft).
4. **İlk yardım içeriği uzman onayı** — yüksek önem: yayın etiketi "uzman onayı bekliyor"; onay süreci tamamlanmalı.
5. **Dependabot 9 PR** (major bump'lar) — düşük: ayrı hijyen turu.
6. **`ehliyet-akademi.vercel.app` yalın adı başka projeye ait** — düşük: kanonik adres `-nine`; özel domain alınca önemsizleşir.

## Bilinen Kısıtlar

Faz 17/19/29/32/33/35 üretimde değil (ROADMAP'te planlı; **22/23/24/25/26/27/28/30/31 tamam**) · CMS/admin/hesap/ödeme yazma uçları prod DATABASE_URL bekliyor (o gelene dek bilinçli 503) · gerçek AI/analitik/Sentry/tahsilat/e-posta ENV bekliyor · CSP `'unsafe-inline'` (SSG kısıtı; nonce ertelendi) · rate-limit bellek-içi · WAF/pen-test yok · Lighthouse-CI/görsel-regresyon kapıları henüz zorunlu-check değil.

## Yayın Sonrası İlk Adımlar (öneri, ROADMAP sırasına uygun)

1. GSC'ye sitemap gönder (Faz 15 devamı) — organik ölçüm gün-1.
2. Auth+DB kalıcılığı → entitlement/ilerleme senkronu (Faz 26/27 kalanı).
3. Gerçek tahsilat adaptörü + hukuki metinler → 🟡'yi 🟢'ye çevir.
4. İçerik motoru: soru üretim hattıyla bankayı büyüt + uzman onay döngüsü.
5. Faz 22 AI (mock→gerçek, grounded) ve Faz 23 analitik.

**Özet:** Çekirdek ürün **canlı, test edilmiş ve CI-korumalı**. Beta kullanıcı trafiği için **GO**;
para tahsilatı ve "tam platform" iddiası için sıradaki fazlar tamamlanmalı.
