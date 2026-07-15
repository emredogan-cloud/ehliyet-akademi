# ADR-010 — AI platformu: sunucu-taraflı grounded yanıtlama + halüsinasyon kapısı

**Statü:** Kabul edildi · Sprint 5 (2026-07-15) · ROADMAP Faz 22/35

## Bağlam

AI koç, platformun KENDİ eğitim içeriğine dayanmalı; halüsinasyon (uydurma) yasak. Gerçek model
(Anthropic) opsiyonel olmalı; anahtar yoksa akış durmamalı. Güvenlik-kritik içerikte (ilk yardım)
model asla serbest üretim yapmamalı.

## Karar

**Sunucu-taraflı grounded boru hattı** (`lib/server/ai.ts` + `POST /api/ai/ask`):

1. **Retrieval** — soru, önek-duyarlı belirteç eşleşmesiyle (Türkçe morfoloji) dersler + soru
   bankasına eşlenir.
2. **Halüsinasyon kapısı** — eşleşme YOKSA model çağrılmaz; dürüstçe reddedilir (`grounded=false`).
3. **Model soyutlaması** — `MockModel` (varsayılan, deterministik, bağlamdan kompozisyon, 0 halüsinasyon)
   | `AnthropicModel` (ENV: `ANTHROPIC_API_KEY`, retry'li). API anahtarı **yalnız sunucuda**.
4. **Prompt orkestrasyonu** — sistem promptu modeli YALNIZCA verilen bağlama zorlar ("bağlamda yoksa
   uydurma").
5. **Fallback** — gerçek model hatası → mock kompozisyonuna düşülür (asla kırılmaz). İstemci de
   sunucu hatasında yerel mock'a düşer (çevrimdışı-dayanıklı).

**Değerlendirme veri kümesi** (`lib/server/ai-eval.ts`): konu-içi (grounded olmalı) + konu-dışı
(reddedilmeli) vakalar + `runEval` skorlayıcı. Birim testi mock'ta **%100 doğruluk** bekler —
halüsinasyon önlemenin kanıtı.

## Sonuçlar

- (+) Anahtar olmadan tam çalışır (mock, 0 halüsinasyon); ENV ile gerçek model tek adım.
- (+) Reddetme kapısı + eval kümesi = ölçülebilir halüsinasyon önleme.
- (−) Retrieval basit heuristik (önek eşleşmesi); ölçekte gömme (embedding) tabanlı geri-getirmeye
  yükseltilebilir (aynı arayüz).
