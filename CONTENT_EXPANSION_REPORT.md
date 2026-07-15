# CONTENT EXPANSION REPORT — Program 1

_Ehliyet Akademi · İçerik Genişletme · Tamamlanma raporu · 2026-07-16_

Amaç: en büyük **özgün** Türkçe B-sınıfı hazırlık platformuna doğru ölçeklenmek — asla telifli materyal kopyalamadan.

## Soru bankası — 100+/konu hedefi

Banka **398 → 534 özgün soruya** çıktı (+136). Her konu artık **100+**:

| Konu                  | Önce    | Sonra   | e-Sınav dağılımı |
| --------------------- | ------- | ------- | ---------------- |
| Trafik ve Çevre       | 123     | **123** | 23/50            |
| İlk Yardım            | 82      | **104** | 12/50            |
| Araç Tekniği (Motor)  | 79      | **103** | 9/50             |
| Trafik Adabı          | 56      | **102** | 6/50             |
| Direksiyon (Uygulama) | 58      | **102** | — (pratik)       |
| **Toplam**            | **398** | **534** |                  |

Bankadaki her soru, sınav-dağılımının (23/12/9/6) çok üstünde — bu, tekrarsız deneme ve konu-odaklı çalışma için gereken çeşitliliği sağlar.

### Her sorunun metaverisi

Batch-3'te eklenen 136 sorunun (ve bankadaki 470+ sorunun) her biri şunları taşır:

- **stem + 4 şık + doğru cevap** (answerIndex 0–3 arasında dengeli dağıtılmış)
- **explanation** — doğru cevabın _neden_ doğru olduğunu öğretir
- **whyWrong** — her çeldiricinin neden yanlış olduğu (öğretici geri bildirim)
- **objective** — sorunun ölçtüğü öğrenme kazanımı
- **tags** — konu etiketleri (arama/SRS/filtre)
- **difficulty** — kolay/orta/zor dağılımı
- **badge** — güvenlik/en-iyi-uygulama/resmî kural (uygun olduğunda)
- **review: 'draft'** + **sourceRef** — özgünlük + uzman onay izi

### Özgünlük & doğruluk güvenceleri

- **Kopya yok**: her batch, mevcut soruları okuyup **farklı açılardan** yazıldı; TÜM banka genelinde **kimlik çakışması sıfır** (doğrulandı).
- **Fail-fast şema**: banka yüklemede Zod ile parse edilir; bozuk/eksik içerik build'i kırar.
- **Tıbbi içerik ihtiyatlı**: ilk yardım soruları standart/konservatif; `review:'draft'` — uzman onayı bekliyor.
- **Teknik doğruluk**: motor/araç soruları doğrulandı (sıcak motorda radyatör kapağı açılmaz; ABS kilitlenmeyi önler; yumuşayan pedal = hidrolik sorunu; vb.).

## Teori & pratik dersleri — görsel zenginleştirme

19 dersin **tümü** metin-ağırlıklı olmaktan çıkarıldı; bölümlere görsel bloklar eklendi:

| Ders grubu                                     | Ders sayısı | Callout | Karşılaştırma tablosu |
| ---------------------------------------------- | ----------- | ------- | --------------------- |
| Çekirdek (trafik/ilk yardım/motor/kavşak/adab) | 5           | 6       | 5                     |
| Teorik Akademi                                 | 9           | 15      | 9                     |
| Sürüş (Direksiyon) Akademisi                   | 5           | 10      | 6                     |
| **Toplam**                                     | **19**      | **31**  | **20**                |

Örnekler:

- **Trafik İşaretlerine Giriş**: renk-şekil→anlam tablosu, DUR/Yol Ver karşılaştırması, "Sınavda ağır kusur" uyarı callout'u.
- **Hız & Takip Mesafesi**: yol türüne göre hız sınırı tablosu, ıslak/kuru mesafe karşılaştırması.
- **Direksiyon dersleri**: pedal düzeni tablosu, rampada kalkış adımları, paralel vs dik park, kör nokta güvenlik callout'ları.

Dersler zaten (önceki sprintlerden) kazanımlar, sık hatalar, hafıza teknikleri, sınav stratejisi, özet, tekrar kartları ve alıştırma sorularını içeriyordu; bu programda bunlara **görsel katman** eklendi — daha fazla metin değil, daha iyi **görselleştirme**.

## Doğrulama

- Banka test kapısı yükseltildi: **≥500 toplam, her konu ≥100, ≥470 zenginleştirilmiş metaveri** — geçiyor.
- `lessons-visual` testi: 19 dersin tümünde callout/karşılaştırma tablosu tutarlılığı (her satır = başlık sütunu sayısı) doğrulanır.
- **145 web birim + 10 soru bankası + 9 şema + diğer paket testleri + 49 e2e** — tümü yeşil.
- Production'da canlı: vitrin "534 özgün soru" gösteriyor; zenginleştirilmiş dersler doğru render ediliyor (0 konsol hatası).

## Dürüstlük notu

Sayılar gerçektir ve abartılmamıştır. İçerik resmî müfredattan **kendi ifademizle** üretilmiştir; ilk yardım ve tıbbi içerik **uzman onay sürecindedir** (`review:'draft'`). Uydurma öğrenci yorumu / başarı istatistiği yayımlanmamıştır.
