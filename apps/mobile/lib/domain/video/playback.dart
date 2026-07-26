import '../content/video_content.dart';

/// Evolution Faz E11 — oynatma kuralları (SAF).
///
/// Buradaki her şey `video_player`'dan ve platformdan bağımsızdır; oynatıcı ekranı yalnız bu
/// kuralları uygular. Böylece "kaldığı yerden devam", "izlendi", bölüm eşleme ve biçimlendirme
/// doğrudan test edilir.

/// Kullanıcıya sunulan oynatma hızları. 2.0 üstü öğrenme için anlamsız olduğundan yok.
const List<double> kPlaybackSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

/// İleri/geri atlama adımı — sektör alışkanlığı 10 sn.
const Duration kSkipStep = Duration(seconds: 10);

/// Bu eşiğin ALTINDA kalan ilerleme "kaldığı yer" sayılmaz; baştan başlamak daha doğrudur.
const Duration kResumeMinimum = Duration(seconds: 5);

/// Videonun sonuna bu kadar yaklaşıldıysa "bitti" kabul edilir ve baştan başlatılır.
/// (Son saniyeler jenerik/kapanış olur; kullanıcıyı oraya geri koymak faydasızdır.)
const double kCompletionFraction = 0.95;

/// "İzlendi" sayılma eşiği — çalışma planına bu bayrak beslenir.
const double kWatchedFraction = 0.9;

/// Süreyi `m:ss` (veya saat varsa `h:mm:ss`) biçiminde yazar. Negatif değer sıfırlanır.
String formatDuration(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// 0..1 arası ilerleme oranı. `duration` sıfırsa 0 (sıfıra bölme yok).
double progressFraction(Duration position, Duration duration) {
  if (duration.inMilliseconds <= 0) return 0;
  final f = position.inMilliseconds / duration.inMilliseconds;
  return f.clamp(0.0, 1.0);
}

/// Videoya girildiğinde nereden başlanmalı?
///
/// KURAL: kayıtlı ilerleme [kResumeMinimum] altındaysa ya da neredeyse bitmişse BAŞTAN başla.
/// Aksi hâlde kaldığı yerden devam et. Böylece "3 saniye izleyip çıktım" durumunda kullanıcı
/// gereksiz bir "devam et" sorusuyla karşılaşmaz.
Duration resumePosition({required Duration saved, required Duration duration}) {
  if (saved <= kResumeMinimum) return Duration.zero;
  if (duration.inMilliseconds > 0 &&
      progressFraction(saved, duration) >= kCompletionFraction) {
    return Duration.zero;
  }
  return saved;
}

/// Kullanıcıya "kaldığın yerden devam edeyim mi?" diye sorulmalı mı?
bool shouldOfferResume({required Duration saved, required Duration duration}) =>
    resumePosition(saved: saved, duration: duration) > Duration.zero;

/// Video "izlendi" sayılır mı?
bool isWatched({required Duration position, required Duration duration}) =>
    duration.inMilliseconds > 0 && progressFraction(position, duration) >= kWatchedFraction;

/// `position`'ın hangi bölümde olduğunu döndürür (bölüm dizini); bölüm yoksa -1.
///
/// Bölümler zaman damgasına göre SIRALI varsayılmaz — burada sıralanır, çünkü içerik elle yazılıyor.
int activeChapterIndex(List<VideoChapter> chapters, Duration position) {
  if (chapters.isEmpty) return -1;
  final indexed = List<int>.generate(chapters.length, (i) => i)
    ..sort((a, b) => chapters[a].t.compareTo(chapters[b].t));
  var active = -1;
  for (final i in indexed) {
    final startMs = (chapters[i].t * 1000).round();
    if (position.inMilliseconds >= startMs) {
      active = i;
    } else {
      break;
    }
  }
  return active;
}

/// Bölüm işaretlerinin zaman çubuğundaki konumu (0..1). Süre bilinmiyorsa boş liste.
List<double> chapterMarkerFractions(List<VideoChapter> chapters, Duration duration) {
  if (duration.inMilliseconds <= 0) return const [];
  final out = <double>[];
  for (final c in chapters) {
    final f = (c.t * 1000) / duration.inMilliseconds;
    // 0 konumundaki işaret çubuğun soluna yapışır ve görünmez; ayrıca 1'i aşan veri korunmaz.
    if (f > 0 && f < 1) out.add(f);
  }
  return out;
}

/// Arabelleğe alınmış oran (0..1) — `video_player` aralık listesi verir, en uzak ucu alırız.
double bufferedFraction(List<DurationRange> ranges, Duration duration) {
  if (duration.inMilliseconds <= 0 || ranges.isEmpty) return 0;
  var maxEnd = 0;
  for (final r in ranges) {
    if (r.endMs > maxEnd) maxEnd = r.endMs;
  }
  return (maxEnd / duration.inMilliseconds).clamp(0.0, 1.0);
}

/// `video_player`'ın `DurationRange`'ine bağımlı kalmamak için küçük bir taşıyıcı.
/// (Saf katman platform paketini import ETMEZ; ekran katmanı dönüştürür.)
class DurationRange {
  const DurationRange(this.startMs, this.endMs);
  final int startMs;
  final int endMs;
}

/// Atlama sonucu konumu — sınırların dışına taşmaz.
Duration seekBy(Duration current, Duration delta, Duration duration) {
  final next = current + delta;
  if (next.isNegative) return Duration.zero;
  if (duration.inMilliseconds > 0 && next > duration) return duration;
  return next;
}

/// Hız listesinde bir sonraki hıza geç (sona gelince başa döner).
double nextSpeed(double current) {
  final i = kPlaybackSpeeds.indexOf(current);
  if (i < 0) return 1.0;
  return kPlaybackSpeeds[(i + 1) % kPlaybackSpeeds.length];
}
