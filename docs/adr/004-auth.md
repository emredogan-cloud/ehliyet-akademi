# ADR-004 — Kimlik doğrulama soyutlaması

**Statü:** Kabul edildi (ROADMAP Faz 4 "auth = kilit taşı", Faz 30)

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
