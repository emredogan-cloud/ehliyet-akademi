# ASSET_PROMPT_LIBRARY.md — Doğrulama Raporu

_Program 3.1 · 2026-07-17 · Kaynak: `new-image/ASSET_PROMPT_LIBRARY.md` (1488 satır) ↔ 30 referans PNG_

## 1. PNG ↔ Prompt Eşleme Doğrulaması

Tüm 30 referans görsel (001–016, 018–031; `017` yok ve dokümanda doğru şekilde
belirtilmiş) tek tek incelendi ve kütüphanenin **Varlık Listesi** satırlarıyla
karşılaştırıldı.

| Kontrol                                   | Sonuç                                                                 |
| ----------------------------------------- | --------------------------------------------------------------------- |
| Görsel başına bölüm (`### 🎬 GÖRSEL nnn`) | ✅ 30/30 (006+007 ve 030+031 bilinçli birleşik)                       |
| Kabuk varlıkları `K-01…K-14`              | ✅ 14/14 tanımlı; görsel bölümleri `→K-xx` ile doğru referans veriyor |
| Varlık Listelerinde vadedilen kod sayısı  | 143 benzersiz `nnn-X` kodu                                            |
| Ayrı `####` bölümü olan kod               | 129                                                                   |
| Birleşik başlıkta tanımlanan kod          | 4 (013-E, 026-D, 028-C, 029-E — "&"'li başlıklarda promptu var)       |
| Bölümsüz kalan kod                        | 10 → **düzeltildi** (aşağıda)                                         |
| Master işaret üreticileri                 | ✅ MI-1…MI-5, 121 işareti `[SEMBOL]` parametresiyle kapsıyor          |

## 2. Eksik Varlıklar (bulundu → düzeltildi)

Şu 10 mikro-varlık listelerde vadedilmiş ama bölümü yoktu:
`003-A, 005-B, 006-C, 008-F, 010-C, 010-E, 012-D, 013-F, 015-C, 026-E`.

**Düzeltme:** Bölüm 2 sonuna kompakt **"🔩 MİKRO-VARLIKLAR (Ek)"** bloğu eklendi —
her öğe tek satırda, ait olduğu aile üreticisine (`→004-D`, `→K-09`, `→MI-2` …)
bağlanarak tanımlandı. 003-A'nın Unicode emoji olduğu (üretim gerektirmediği)
açıkça not edildi. Mevcut yapı ve biçim korundu; hiçbir mevcut bölüm yeniden yazılmadı.

## 3. Yinelenen Promptlar

Birebir yinelenen `Üretim Promptu` satırı **yok** (otomatik karşılaştırma temiz).
Aile benzerliği taşıyanlar (ör. 008-D/012-B/030-D bildirim kutuları) zaten
`Varyasyonlar` satırında birbirine bilinçli referans veriyor — sorun değil.

## 4. Kullanılmayan Promptlar

Kütüphanedeki her prompt bir referans PNG'deki görünür öğeden türetilmiş; PNG'lerde
karşılığı olmayan "hayalet" prompt bulunamadı. (UI-bileşeni kategorisindeki promptlar
konsept/teferruat amaçlıdır ve Bölüm 3 "Model Önerileri" bunu açıkça belirtir:
UI bileşenleri kodla çizilir, AI çıktısı konsepttir — depodaki uygulama da böyle yapıyor.)

## 5. Dosya Adı / Klasör Tutarlılığı

Kütüphane, üretim promptlarını kod sistemiyle (`K-xx`, `nnn-X`) tanımlar ancak
**çıktı dosya adı/klasör kuralı içermiyordu**. Depodaki gerçek adlandırma
`ASSET_GENERATION_PLAN.md`'dedir (ör. `landing-hero.webp → apps/web/public/assets/ui/`).

**Düzeltme:** "Bu Dokümanı Nasıl Kullanırsın?" bölümüne tek satırlık
**"Dosya adı & klasör"** maddesi eklendi; plan dosyasına ve
"dosya adı = manifest kimliği → otomatik bağlanır" kuralına işaret ediyor.

Mevcut üretilmiş varlıklar doğrulandı: `public/ui/*.png` (14 adet) plandaki
kimliklerle birebir eşleşiyor; WebP'e dönüştürülüp `public/assets/ui/`'ye kondu ve
arayüze bağlandı (bkz. commit `4665d43`).

## 6. Prompt Kalitesi Tutarlılığı

- Tüm promptlar Bölüm 0 stil DNA'sına ve standart son eke bağlı ✅
- Her varlıkta Kategori / Açıklama / Üretim Promptu / Negatif Prompt / Varyasyonlar
  beşlisi eksiksiz ✅ (mikro-varlıklar bilinçli tek satır)
- Politika tutarlı: marka/plaka/okunur metin yok, KVKK-dostu, Türk işaret standardı ✅
- ⭐ marka-kritik 13 varlık işaretli ve Bölüm 3 üretim iş akışında önceliklendirilmiş ✅

## 7. Sonuç

Kütüphane **geçerli ve üretim için kullanılabilir** durumda. Yapılan iki minimal
düzeltme: (1) 10 mikro-varlık için ek blok, (2) dosya adı/klasör yönlendirme maddesi.
Başka gerçek hata bulunamadı; yapı, numaralandırma ve stil dili tutarlı.
