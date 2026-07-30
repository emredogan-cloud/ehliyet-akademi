#!/usr/bin/env bash
# Beta sprint — CİHAZ SEÇİM POLİTİKASI (tek kaynak).
#
# Doğrulama sırasında cihazlar USB'den düşüyor; her seferinde elle kimlik yazmak, "hangi cihazda
# test edildi" sorusunu belirsizleştirir. Politika burada kodlanır ve her çağrıda YENİDEN
# değerlendirilir:
#
#   1. Birincil:  Redmi Note 11R   (model 22095RA98C)
#   2. Yedek:     Huawei           (model ANE_LX1 / ANE-LX1)
#   3. Son çare:  bağlı EN SON Redmi (ör. Redmi 8A / M1908C3JGG)
#
# Kullanım:
#   DEV=$(tool/pick_device.sh) || exit 1
#   flutter run -d "$DEV"
#
# Çıktı: yalnız seri numarası (stdout). Tanılama satırları stderr'e gider ki komut ikamesi
# (`$(...)`) kirlenmesin.
set -uo pipefail

# `adb devices -l` bazen ilk çağrıda sunucuyu başlatır ve liste boş döner; bir kez daha bakılır.
#
# Ayraç SEKME DEĞİL BOŞLUKTUR (`adb devices -l` hizalama için boşluk kullanır); `\tdevice` kalıbı
# hiçbir şey bulmuyordu. İkinci alanın tam olarak `device` olmasına bakılır — böylece `offline`,
# `unauthorized` ve `no permissions` durumundaki cihazlar da dışarıda kalır.
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
  echo "HATA: bağlı Android cihaz yok. USB kablosunu ve 'USB hata ayıklama' iznini kontrol et." >&2
  exit 1
fi

pick_by_model() {
  local pattern="$1"
  echo "$devices" | grep -iE "model:$pattern" | head -1 | awk '{print $1}'
}

serial=""
label=""

# "Bağlı" YETMEZ, "kurulum kabul ediyor" gerekir.
#
# Huawei ANE-LX1 bu makinede `adb` listesinde `device` olarak görünüyor ama `adb install`
# CEVAP VERMEDEN askıda kalıyor: EMUI, USB üzerinden kurulumu ekranda elle onaylatıyor ve o onay
# betikten verilemiyor. Sessizce o cihazı seçmek, doğrulama adımını on dakika boyunca kilitliyordu.
#
# Bu yüzden aday cihaz, ucuz ve yan etkisiz bir paket yöneticisi çağrısıyla sınanır. Cevap
# vermezse aday DÜŞER ve politika bir sonrakine geçer.
usable() {
  local s="$1"
  timeout 12 adb -s "$s" shell pm get-install-location >/dev/null 2>&1
}

try_device() {
  local pattern="$1" name="$2"
  local candidate
  candidate="$(pick_by_model "$pattern")"
  [[ -z "$candidate" ]] && return 1
  if ! usable "$candidate"; then
    echo "atlandı: $candidate ($name) — adb komutlarına cevap vermiyor" >&2
    return 1
  fi
  serial="$candidate"
  label="$name"
  return 0
}

try_device '22095RA98C' 'Redmi Note 11R (birincil)' ||
  try_device 'ANE.?LX1' 'Huawei ANE-LX1 (yedek — birincil bağlı değil)' || true

if [[ -z "$serial" ]]; then
  # Son çare: herhangi bir Redmi/Xiaomi. `M1908C3JGG` = Redmi 8A; kalıp geniş tutuldu ki
  # başka bir Redmi takıldığında da bulunsun.
  try_device 'M19|Redmi|22[0-9]{4}' 'Redmi (son çare — birincil ve yedek kullanılamıyor)' || true
fi

if [[ -z "$serial" ]]; then
  # Politikadaki hiçbir cihaz kullanılamıyor ama BİR cihaz var: dürüst davran, onu kullan ve söyle.
  serial="$(echo "$devices" | head -1 | awk '{print $1}')"
  label="politika dışı cihaz — hangi cihaz olduğu raporda belirtilmeli"
fi

echo "cihaz: $serial — $label" >&2
echo "$serial"
