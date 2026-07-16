# PROGRAM 2 · FAZ 5 RAPORU — AI Görsel Öğrenme

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

AI koç **görsel-farkında** oldu ve platform **görsel quiz + görsel zayıf-deste** kazandı.
Halüsinasyon kapısı artık görsel kimlikleri de kapsıyor: AI yanıtlarına iliştirilen her görsel
YALNIZ kendi kataloglarımızdan (44 özgün işaret + premium bileşen fotoğrafları) gelir.

## Teslim edilenler

- **`lib/visual-match.ts`** — grounded görsel eşleyici: TR-normalize; kısa terimlerde tam
  kelime sınırı ("dur" ≠ "durum"); ad eşleşmesi > anahtar kelime önceliği; katı limit;
  "katalog dışı görsel asla dönmez" birim testle garanti.
- **AI Koç görsel kartları** — grounded yanıtların altında ilgili işaret (özgün SVG) /
  bileşen (premium foto) kartları; galerilere bağlantılı. Canlı örnek: "DUR levhasında ne
  yapılır?" → yanıt + **DUR ve Yol Ver kartları**.
- **`lib/visual-quiz.ts`** — saf tur üreticisi: havuz = 44 işaret + 32 fotoğraflı bileşen (76);
  çeldiriciler AYNI kategori/sistemden; enjekte edilebilir RNG (deterministik test).
- **`/gorsel-quiz`** — "Bu işaret/bileşen nedir?": SVG/foto sunum, 4 seçenek, doğru/yanlış
  geri bildirim + öğretici açıklama, skor; **zayıflar destesi** (`ea:visualQuiz:v1`):
  yanlışlar desteye düşer, "Zayıfları tekrar" modunda **iki kez doğru** bilinene dek sorulur.
- **ADR-014** — kamera/vizyon mimarisi (tasarım): görüntü cihazda kalır varsayılanı, tek-tek
  açık rıza, sıfır saklama, model çıktısı yalnız katalog-kimliğine eşlenir; `VisionProvider`
  soyutlaması; uygulama kullanıcı onayına bağlı. ADR indeksi 013–014 ile güncellendi.

## Doğrulama

| Kapı       | Sonuç                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Birim      | **169/169** (7 yeni: grounded garanti, kelime-sınırı, limit, tur bütünlüğü, zayıf-tekrar üretimi) |
| e2e        | **58/58** (2 yeni: quiz cevap→geri bildirim→sonraki; AI yanıtına DUR kartı)                       |
| CI         | **Yeşil** (`7298968`)                                                                             |
| Production | /gorsel-quiz canlı; AI görsel kartları canlı doğrulandı (DUR + Yol Ver); **0 konsol hatası**      |
| Gizlilik   | Zayıf deste yalnız localStorage; ADR-014 gizlilik-öncelikli tasarım                               |

## Düzeltilen sorunlar (dürüst kayıt)

1. İlk eşleyici sürümünde katalog sırası yüzünden "DUR" kartı limite giremiyordu → ad-eşleşmesi
   önceliği eklendi (test e2e'de yakaladı, yayına girmeden düzeltildi).
2. Kısa terim yanlış pozitifi ("dur" → "durum") tasarım aşamasında yakalanıp kelime-sınırı kuralıyla önlendi.
3. Bileşen turlarında foto-kimliği/bileşen-kimliği ayrımı netleştirildi (`itemId` + `assetId`).

## Sonraki faz

**Faz 6 — Trafik İşareti Genişletmesi**: 44 → ≥120 işaret; işaret detay sayfaları;
"karıştırılanlar" karşılaştırmaları; görsel quiz havuzu otomatik büyür.
