# ADR-004 — Kimlik doğrulama soyutlaması

**Statü:** Kabul edildi · **Sprint 1'de uygulandı (2026-07-15)**

## Sprint 1 karar güncellemesi — sağlayıcı karşılaştırması

| Aday                           | Değerlendirme                                                                                                                               |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Clerk                          | Güçlü DX ama harici hesap + vendor kilidi; otonom kurulamaz                                                                                 |
| Auth.js v5                     | Olgun; ancak Credentials akışında ek soyutlama katmanı ve konfig yükü                                                                       |
| Supabase/Firebase              | Platform kilidi + harici hesap gerektirir                                                                                                   |
| **Özel credentials (SEÇİLDİ)** | node:crypto scrypt + DB-destekli oturum: sıfır harici bağımlılık, tam kontrol, test edilebilir; Clerk/Auth.js adaptörü sonradan takılabilir |

Uygulama: scrypt(N=16384) parola; oturum = rastgele 256-bit token (yalnız SHA-256 hash'i DB'de),
httpOnly+SameSite=Lax çerez, 30 gün, çok-cihaz (oturum başına satır); forgot/reset token akışı
(e-posta servisi yoksa dürüst devToken modu); tüm uçlar `guarded()` ile DB-yapılandırma
hatasında 503 döner.

## Bağlam

Hesap; çok-cihaz senkron, SRS geçmişi, ödeme ve B2B'nin kilididir. Ancak harici auth
sağlayıcısına (Clerk/Auth0) sıkı bağlanmak, yerel geliştirmeyi ve taşınabilirliği zorlaştırır.

## Karar

- **Sağlayıcı-agnostik `AuthProvider` arayüzü** (`signIn`, `signUp`, `session`, `signOut`).
- **Yerel/varsayılan:** güvenli **credentials** sağlayıcısı (Argon2/scrypt hash, HTTP-only
  cookie session) — harici servis gerektirmez, tam çalışır ve testlenebilir.
- **Üretim seçeneği:** aynı arayüzün Clerk/Auth.js adaptörü (ENV varsa).
- Parola/PII güvenliği ROADMAP Faz 30'a tabidir.

## Sonuçlar

- (+) Gün-1'den çalışan gerçek auth; sağlayıcı sonradan takılır.
- (−) Kendi credentials akışını güvenli tutma sorumluluğu → Faz 30 sertleştirmesi + testler.
