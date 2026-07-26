/// Evolution Faz E11 — WebVTT altyazı çözümleyici (SAF, ağdan ve platformdan bağımsız).
///
/// NEDEN KENDİMİZ ÇÖZÜMLÜYORUZ: `video_player` altyazıyı `ClosedCaptionFile` ile alır ama bizim
/// altyazı anahtarını (aç/kapa) ve transkript vurgusunu aynı veriden beslememiz gerekiyor.
/// Çözümleyici saf olduğu için doğrudan test edilir — platform kanalı gerekmez.
library;

/// Tek bir altyazı ipucu.
class Caption {
  const Caption({required this.start, required this.end, required this.text});

  final Duration start;
  final Duration end;
  final String text;

  bool containsPosition(Duration p) => p >= start && p < end;

  @override
  String toString() => 'Caption(${start.inMilliseconds}-${end.inMilliseconds}: $text)';

  @override
  bool operator ==(Object other) =>
      other is Caption && other.start == start && other.end == end && other.text == text;

  @override
  int get hashCode => Object.hash(start, end, text);
}

/// `mm:ss.mmm` veya `hh:mm:ss.mmm` biçimini süreye çevirir. Geçersizse `null`.
///
/// WebVTT saat alanını İSTEĞE BAĞLI bırakır; iki biçimi de kabul etmek zorundayız.
Duration? parseVttTimestamp(String raw) {
  final value = raw.trim();
  // Ayırıcı olarak nokta da virgül de görülür (SRT'den dönüştürülmüş dosyalar).
  final m = RegExp(r'^(?:(\d+):)?(\d{1,2}):(\d{1,2})[.,](\d{1,3})$').firstMatch(value);
  if (m == null) return null;
  final hours = int.tryParse(m.group(1) ?? '0') ?? 0;
  final minutes = int.tryParse(m.group(2)!) ?? 0;
  final seconds = int.tryParse(m.group(3)!) ?? 0;
  // '5' → 500 ms, '05' → 50 ms, '005' → 5 ms olacak şekilde sağdan tamamla.
  final fraction = m.group(4)!.padRight(3, '0');
  final millis = int.tryParse(fraction) ?? 0;
  if (minutes > 59 || seconds > 59) return null;
  return Duration(hours: hours, minutes: minutes, seconds: seconds, milliseconds: millis);
}

/// WebVTT metnini ipuçlarına çevirir.
///
/// DAYANIKLILIK: başlık satırı (`WEBVTT`), `NOTE` blokları, ipucu kimlikleri, `-->` sonrası
/// yerleşim ayarları (`align:start` vb.) ve satır sonu farkları (`\r\n`) yok sayılır. Bozuk bir
/// blok bütün dosyayı düşürmez — yalnız o blok atlanır.
List<Caption> parseVtt(String source) {
  final out = <Caption>[];
  final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trim();
    i++;
    if (line.isEmpty || line == 'WEBVTT' || line.startsWith('WEBVTT ')) continue;
    if (line.startsWith('NOTE')) {
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        i++;
      }
      continue;
    }

    // Zaman satırı bu satır olabilir; değilse bir sonraki satır olabilir (ipucu kimliği durumu).
    var timing = line;
    if (!timing.contains('-->')) {
      if (i >= lines.length) break;
      timing = lines[i].trim();
      if (!timing.contains('-->')) continue; // ne kimlik ne zaman → atla
      i++;
    }

    final parts = timing.split('-->');
    if (parts.length != 2) continue;
    final start = parseVttTimestamp(parts[0]);
    // Bitişten sonra yerleşim ayarları gelebilir: "00:02.200 align:start position:10%"
    final endToken = parts[1].trim().split(RegExp(r'\s+')).first;
    final end = parseVttTimestamp(endToken);
    if (start == null || end == null || end <= start) {
      // Bozuk zaman satırı → bu bloğun metnini de yut, sonraki bloğa geç.
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        i++;
      }
      continue;
    }

    final buffer = <String>[];
    while (i < lines.length && lines[i].trim().isNotEmpty) {
      buffer.add(lines[i].trim());
      i++;
    }
    final text = buffer.join('\n').trim();
    if (text.isNotEmpty) out.add(Caption(start: start, end: end, text: text));
  }

  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

/// `position` anında gösterilecek ipucu; yoksa `null`.
Caption? captionAt(List<Caption> captions, Duration position) {
  for (final c in captions) {
    if (c.containsPosition(position)) return c;
  }
  return null;
}
