# ADR-005 — Tipli içerik + özgün soru bankası modeli

**Statü:** Kabul edildi (ROADMAP Faz 9–12, C.4, E.6)

## Bağlam

v1'de içerik = kod (`data.js`). Ölçekte (yüzlerce ders, binlerce soru, 4 teorik ders +
pratik) bu sürdürülemez. Ayrıca **hukuki kısıt bağlayıcı:** hiçbir rakip içeriği kopyalanamaz.

## Karar

- **`@ea/content-schema`**: Zod ile tipli şemalar (Lesson, Section, Badge, Question, Quiz,
  ExamBlueprint, ErrorRow, Checklist). Derleme-zamanı + çalışma-zamanı doğrulama.
- **`@ea/question-bank`**: **özgün**, kategorize (ders/konu/zorluk/tip), açıklamalı sorular;
  kaynak = resmî MEB/ODSGM müfredatı + mevzuat; **kendi ifademizle**; uzman-onay alanı
  (`reviewedBy`) şemada zorunlu tutulur.
- İçerik başta tipli TS/JSON; ölçekte CMS'e (Faz 24, Payload) taşınır — şema aynı kalır.
- **Bilgi sınıflandırma rozetleri** (Resmî Kural/Sınav Uygulaması/Eğitmen Tavsiyesi/En İyi
  Uygulama/Güvenlik İpucu) v1'den korunur.

## Sonuçlar

- (+) Hukuken temiz, doğrulanabilir, ölçeklenebilir içerik.
- (+) CMS geçişi şema-uyumlu → sürtünmesiz.
- (−) Özgün üretim emek-yoğun (ROADMAP "uzun kutup") → erken/paralel başlar.
