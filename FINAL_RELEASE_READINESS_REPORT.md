# FINAL RELEASE READINESS REPORT — Ehliyet Akademi

_Tarih: 2026-07-15 (v2 — production deploy sonrası) · Tek doğru kaynak: `ROADMAP.md` (v3.1)_

---

## Sonuç: 🟢 GO — Public Beta (canlı) · 🟡 KOŞULLU — gerçek tahsilat · 🔴 NO-GO — "tam kurumsal platform" iddiası

- **🟢 GO (yayında):** Ürün **production'da canlı**: https://ehliyet-akademi-nine.vercel.app — tanı→hazırlık skoru, 5 ders+görseller, SRS pratiği+seri, **gerçek formatlı e-Sınav simülatörü**, tek-seferlik paket vitrini (demo ödeme), PWA. CI yeşil, tarayıcı doğrulaması eksiksiz. **Public beta olarak kullanıcı almaya hazır.**
- **🟡 KOŞULLU (para almadan önce):** ödeme şu an **demo** (MockPaymentProvider — gerçek tahsilat yok ve öyle etiketli). Gerçek satış için: LemonSqueezy/Stripe **one-time** adaptörü + webhook + iade akışı + auth/DB'ye taşınmış entitlement + Mesafeli Satış/KVKK metinleri.
- **🔴 NO-GO:** ROADMAP'in tam vizyonu (AI platformu, CMS, admin, topluluk, platform zekâsı — Faz 22–35) henüz üretimde değil; "Türkiye'nin en gelişmiş platformu" iddiasıyla pazarlama bu fazlar sonrası.

## Alan Bazlı Kontroller

| Alan                        | Durum      | Not                                                                                                              |
| --------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------- |
| **Production Readiness**    | 🟢         | Vercel prod canlı; SSG+ISR-hazır; 0 konsol hatası; deploy tek komut                                              |
| **ENV**                     | 🟢         | Rehber güncel (deploy bölümü eklendi); tek zorunlu env yok; `NEXT_PUBLIC_SITE_URL` prod'da set                   |
| **Security**                | 🟡         | Başlıklar + gitleaks + CodeQL + branch protection ✅ · CSP/pen-test/KVKK metinleri Faz 30                        |
| **Performance**             | 🟢         | SSG, ~103 kB paylaşımlı JS; prod hızlı (CWV-dostu); Lighthouse CI eşiği sonraki hijyen turu                      |
| **Accessibility**           | 🟢 (temel) | Semantik, skip-link, odak, aria-live, kontrast; tam axe-regresyon Faz 20 genişletmesi                            |
| **SEO**                     | 🟢 (temel) | Crawl'lanabilir URL + sitemap(prod URL) + robots + **JSON-LD canlıda** · programatik/pillar içerik Faz 15 devamı |
| **AI**                      | 🔴 planlı  | Faz 22; `AI_PROVIDER=mock` soyutlama sözleşmesi hazır                                                            |
| **CMS / Admin**             | 🔴 planlı  | Faz 24/25; içerik tipli-TS + şema doğrulamalı (geçiş şema-uyumlu)                                                |
| **Payments (tek-seferlik)** | 🟡         | Model + katalog + entitlement + kota **canlıda (demo)**; gerçek tahsilat koşullu-GO listesi                      |
| **Test**                    | 🟢         | 43 unit + 10 e2e; **CI'da** koşuyor                                                                              |
| **CI**                      | 🟢         | Actions yeşil (quality/e2e/gitleaks/CodeQL); kırmızı→düzelt→yeşil disiplini uygulandı                            |
| **Deploy doğrulaması**      | 🟢         | Preview + Production; canlıda tarayıcı ile 8 akış doğrulandı (geliştirme raporu §5)                              |

## Açık Riskler

1. **Demo ödeme yanlış anlaşılması** — düşük/orta: UI'da açık "demo ödeme — gerçek tahsilat yapılmaz" etiketi var; gerçek satış öncesi koşullu-GO listesi tamamlanmalı.
2. **Entitlement/ilerleme yalnız cihazda** (localStorage) — orta: auth+DB kalıcılığı (Faz 4 omurgası hazır) taşınmalı; cihaz değişiminde kayıp olur.
3. **İçerik hacmi** — orta: 53 soru tam sınav dağılımını karşılar ama tekrar eden denemelerde çeşitlilik sınırlı; 100+/konu + uzman onayı (`review: approved`) hedefi açık.
4. **İlk yardım içeriği uzman onayı** — yüksek önem: yayın etiketi "uzman onayı bekliyor"; onay süreci tamamlanmalı.
5. **Dependabot 9 PR** (major bump'lar) — düşük: ayrı hijyen turu.
6. **`ehliyet-akademi.vercel.app` yalın adı başka projeye ait** — düşük: kanonik adres `-nine`; özel domain alınca önemsizleşir.

## Bilinen Kısıtlar

Faz 17/19/22–35 üretimde değil (ROADMAP'te planlı) · hazırlık-skoru tahmini kalibrasyonu gerçek geçme verisiyle rafine edilecek (Faz 35) · Lighthouse-CI/görsel-regresyon kapıları henüz zorunlu-check değil.

## Yayın Sonrası İlk Adımlar (öneri, ROADMAP sırasına uygun)

1. GSC'ye sitemap gönder (Faz 15 devamı) — organik ölçüm gün-1.
2. Auth+DB kalıcılığı → entitlement/ilerleme senkronu (Faz 26/27 kalanı).
3. Gerçek tahsilat adaptörü + hukuki metinler → 🟡'yi 🟢'ye çevir.
4. İçerik motoru: soru üretim hattıyla bankayı büyüt + uzman onay döngüsü.
5. Faz 22 AI (mock→gerçek, grounded) ve Faz 23 analitik.

**Özet:** Çekirdek ürün **canlı, test edilmiş ve CI-korumalı**. Beta kullanıcı trafiği için **GO**;
para tahsilatı ve "tam platform" iddiası için sıradaki fazlar tamamlanmalı.
