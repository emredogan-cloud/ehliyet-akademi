#!/usr/bin/env bash
# Beta Faz 10 — BAŞARIM LABORATUVARI.
#
# Gerçek cihazda ölçer, sonucu bir taban çizgisiyle (`tool/perf-baseline.json`) karşılaştırır ve
# gerileme varsa HATA ile döner.
#
# ── Neden bir betik, elle ölçüm değil ────────────────────────────────────────────────────────────
#
# Başarım iddiaları ölçülmediğinde uydurma olur ("akıcı çalışıyor"), ölçüldüğünde de tek seferlik
# kalır. Asıl soru "hızlı mı" değil, **"dün olduğundan yavaş mı"**. O soruyu ancak aynı yöntemle
# tekrarlanan bir ölçüm cevaplayabilir.
#
# ── Neden RELEASE derlemesi ──────────────────────────────────────────────────────────────────────
#
# Hata ayıklama derlemesi JIT ile çalışır ve kat kat yavaştır; onunla ölçmek anlamsız sayılar
# üretir. Bu betik release APK ister ve yoksa üretir.
#
# ── Neden medyan, ortalama değil ─────────────────────────────────────────────────────────────────
#
# Telefon paylaşılan bir makinedir: arka planda bir güncelleme, bir bildirim ya da termal kısıtlama
# tek bir koşuyu iki katına çıkarabilir. Ortalama o tek koşudan bozulur; medyan bozulmaz.
#
# KULLANIM:
#   tool/perf_lab.sh                 # ölç ve taban çizgisiyle karşılaştır
#   tool/perf_lab.sh --update        # ölç ve tabanı GÜNCELLE (bilinçli bir karar)
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

PKG=com.ehliyetegitim.ehliyet_akademi
ACTIVITY="$PKG/.MainActivity"
BASELINE=tool/perf-baseline.json
RUNS=${RUNS:-5}
UPDATE=0
[[ "${1:-}" == "--update" ]] && UPDATE=1

# ── Cihaz ────────────────────────────────────────────────────────────────────────────────────────
DEV=$(tool/deploy.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 2>/dev/null | tail -1)
if [[ -z "$DEV" ]]; then
  echo "release APK bulunamadı, üretiliyor…" >&2
  flutter build apk --release --split-per-abi >/dev/null 2>&1 || {
    echo "HATA: release derlemesi başarısız." >&2
    exit 1
  }
  DEV=$(tool/deploy.sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 2>/dev/null | tail -1)
fi
[[ -z "$DEV" ]] && { echo "HATA: cihaz yok." >&2; exit 1; }

