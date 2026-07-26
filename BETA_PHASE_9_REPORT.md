# Beta Faz 9 — Akan (streaming) AI

**Durum:** ✅ Tamamlandı · **Kapsam:** `apps/web` (sunucu) + `apps/mobile` (istemci)

---

## A. Ölçüm — backend akış destekliyor mu?

Yol haritasının DoD'si bunu **ölçmeyi** şart koşuyordu. Ölçüldü:

| Soru                   | Cevap                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Bugün akış var mı?     | **Yok.** `apps/web/lib/server/ai.ts` Anthropic'e düz `fetch` atıyor, tam yanıtı bekliyor (`res.json()`).             |
| Gerçek akış mümkün mü? | **Evet.** Anthropic Messages API `stream: true` ile SSE döner; Next.js route'u `ReadableStream` ile yanıt verebilir. |
| Sahte akış gerekir mi? | **Hayır** — ve zaten yasak.                                                                                          |

Sonuç: **gerçek akış** uygulandı, aşamalı taklit değil.

---

## B. Sunucu — `/api/ai/ask/stream`

`answerGrounded` **değişmedi**; `/api/ai/ask` aynen çalışıyor. Akış ayrı bir üreteçtir
(`answerGroundedStream`) ve ayrı bir uçtan servis edilir.

**Olay sözleşmesi:** `meta` → `delta`\* → `done`

```json
{"type":"meta","grounded":true,"sources":["motor-005","ders:motor-temel"],
 "model":"anthropic","streamed":true}
{"type":"delta","text":"# Kırmızı Işıkta Ne Yapmalısınız?\n\nSorun"}
```

### Üç bilinçli karar

1. **`streamed` bayrağı sözleşmenin parçasıdır.** Yanıt tek parça geldiğinde `false` olur ve
   istemci bunu **olduğu gibi** çizer. Bu bayrak olmasaydı istemci ayırt edemez, "güzel görünsün"
   diye uydurma bir yazma animasyonu eklenirdi — yol haritasının açıkça yasakladığı şey.

2. **`meta`, ilk parça gelene kadar GÖNDERİLMEZ.** Akış daha ilk baytta patlarsa istemciye
   "akıyor" demiş olmayız. Bu, sahte akışın en sinsi biçimi olurdu: söz verilip tutulmaması.

3. **Halüsinasyon kapısı akıştan ÖNCE çalışır.** Retrieval ve bağlam kurulumu aynen korunur;
   akış yalnız modelin yanıtını taşır. Kapının anlamı akışta da bozulmaz.

### Tampon zorunluluğu

