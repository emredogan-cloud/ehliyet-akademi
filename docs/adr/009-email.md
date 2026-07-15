# ADR-009 — E-posta platformu: Resend

**Statü:** Kabul edildi · Sprint 4 (2026-07-15) · ROADMAP Faz 22/30 destek servisleri

## Bağlam

Üretim için işlemsel e-posta gerekir: e-posta doğrulama, parola sıfırlama, satın alma onayı,
hoş geldin, destek. Sağlayıcı-agnostik, test edilebilir ve ENV-kapılı olmalı (anahtar yoksa akış durmamalı).

## Değerlendirme

| Aday       | Değerlendirme                                                                                           |
| ---------- | ------------------------------------------------------------------------------------------------------- |
| **Resend** | En iyi DX, basit REST API, Next.js dostu, cömert ücretsiz kademe, HTML+text kolay; hızlı entegrasyon    |
| Postmark   | Mükemmel teslim edilebilirlik (işlemsel odaklı) ama entegrasyon/fiyat Resend'e göre daha ağır başlangıç |
| Amazon SES | En ucuz ölçek ama kurulum karmaşık (domain/DKIM/kota), DX zayıf; küçük ürün için erken optimizasyon     |
| **Karar**  | **Resend** — bu aşamada en iyi DX/başlangıç dengesi; ölçekte SES/Postmark aynı arayüzle takılabilir     |

## Karar

Sağlayıcı-agnostik `EmailProvider` arayüzü (`apps/web/lib/server/email.ts`). Varsayılan
**ConsoleEmailProvider** (RESEND_API_KEY yoksa: e-posta gitmez, güvenli loglanır — dürüst dev modu).
ENV (`RESEND_API_KEY`, `EMAIL_FROM`) geldiğinde **ResendEmailProvider** (yeniden-denemeli `withRetry`).

Saf **şablonlar** (test edilebilir): `welcomeEmail`, `verificationEmail`, `passwordResetEmail`,
`purchaseConfirmationEmail`, `supportRequestEmail` — HTML + text; kullanıcı girişi HTML-escape edilir.

Bağlandığı akışlar: kayıt (hoş geldin + doğrulama), `POST /api/auth/verify` (doğrulama), forgot
(sıfırlama bağlantısı), satın alma (webhook + mock grant onayı), `POST /api/support` (destek kutusu).
E-posta servisi yokken doğrulama/sıfırlama **devToken** modunda çalışır (yanıt içinde token — dürüst).

## Sonuçlar

- (+) Anahtar olmadan tam akış test edilir; ENV ile gerçek gönderim tek adım.
- (+) Şablonlar saf → birim testli; retry ile geçici hatalara dayanıklı.
- (−) Gerçek gönderim için Resend hesabı + doğrulanmış gönderen alan adı (kullanıcı aksiyonu) gerekir.