MODEL=$(adb -s "$DEV" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
ANDROID=$(adb -s "$DEV" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
echo "cihaz: $MODEL (Android $ANDROID)" >&2

med() { sort -n | awk '{a[NR]=$1} END {print (NR%2 ? a[(NR+1)/2] : int((a[NR/2]+a[NR/2+1])/2))}'; }

# ── Soğuk açılış ─────────────────────────────────────────────────────────────────────────────────
#
# `force-stop` + `pm clear`? HAYIR — `pm clear` veriyi de siler ve her koşuda tanıtım turu açılır;
# ölçülen şey uygulamanın açılışı değil, farklı bir ekranın açılışı olurdu. `force-stop` süreci
# öldürür: soğuk açılışın tanımı budur.
cold=()
for i in $(seq 1 "$RUNS"); do
  adb -s "$DEV" shell am force-stop "$PKG" >/dev/null 2>&1
  sleep 2
  t=$(adb -s "$DEV" shell am start -W -n "$ACTIVITY" 2>/dev/null | awk -F': ' '/^TotalTime/{print $2}' | tr -d '\r')
  [[ -n "$t" ]] && cold+=("$t")
  sleep 1
done
COLD=$(printf '%s\n' "${cold[@]}" | med)

# ── Sıcak açılış ─────────────────────────────────────────────────────────────────────────────────
#
# Süreç YAŞARKEN ana ekrana çıkıp geri dönmek. Kullanıcının gün içinde en çok yaşadığı açılış budur.
warm=()
for i in $(seq 1 "$RUNS"); do
  adb -s "$DEV" shell input keyevent KEYCODE_HOME >/dev/null 2>&1
  sleep 2
  t=$(adb -s "$DEV" shell am start -W -n "$ACTIVITY" 2>/dev/null | awk -F': ' '/^TotalTime/{print $2}' | tr -d '\r')
  [[ -n "$t" ]] && warm+=("$t")
  sleep 1
done
WARM=$(printf '%s\n' "${warm[@]}" | med)

# ── Kare ölçümü NEDEN BURADA YOK ─────────────────────────────────────────────────────────────────
#
# İlk yazımda bu betik `dumpsys gfxinfo` ile jank ve kare yüzdelikleri okuyordu. Cihazda çalıştırınca
# çıkan sayılar şunlardı:
#
#     Total frames rendered: 0
#     Janky frames: 0 (0.00%)
#     90th percentile: 4950ms
#
# `4950ms` bir kare süresi DEĞİL — histogramın son kovasının etiketi. Yani ölçüm hiçbir şey
# ölçmemişti ve rapora "kare p90 = 4950 ms" diye uydurma bir sayı girecekti.
#
# KÖK NEDEN: `gfxinfo`, Android'in kendi görünüm sistemini (HWUI) ölçer. Flutter HWUI'yi
# KULLANMAZ; kendi motoruyla doğrudan bir yüzeye çizer. Bu yüzden gfxinfo bir Flutter uygulaması
# için HER ZAMAN sıfır kare bildirir — cihaz ne kadar akıcı olursa olsun.
#
# Doğru kaynak uygulamanın İÇİDİR: `FrameTiming` (build + raster süresi). O ölçüm
# `integration_test/device_smoke_test.dart` içinde zaten var ve p10 eşiğiyle korunuyor:
#
#     flutter test integration_test -d <cihaz>
#
# Bu betik ölçemediğini ÖLÇÜYORMUŞ GİBİ YAPMAZ; kare metriği oraya bırakılmıştır.

# ── Uygulamayı GERÇEKTEN kullan ──────────────────────────────────────────────────────────────────
#
# Bellek, açılış ekranında ölçülürse gerçeği temsil etmez: listeler, görseller ve önbellekler henüz
# kurulmamıştır. Ölçümden önce birkaç kaydırma yapılır.
for _ in 1 2 3 4; do
  adb -s "$DEV" shell input swipe 540 1600 540 500 300 >/dev/null 2>&1
  sleep 1
done
sleep 2

# ── Bellek ───────────────────────────────────────────────────────────────────────────────────────
#
# PSS (Proportional Set Size) ölçülür: paylaşılan sayfaları orantılı sayan, "bu uygulama gerçekte
# ne kadar yer kaplıyor" sorusuna en yakın metrik.
PSS=$(adb -s "$DEV" shell dumpsys meminfo "$PKG" 2>/dev/null | awk '/TOTAL PSS:/{print $3; exit}' | tr -d '\r')
[[ -z "$PSS" ]] && PSS=$(adb -s "$DEV" shell dumpsys meminfo "$PKG" 2>/dev/null | awk '/^ *TOTAL/{print $2; exit}' | tr -d '\r')

# ── Artefakt boyutları ───────────────────────────────────────────────────────────────────────────
#
# AAB dosya boyutu KULLANICININ İNDİRDİĞİ boyut DEĞİLDİR: yarısı hata ayıklama sembolleri ve
# ProGuard haritasıdır, Play onları kullanıcıya göndermez. Gerçek indirme, ABI'ye bölünmüş APK'dır.
size_mb() { [[ -f "$1" ]] && echo $(( $(stat -c%s "$1") / 1048576 )) || echo 0; }
APK_ARM64=$(size_mb build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)
APK_ARM32=$(size_mb build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk)
AAB=$(size_mb build/app/outputs/bundle/release/app-release.aab)

RESULT=$(cat <<JSON
{
  "device": "$MODEL",
  "android": "$ANDROID",
  "runs": $RUNS,
  "coldStartMs": ${COLD:-0},
  "warmStartMs": ${WARM:-0},
  "memoryPssKb": ${PSS:-0},
  "apkArm64Mb": $APK_ARM64,
  "apkArm32Mb": $APK_ARM32,
  "aabMb": $AAB
}
JSON
)

echo "$RESULT"

if [[ $UPDATE -eq 1 ]]; then
  echo "$RESULT" > "$BASELINE"
  echo "taban çizgisi güncellendi: $BASELINE" >&2
  exit 0
fi

[[ ! -f "$BASELINE" ]] && {
  echo "taban çizgisi yok — ilk kez oluşturmak için: tool/perf_lab.sh --update" >&2
  exit 0
}

# ── Gerileme karşılaştırması ─────────────────────────────────────────────────────────────────────
#
# Eşikler GENİŞ (%30 / +5 puan) ve bu bilinçli: dar bir eşik, cihazın o anki yüküyle sürekli
# yanlış alarm verir ve laboratuvar hiç bakılmayan bir gürültü kaynağına dönüşür. Amaç küçük
# dalgalanmayı değil, GERÇEK gerilemeyi yakalamak.
python3 - "$BASELINE" <<PY
import json, sys
base = json.load(open(sys.argv[1]))
now = json.loads('''$RESULT''')
fails = []
def worse(key, label, pct=0.30, unit=''):
    b, n = base.get(key, 0), now.get(key, 0)
    if not b or not n: return
    if n > b * (1 + pct):
        fails.append(f"{label}: {b}{unit} → {n}{unit} (%{round((n/b-1)*100)} kötüleşme)")
    print(f"  {label:24} {b}{unit} → {n}{unit}")
worse('coldStartMs', 'soğuk açılış', unit=' ms')
worse('warmStartMs', 'sıcak açılış', unit=' ms')
worse('memoryPssKb', 'bellek (PSS)', unit=' KB')
# Boyut eşiği DAR (%10): açılış süresi cihazın yüküyle oynar, dosya boyutu oynamaz. Büyüme
# doğrudan bizim eklediğimiz bir şeydir ve fark edilmeden birikir.
worse('apkArm64Mb', 'APK arm64', pct=0.10, unit=' MB')

if fails:
    print('\nGERİLEME:', file=sys.stderr)
    for f in fails: print('  ✗', f, file=sys.stderr)
    sys.exit(1)
print('\ngerileme yok.')
PY
