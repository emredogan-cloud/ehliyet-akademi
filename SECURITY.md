# Güvenlik Politikası

## Güvenlik açığı bildirimi

Bir güvenlik açığı bulduysanız lütfen **halka açık issue AÇMAYIN**.

- GitHub **Private Vulnerability Reporting** (Security → Report a vulnerability) kullanın,
- veya depo sahibine doğrudan ulaşın.

72 saat içinde ilk yanıt hedeflenir. Doğrulanan açıklar düzeltilene kadar
ayrıntı paylaşılmaz (coordinated disclosure).

## Kapsam

- `apps/*`, `packages/*` altındaki kod
- CI/CD workflow'ları
- Yayınlanmış üretim ortamı

## İlkeler (ROADMAP Faz 30)

- OWASP Top 10 azaltımları; sıkı CSP; CSRF/XSS koruması
- Sırlar yalnız ortam değişkeni/vault — repoda asla sır tutulmaz (CI'da gitleaks taraması)
- En-az-ayrıcalık (RBAC); denetim kayıtları
- KVKK/GDPR: veri-silme hakkı, onay yönetimi
