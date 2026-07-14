# ADR-001 — Çatı: Next.js App Router

**Statü:** Kabul edildi (ROADMAP Faz 3–4)

## Bağlam

Ürün aynı anda **SEO-kritik** (trafik organik aramadan gelir), **yoğun etkileşimli**
(quiz/simülatör/SRS) ve **hesap/ödeme** gerektirir. v1 vanilla SPA + hash router SEO'da kördür.

## Karar

**Next.js (App Router)** + React Server Components; SSG/ISR ile içerik ve programatik SEO
sayfaları, client component ile etkileşim. Barındırma hedefi Vercel; ancak kod
Vercel-bağımsız çalışacak (standart Node runtime).

## Sonuçlar

- (+) En güçlü SEO (SSR/SSG/ISR), tek çatıda içerik + uygulama + API + auth.
- (+) Devasa ekosistem (auth, ödeme, i18n).
- (−) React öğrenme eğrisi; over-engineering riski → P0/P1 disiplini (ROADMAP E.2).
- Alternatifler: Astro (etkileşim ada yönetimi zor), SvelteKit (küçük ekosistem), vanilla+geliştir (SEO/ölçek duvarı) — reddedildi (ROADMAP Faz 4 tablosu).
