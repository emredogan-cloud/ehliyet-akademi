# PROGRAM 2 · FAZ 9 RAPORU — Büyük İçerik Genişletmesi

_Ehliyet Akademi · 2026-07-16 · Durum: **TAMAMLANDI**_

## Özet

Soru bankası **534 → 1534 özgün soruya** çıktı (hedef 1500+ ✓). Dört dalga halinde,
her dalga kalite-denetimli ve tekrarsız üretildi; ayrıca büyüyen bankanın iki yan etkisi
(AI grounding hassasiyeti + istemci paket boyutu) tespit edilip düzeltildi.

## Ölçek

| Konu            | Faz 9 öncesi | Sonra    |
| --------------- | ------------ | -------- |
| Trafik ve Çevre | 123          | **368**  |
| İlk Yardım      | 104          | **299**  |
| Araç Tekniği    | 103          | **298**  |
| Trafik Adabı    | 102          | **272**  |
| Direksiyon      | 102          | **297**  |
| **Toplam**      | **534**      | **1534** |

Kimlik çakışması **sıfır**; her soru tam metaverili (whyWrong/objective/tags/difficulty/badge/
review:'draft'/sourceRef).

## Dalgalar (her biri: yaz → wire → tekrar-tara → test → commit → CI)

- **Dalga A** (+275, ids 401+): şerit disiplini, ceza puanı, duraklama mesafeleri, triyaj
  temelleri, egzoz duman renkleri, fermuar kuralı, eğimde park…
- **Dalga B** (+275, ids 501+): ışıklı cihazlar, scooter, OED/TYD oranları, ESP/ASR,
  aquaplaning, savrulma karşı manevra, direksiyon devri olgunluğu…
- **Dalga C** (+275, ids 601+): dört-yol öncelik senaryoları, kask çıkarma kuralı, arıza
  teşhis senaryoları (akü/termostat/balata ayrımı), araç anonimliği psikolojisi…
- **Dalga D** (+175, ids 701+): işaret tanıma + çevre, ilk yardım tanımları, sistem özetleri
  - gösterge okuma, değer kavramları, temel beceriler + sürüş öncesi.

## Kalite güvencesi — özgünlük denetimi

Yeni araç: `scripts/content/similarity-check.mjs` (TR-normalize token-kümesi Jaccard). Denetim:

- **Mevcut bankada 9 şüpheli çift** bulundu (biri BİREBİR duplikeydi); **8 gerçek duplike
  yerinde farklı gerçeklere dönüştürüldü** (levha vs genel sınır, sollanan araç davranışı,
  ticari 0.00 promil, eski yağ, koma öncesi solunum kontrolü, açık kırıkta kanama önceliği…).
- Her dalga sonrası yeniden tarandı; final tarama **1530 kök, 0 şüpheli çift**.

## Büyümenin yan etkilerinin düzeltilmesi (dürüst kayıt)

1. **AI grounding hassasiyeti** — Dalga A/B bankayı büyütünce "otel" kelimesi trafik bilgi
   içeriğinde geçmeye başladı ve "Bana tatil için otel öner" gibi konu-dışı bir istek yanlışça
   grounded oldu (halüsinasyon-önleme eval'i %90'a düştü → CI kırmızı). Düzeltme: grounding
   eşiği sertleştirildi — tek kısa rastlantısal token artık grounding yapmaz (≥2 token VEYA
   ≥6 harfli özgül token gerekir). 10/10 eval geri döndü; kapı artık banka büyümesine dayanıklı.
2. **İstemci paket boyutu** — 1534 soruluk banka `/deneme-sinavi` (561 kB) ve `/calisma-plani`
   (584 kB) İlk Yük JS'ini şişirdi. Düzeltme: `ssr:false` dinamik import ile kod-bölme
   (`ExamSimulatorLazy` + `CalismaPlaniContent`) → ikisi de **104 kB**; banka ayrı parça olarak
   iskelet gösterilerek yüklenir. Sınav akışı gerçek tarayıcıda uçtan uca doğrulandı.

## Operasyonel not

Dört içerik ajanı, üretim ortamının oturum kullanım limitine (reset 19:50) takılıp yarıda
kesildi; limit sıfırlanınca yeniden çalıştırıldı. Bu, dış bir kaynak sınırıdır — üretilen
içeriğin kalitesini etkilemedi.

## Doğrulama

| Kapı       | Sonuç                                                                                                    |
| ---------- | -------------------------------------------------------------------------------------------------------- |
| Birim      | **218** (paketler + web); banka kapısı ≥1500 + konu bazlı ≥340/270/270/250/270 + ≥1400 zenginleştirilmiş |
| e2e        | **61** yeşil (CI'da E2E dahil tüm işler yeşil)                                                           |
| Özgünlük   | similarity-check: 1530 kök, **0 şüpheli çift**                                                           |
| CI         | **Yeşil** (`a748a05`)                                                                                    |
| Performans | /deneme-sinavi & /calisma-plani İlk Yük JS 561/584 → **104 kB**                                          |
| Production | Vitrin "1534 özgün soru" canlı; sınav akışı gerçek tarayıcıda çalışıyor; 0 konsol hatası                 |

## Sonraki adım

Program 2'nin **dokuz fazının tamamı bitti**. Kapanış: `PROGRAM_2_REPORT.md` (tüm fazların
roadmap'e karşı gözden geçirimi). Program 3 BAŞLATILMAYACAK.
