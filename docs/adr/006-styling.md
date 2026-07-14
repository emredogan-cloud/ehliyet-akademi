# ADR-006 — Stil: v1 tasarım tokenlarının taşınması

**Statü:** Kabul edildi (ROADMAP Faz 6)

## Bağlam

v1'in cilalı tasarım sistemi (CSS custom properties, koyu/açık tema, 60fps, erişilebilir
kontrast) korunmalı; ancak bileşenleşmeli ve tokenlaşmalı.

## Karar

- **`@ea/design-tokens`**: tek kaynak (primitive → semantic → component) → CSS değişkeni +
  TS tipi üretir. v1'in renk/uzay/tipografi/hareket değerleri buraya taşınır.
- **Stil yöntemi:** CSS Modules + global token katmanı (framework-hafif, RSC-uyumlu, sıfır
  runtime). Tailwind gerekli görülmedi (ROADMAP "gerekmedikçe Tailwind yok").
- Bileşenler `@ea/ui` altında; Storybook + görsel regresyon (Faz 6/20).

## Sonuçlar

- (+) v1 estetiği korunur, tema tek kaynaktan; RSC ile hızlı.
- (−) Tailwind ekosistem kısayolları yok → kendi ölçeklerimiz (kabul).
