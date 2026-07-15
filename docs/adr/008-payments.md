# ADR-008 — Ödeme: LemonSqueezy (Merchant of Record), tek-seferlik satın alma

**Statü:** Kabul edildi · Sprint 4 (2026-07-15) · ROADMAP Faz 16 (tek-seferlik pivot) ile uyumlu

## Bağlam

Platform **tek-seferlik** (abonelik YOK) dijital paketler satar (Faz 16 pivotu). Üretim tahsilatı
için gerçek bir ödeme sağlayıcısı gerekir; Türkiye'de KDV/e-fatura yükümlülükleri kritik.

## Değerlendirme

| Aday             | Değerlendirme                                                                                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LemonSqueezy** | **Merchant of Record**: KDV/vergi, fatura ve iade yükünü ÜSTLENİR (solo satıcı için kritik); dijital ürünlere odaklı; hosted checkout; HMAC imzalı webhook; basit |
| Stripe           | Daha fazla kontrol ama **MoR sensiniz** — Türkiye KDV/e-fatura ve uyum tümüyle sizde; tek-seferlik dijital ürün için gereğinden ağır                              |
| **Karar**        | **LemonSqueezy** — MoR modeli, tek geliştiriciyle uyumluluğu ve dijital-ürün akışını basitleştirir                                                                |

## Karar

**LemonSqueezy** ağ geçidi, sağlayıcı-agnostik `PaymentGateway` arayüzü ardında
(`apps/web/lib/server/checkout.ts`). Varsayılan **MockGateway** (harici servissiz tam akış); ENV
(`LEMONSQUEEZY_API_KEY`, `LEMONSQUEEZY_STORE_ID`, `LEMONSQUEEZY_WEBHOOK_SECRET`,
`LEMONSQUEEZY_VARIANT_<PRODUCT>`) geldiğinde gerçek adaptör devreye girer — **uygulama sözleşmesi değişmez**.

Akış:

1. `POST /api/checkout` → mock ise `{mode:'mock'}` (istemci sunucu-grant kullanır), gerçek ise
   hosted checkout URL'i (`{mode:'redirect'}`). Rate-limited.
2. Webhook `POST /api/webhooks/lemonsqueezy` → **HAM gövde HMAC-SHA256 imza doğrulaması**
   (timingSafeEqual) → `order_created` ayrıştırma → **makbuz doğrulaması** (ürün var + katalog
   fiyatı ile tutarlı) → **idempotent** sahiplik yazımı (`external_ref` = sipariş id) → onay e-postası.
3. Sahiplik `purchases` tablosunda kalıcı; satır = ömür boyu erişim. Restore = sunucudan geri yükleme.

**Fiyat-bütünlüğü:** fiyat her zaman SUNUCUDA katalogdan (`lib/products`) doğrulanır; istemci fiyatı asla güvenilmez.

## Sonuçlar

- (+) Bugün: gerçek para olmadan tam test edilebilir (mock); ENV ile üretime tek adım.
- (+) Webhook imza + makbuz + idempotency = güvenli, tekrar-güvenli tahsilat.
- (−) Gerçek tahsilat için LemonSqueezy hesabı + variant kurulumu (kullanıcı aksiyonu) gerekir.
- Not: gelecekte Stripe gerekirse aynı `PaymentGateway` arayüzüyle ikinci adaptör takılır.
