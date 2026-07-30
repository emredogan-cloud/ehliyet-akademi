#!/usr/bin/env bash
# Beta sprint — APK'yı politikaya göre bir cihaza KUR ve hangi cihaza kurulduğunu bildir.
#
# `pick_device.sh` "hangi cihaz bağlı" sorusunu cevaplar; bu betik "hangi cihaz GERÇEKTEN kurulum
# kabul ediyor" sorusunu cevaplar. İkisi aynı şey değil ve fark pahalıya geldi:
#
#   Huawei ANE-LX1, `adb devices` listesinde `device` olarak görünüyor ve kabuk komutlarına
#   (`pm get-install-location` dâhil) cevap veriyor. Ama `adb install` CEVAPSIZ ASKIDA KALIYOR:
#   EMUI, USB üzerinden kurulumu telefon ekranında elle onaylatıyor. Betikten verilemeyen bir onay.
#   Kabuk sınaması bunu ayırt EDEMEZ — tek gerçek sınama, kurulumun kendisidir.
#
# Bu yüzden politika sırası ZAMAN SINIRLI kurulum denemeleriyle yürütülür. Bir cihaz sınırda
# cevap vermezse aday düşer ve sıradakine geçilir.
#
# Kullanım:
#   DEV=$(tool/deploy.sh build/app/outputs/flutter-apk/app-debug.apk) || exit 1
#   adb -s "$DEV" shell ...
#
# Çıktı: yalnız kurulumun BAŞARILI olduğu cihazın seri numarası (stdout).
set -uo pipefail

APK="${1:-build/app/outputs/flutter-apk/app-debug.apk}"
# Bir kurulum denemesine tanınan süre. Redmi 8A'da akışlı kurulum ~20 sn; 150 sn yavaş bir cihazda
# da bolca yeterli ve askıda kalan bir cihazı iki buçuk dakikada eler.
INSTALL_TIMEOUT="${INSTALL_TIMEOUT:-150}"

if [[ ! -f "$APK" ]]; then
  echo "HATA: APK bulunamadı: $APK" >&2
  exit 1
fi

list_devices() {
  adb devices -l 2>/dev/null | awk 'NR > 1 && $2 == "device" { print }'
}

devices="$(list_devices)"
if [[ -z "$devices" ]]; then
  adb start-server >/dev/null 2>&1
  sleep 1
  devices="$(list_devices)"
fi
if [[ -z "$devices" ]]; then
  echo "HATA: bağlı Android cihaz yok." >&2
  exit 1
fi

serial_of_model() {
  echo "$devices" | grep -iE "model:$1" | head -1 | awk '{print $1}'
}

# Politika sırası: birincil Redmi Note 11R → yedek Huawei → son çare herhangi bir Redmi.
declare -a PATTERNS=('22095RA98C' 'ANE.?LX1' 'M19|Redmi|22[0-9]{4}')
declare -a NAMES=(
  'Redmi Note 11R (birincil)'
  'Huawei ANE-LX1 (yedek)'
  'Redmi (son çare)'
)

tried=""
for i in "${!PATTERNS[@]}"; do
  candidate="$(serial_of_model "${PATTERNS[$i]}")"
  [[ -z "$candidate" ]] && continue
  # Aynı cihaz iki kalıba uyabilir (Redmi Note 11R hem birincil hem son çare kalıbına uyar).
  [[ " $tried " == *" $candidate "* ]] && continue
  tried="$tried $candidate"

  echo "deneniyor: $candidate — ${NAMES[$i]}" >&2
  if timeout "$INSTALL_TIMEOUT" adb -s "$candidate" install -r "$APK" >/dev/null 2>&1; then
    echo "kuruldu: $candidate — ${NAMES[$i]}" >&2
    echo "$candidate"
    exit 0
  fi
  echo "başarısız/askıda: $candidate — ${NAMES[$i]} → sıradaki cihaza geçiliyor" >&2
  # Askıda kalmış kurulum oturumunu temizle; bırakılırsa sonraki denemeyi de kilitler.
  timeout 10 adb -s "$candidate" shell pm install-abandon 2>/dev/null >/dev/null || true
done

echo "HATA: politikadaki hiçbir cihaza kurulum yapılamadı (denenen:$tried)." >&2
exit 1
