# FINAL RELEASE READINESS REPORT — Ehliyet Akademi

_Tarih: 2026-07-15 (v5 — Sprint 2 sonrası) · Tek doğru kaynak: `ROADMAP.md` (v3.1)_

---

## Sonuç: 🟢 GO — Public Beta (canlı) · 🟡 KOŞULLU — gerçek tahsilat · 🔴 NO-GO — "tam kurumsal platform" iddiası

- **🟢 GO (yayında):** Ürün **production'da canlı**: https://ehliyet-akademi-nine.vercel.app — **SaaS kabuk (sidebar+panel)**, tanı→hazırlık skoru, 5 ders+görseller, AI koç (mock), başarılar, arama, tema, SRS pratiği+seri, **gerçek formatlı e-Sınav simülatörü**, tek-seferlik paket vitrini (demo ödeme), PWA. CI yeşil, tarayıcı doğrulaması eksiksiz. **Public beta olarak kullanıcı almaya hazır.**
- **🟡 KOŞULLU (para almadan önce):** ödeme şu an **demo** (MockPaymentProvider — gerçek tahsilat yok ve öyle etiketli). Gerçek satış için: LemonSqueezy/Stripe **one-time** adaptörü + webhook + iade akışı + auth/DB'ye taşınmış entitlement + Mesafeli Satış/KVKK metinleri.
- **🔴 NO-GO:** ROADMAP'in tam vizyonu (gerçek AI platformu, topluluk, platform zekâsı — Faz 22/32/33/35 vb.) henüz üretimde değil; "Türkiye'nin en gelişmiş platformu" iddiasıyla pazarlama bu fazlar sonrası. **(Faz 24 CMS · 25 Admin · 26/27 Auth-DB · 28 Arama çekirdekleri artık tamam.)**

## Alan Bazlı Kontroller

| Alan                        | Durum      | Not                                                                                                                                                                           |
| --------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Production Readiness**    | 🟢         | Vercel prod canlı; SSG+ISR-hazır; 0 konsol hatası; deploy tek komut                                                                                                           |
| **ENV**                     | 🟢         | Rehber güncel (deploy bölümü eklendi); tek zorunlu env yok; `NEXT_PUBLIC_SITE_URL` prod'da set                                                                                |
| **Security**                | 🟡         | Başlıklar + gitleaks + CodeQL + branch protection ✅ · CSP/pen-test/KVKK metinleri Faz 30                                                                                     |
| **Performance**             | 🟢         | SSG, ~103 kB paylaşımlı JS; prod hızlı (CWV-dostu); Lighthouse CI eşiği sonraki hijyen turu                                                                                   |
| **Accessibility**           | 🟢 (temel) | Semantik, skip-link, odak, aria-live, kontrast; tam axe-regresyon Faz 20 genişletmesi                                                                                         |
| **SEO**                     | 🟢 (temel) | Crawl'lanabilir URL + sitemap(prod URL) + robots + **JSON-LD canlıda** · programatik/pillar içerik Faz 15 devamı                                                              |
| **AI**                      | 🟡 (mock)  | **AI Koç canlıda** — grounded mock (halüsinasyon=0, uyarı etiketli); gerçek model ENV ile takılır                                                                             |
| **CMS / Admin**             | 🟢 (temel) | **Sprint 2:** özel CMS çekirdeği + içerik hattı (durum makinesi + sürüm + denetim) + /admin RBAC — canlı (yazma uçları DATABASE_URL bekliyor); zengin blok-editör sonraki tur |
| **RBAC / Denetim**          | 🟢         | user/editor/admin; `requireRole` (401/403); rol bootstrap; öz-adminlik kilidi; tam `audit_logs`                                                                               |
| **Arama**                   | 🟢 (temel) | `SearchProvider` soyutlaması + LocalSearchProvider canlıda; Meili/Typesense/Algolia yeniden-yazımsız takılır                                                                  |
| **Payments (tek-seferlik)** | 🟡         | Model + katalog + entitlement + kota **canlıda (demo)**; gerçek tahsilat koşullu-GO listesi                                                                                   |
| **Test**                    | 🟢         | 81 unit/integration + 28 e2e; **CI'da** koşuyor                                                                                                                               |
| **CI**                      | 🟢         | Actions yeşil (quality/e2e/gitleaks/CodeQL); kırmızı→düzelt→yeşil disiplini uygulandı                                                                                         |
| **Deploy doğrulaması**      | 🟢         | Preview + Production; canlıda tarayıcı ile 8 akış doğrulandı (geliştirme raporu §5)                                                                                           |

## Açık Riskler

1. **Demo ödeme yanlış anlaşılması** — düşük/orta: UI'da açık "demo ödeme — gerçek tahsilat yapılmaz" etiketi var; gerçek satış öncesi koşullu-GO listesi tamamlanmalı.
2. ~~Entitlement/ilerleme yalnız cihazda~~ → **ÇÖZÜLDÜ (Sprint 1):** hesapla giriş → sunucu senkronu + restore. Kalan: prod DATABASE_URL (Neon şartları — kullanıcı kabulü; link SPRINT_1_REPORT.md).
3. **İçerik hacmi** — orta: 53 soru tam sınav dağılımını karşılar ama tekrar eden denemelerde çeşitlilik sınırlı; 100+/konu + uzman onayı (`review: approved`) hedefi açık.
4. **İlk yardım içeriği uzman onayı** — yüksek önem: yayın etiketi "uzman onayı bekliyor"; onay süreci tamamlanmalı.
5. **Dependabot 9 PR** (major bump'lar) — düşük: ayrı hijyen turu.
6. **`ehliyet-akademi.vercel.app` yalın adı başka projeye ait** — düşük: kanonik adres `-nine`; özel domain alınca önemsizleşir.

## Bilinen Kısıtlar

Faz 17/19/22/23/29–33/35 üretimde değil (ROADMAP'te planlı; **24/25/26/27/28 tamam**) · CMS/admin yazma uçları prod DATABASE_URL bekliyor (o gelene dek bilinçli 503) · zengin CMS blok-editörü sonraki tur · hazırlık-skoru tahmini kalibrasyonu gerçek geçme verisiyle rafine edilecek (Faz 35) · Lighthouse-CI/görsel-regresyon kapıları henüz zorunlu-check değil.

## Yayın Sonrası İlk Adımlar (öneri, ROADMAP sırasına uygun)

1. GSC'ye sitemap gönder (Faz 15 devamı) — organik ölçüm gün-1.
2. Auth+DB kalıcılığı → entitlement/ilerleme senkronu (Faz 26/27 kalanı).
3. Gerçek tahsilat adaptörü + hukuki metinler → 🟡'yi 🟢'ye çevir.
4. İçerik motoru: soru üretim hattıyla bankayı büyüt + uzman onay döngüsü.
5. Faz 22 AI (mock→gerçek, grounded) ve Faz 23 analitik.

**Özet:** Çekirdek ürün **canlı, test edilmiş ve CI-korumalı**. Beta kullanıcı trafiği için **GO**;
para tahsilatı ve "tam platform" iddiası için sıradaki fazlar tamamlanmalı.