Ağ gövdesi satır sınırlarına saygı göstermez: tek bir SSE satırı iki okuma arasında bölünebilir.
Hem sunucu (Anthropic'i okurken) hem istemci (bizi okurken) tampon tutar ve yalnız **tam** olay
bloklarını işler. Bu yapılmazsa `JSON.parse` sessizce patlar ve akış ortada kesilir — testte
kasten ortadan bölünmüş parçalarla doğrulandı.

---

## C. İstemci — sahte animasyon yok

`CoachApi.askStream` SSE'yi olaylara çevirir; denetleyici parçaları **tek bir balonda** biriktirir.

- İlk parçada mesaj **eklenir**, sonrakilerde **yerine yazılır** — her parça için yeni balon
  eklenirse tek yanıt onlarca mesaja bölünürdü.
- `streamed: false` ise metin **tek seferde** yazılır; `streaming` bayrağı hiç açılmaz.
- Akış kurulamazsa (eski sunucu, 404, ağ) **sessizce** tek parça uca düşülür; yarım kalmış AI
  balonu geri alınır ki kullanıcı iki yanıt görmesin.
- "Koç düşünüyor…" balonu yalnız **henüz içerik yokken** durur. Akış başladıktan sonra büyüyen
  yanıtın kendisi göstergedir; ikisi birden çizilirse kullanıcı iki ayrı yanıt bekliyor sanır.

---

## D. Ölçülen sonuçlar

### Gerçek HTTP + gerçek model (yerel sunucu, canlı Anthropic anahtarı)

```
POST /api/ai/ask/stream
content-type: text/event-stream; charset=utf-8
cache-control: no-store, no-transform
x-accel-buffering: no

parça sayısı : 22
ilk parça    : 0,64 s
son parça    : 4,94 s
yayılım      : 4,31 s
```

**İlk metin 0,64 saniyede görünüyor; tam yanıt 4,94 saniyede tamamlanıyor.** Yani kullanıcı
eskiden 4,94 s boş ekrana bakarken artık **~7,7× daha erken** okumaya başlıyor. Yayılımın 4,31 s
olması, yanıtın gerçekten parça parça geldiğinin kanıtıdır — arabelleklenmiş olsaydı hepsi aynı
anda düşerdi.

### Cihaz (AYXSUKIVJVPZ7HPZ, Android 11)

| Senaryo                                       | Sonuç                                                                                              |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **Üretim** (akan uç henüz yayınlanmadı → 404) | Sessizce tek parça uca düşüldü, kullanıcı tam yanıt aldı, hata mesajı yok                          |
| **Yerel akan sunucu** (`adb reverse`)         | Sunucu günlüğü: **3 × `POST /api/ai/ask/stream`**, `POST /api/ai/ask` **0** — yedeğe hiç düşülmedi |

`RenderFlex overflowed` / `EXCEPTION CAUGHT`: **0**.

### Dürüst ölçüm sınırı

Cihazda **kademeli çizimin kendisi** ekran görüntüsüyle gösterilemedi: ilk parça geldiği anda
liste sonuna kaydırılıyor ve görünür alan tek örnekleme aralığında doluyor. Kademeli çizim,
denetleyici testinde **ara metinler doğrudan gözlenerek** doğrulandı
(`'Kırmızı '` → `'Kırmızı ışıkta '` → tam metin). Cihaz kanıtı, akan ucun kullanıldığı ve akışın
gerçekten parçalı olduğudur; "gözle görülen yazma efekti" iddiası ekran görüntüsüyle
**kanıtlanmadı** ve öyle sunulmuyor.

---

## E. Testler

| Katman  | Test                                | Ölçtüğü                                                                                                                                                                               |
| ------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sunucu  | `ai-stream.integration.test.ts` (7) | tek parçada `streamed:false` + **tek delta** · gerçek akışta çok delta · `meta` ilk olay · ilk baytta patlarsa "akıyor" denmez · ortada kopma · 400 · **mevcut uç bozulmadı**         |
| İstemci | `coach_stream_test.dart` (7)        | SSE çözümleyici · **olay ortasından bölünmüş** ağ parçaları · bozuk olay akışı öldürmez · parça parça tek balon · akmayanda **ara metin yok** · yedeğe düşüş · yarım balon bırakılmaz |

```
pnpm test        → 548 test (web)
flutter test     → 373 test (+7)
flutter analyze  → 0 · pnpm lint/typecheck/format/verify → temiz
```

---

## F. Testlerde düzeltilen iki hata (ikisi de bende)

1. **`controller.error()` kuyruğu boşaltır.** "Akış ortada kopar" taklidinde `enqueue` + hemen
   `error` yazmıştım; parça okuyucuya hiç ulaşmadı ve test aslında "akış hiç başlamadı" durumunu
   ölçüyordu. Gerçek kopmayı modellemek için parça **ilk çekimde**, hata **ikinci çekimde** verilir.
2. **Bildirim sayısı ≠ metin durumu.** "Sahte animasyon yok" testinde her durum bildirimini
   sayıyordum; `sending` kapanışı da bir bildirim üretiyor ama metni değiştirmiyor. Ölçü, görülen
   **farklı metinler** olarak düzeltildi.

Ayrıca `coach_test.dart`'taki `calls == 1` iddiası güncellendi: istemci artık önce akan ucu
dener, tek parça uç yalnız yedektir. Eski iddia yeni yolu değil, yalnız yedek yolu ölçerdi.

---

## G. Değişen dosyalar

| Dosya                                                    | Değişiklik                                                          |
| -------------------------------------------------------- | ------------------------------------------------------------------- |
| `apps/web/lib/server/ai.ts`                              | `answerGroundedStream` + Anthropic SSE okuyucu (mevcut kod korundu) |
| `apps/web/app/api/ai/ask/stream/route.ts`                | **yeni** — SSE ucu                                                  |
| `apps/web/lib/server/ai-stream.integration.test.ts`      | **yeni** — 7 test                                                   |
| `apps/mobile/lib/data/coach/coach_api.dart`              | `askStream` + `parseCoachSse` + olay tipleri                        |
| `apps/mobile/lib/domain/coach/coach_controller.dart`     | akış → tek balonda birikme · yedeğe düşüş · `streaming` bayrağı     |
| `apps/mobile/lib/features/coach/coach_screen.dart`       | "düşünüyor" balonu yalnız içerik yokken                             |
| `apps/mobile/test/coach_stream_test.dart`                | **yeni** — 7 test                                                   |
| `apps/mobile/test/helpers.dart` · `test/coach_test.dart` | sahte API akışı destekler; iddia güncellendi                        |
