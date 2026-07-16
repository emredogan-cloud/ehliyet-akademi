# ADR-014 — Vizyon Modeli & Kamera-Destekli Öğrenme Mimarisi (Program 2 · Faz 5)

**Statü:** Önerildi (mimari tasarım — uygulama kullanıcı onayına bağlı) · 2026-07-16

## Bağlam

Faz 5, gelecekteki vizyon-model entegrasyonunun mimarisini ister: kullanıcının çektiği bir
gösterge/işaret fotoğrafını tanıyıp ilgili eğitim içeriğine bağlamak ("bu lamba ne?").
Platform ilkeleri: gizlilik-öncelikli (KVKK), grounded AI (halüsinasyon kapısı), CSP sıkı.

## Karar (tasarım)

1. **Varsayılan: görüntü cihazda kalır.** Kamera erişimi yalnız kullanıcı hareketiyle
   (getUserMedia / dosya seçimi); önizleme ve kırpma istemcide.
2. **Açık rıza + geçicilik**: sunucuya gönderim ancak tek-tek açık onayla; görüntü işlendikten
   sonra SAKLANMAZ (retention=0); günlüklere görüntü/başlık yazılmaz.
3. **Grounded sınıflandırma**: vizyon modeli çıktısı serbest metin olarak KULLANILMAZ.
   Model çıktısı yalnız **katalog kimliğine** eşlenir (işaret kataloğu + ikaz lambası kataloğu);
   eşleşme eşiği altında "tanıyamadım" denir — Faz 5'te kurulan `matchVisuals`/görsel-kimlik
   disiplininin devamı.
4. **Model soyutlaması**: `VisionProvider` arayüzü (ADR-010 `ModelProvider` deseni);
   `MockVisionProvider` (test) + sağlayıcı adaptörü (Anthropic vision / yerel model) ENV ile.
5. **Aşamalar**: (a) dosya-yükle + tanı (kamera yok), (b) canlı kamera, (c) cihaz-içi model
   (WebGPU/ONNX) — tamamen çevrimdışı hedefi.

## Sonuçlar

- Uygulama bu ADR'yi hayata geçirmeden önce kullanıcı onayı + sağlayıcı seçimi gerekir
  (maliyet + KVKK değerlendirmesi). Faz 5'te kod tarafında zemin hazır:
  görsel kimlik eşleme (`lib/visual-match.ts`) ve görsel kart arayüzü mevcut.
