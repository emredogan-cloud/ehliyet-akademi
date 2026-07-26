import 'package:ehliyet_akademi/domain/content/video_content.dart';
import 'package:ehliyet_akademi/domain/video/captions.dart';
import 'package:ehliyet_akademi/domain/video/playback.dart';
import 'package:ehliyet_akademi/domain/video/video_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evolution Faz E11 — oynatıcının SAF mantığı.
///
/// Bu katman `video_player`'a ve platform kanalına dokunmaz; bu yüzden her kural burada
/// doğrudan doğrulanır ve widget/cihaz testleri yalnız görünürlükle ilgilenir.
void main() {
  group('WebVTT zaman damgası', () {
    test('mm:ss.mmm ve hh:mm:ss.mmm', () {
      expect(parseVttTimestamp('00:02.200'), const Duration(seconds: 2, milliseconds: 200));
      expect(parseVttTimestamp('01:00:05.000'), const Duration(hours: 1, seconds: 5));
    });

    test('kesir SAĞDAN tamamlanır', () {
      expect(parseVttTimestamp('00:01.5'), const Duration(seconds: 1, milliseconds: 500));
      expect(parseVttTimestamp('00:01.05'), const Duration(seconds: 1, milliseconds: 50));
      expect(parseVttTimestamp('00:01.005'), const Duration(seconds: 1, milliseconds: 5));
    });

    test('SRT virgülü de kabul edilir', () {
      expect(parseVttTimestamp('00:02,200'), const Duration(seconds: 2, milliseconds: 200));
    });

    test('geçersiz değerler null', () {
      expect(parseVttTimestamp('abc'), isNull);
      expect(parseVttTimestamp('00:99.000'), isNull); // saniye 59'u aşamaz
      expect(parseVttTimestamp(''), isNull);
    });
  });

  group('WebVTT çözümleme', () {
    const sample = '''
WEBVTT

00:00.000 --> 00:02.200
Kavşağa yaklaşırken yavaşla.

00:02.200 --> 00:05.000
Sağdan gelen araç var.
''';

    test('gerçek dosya biçimini çözümler', () {
      final cues = parseVtt(sample);
      expect(cues, hasLength(2));
      expect(cues.first.text, 'Kavşağa yaklaşırken yavaşla.');
      expect(cues.first.start, Duration.zero);
      expect(cues.first.end, const Duration(seconds: 2, milliseconds: 200));
    });

    test('ipucu KİMLİĞİ olan blokları da çözümler', () {
      final cues = parseVtt('WEBVTT\n\ncue-1\n00:00.000 --> 00:01.000\nMerhaba\n');
      expect(cues, hasLength(1));
      expect(cues.single.text, 'Merhaba');
    });

    test('NOTE blokları ve yerleşim ayarları yok sayılır', () {
      final cues = parseVtt(
        'WEBVTT\n\nNOTE bu bir yorumdur\nikinci satırı da atlanmalı\n\n'
        '00:00.000 --> 00:01.000 align:start position:10%\nMetin\n',
      );
      expect(cues, hasLength(1));
      expect(cues.single.text, 'Metin');
    });

    test('CRLF satır sonları', () {
      final cues = parseVtt('WEBVTT\r\n\r\n00:00.000 --> 00:01.000\r\nSatır\r\n');
      expect(cues, hasLength(1));
    });

    test('çok satırlı ipucu birleştirilir', () {
      final cues = parseVtt('WEBVTT\n\n00:00.000 --> 00:01.000\nBirinci\nİkinci\n');
      expect(cues.single.text, 'Birinci\nİkinci');
    });

    test('BOZUK blok bütün dosyayı düşürmez', () {
      final cues = parseVtt(
        'WEBVTT\n\n00:00.000 --> BOZUK\nAtlanmalı\n\n00:02.000 --> 00:03.000\nGeçerli\n',
      );
      expect(cues, hasLength(1));
      expect(cues.single.text, 'Geçerli');
    });

    test('bitiş başlangıçtan önceyse blok atılır', () {
      final cues = parseVtt('WEBVTT\n\n00:05.000 --> 00:02.000\nTers\n');
      expect(cues, isEmpty);
    });

    test('boş girdi boş liste', () {
      expect(parseVtt(''), isEmpty);
      expect(parseVtt('WEBVTT\n'), isEmpty);
    });

    test('konuma göre ipucu bulunur', () {
      final cues = parseVtt(sample);
      expect(captionAt(cues, const Duration(seconds: 1))?.text, 'Kavşağa yaklaşırken yavaşla.');
      expect(captionAt(cues, const Duration(seconds: 3))?.text, 'Sağdan gelen araç var.');
      // Aralık dışı → null (son ipucunun bitişinden sonrası)
      expect(captionAt(cues, const Duration(seconds: 9)), isNull);
    });
  });

  group('süre biçimlendirme', () {
    test('dakika:saniye', () {
      expect(formatDuration(const Duration(seconds: 9)), '0:09');
      expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
    });

    test('saat varsa saat gösterilir', () {
      expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });

    test('negatif süre sıfırlanır', () {
      expect(formatDuration(const Duration(seconds: -5)), '0:00');
    });
  });

  group('kaldığı yerden devam', () {
    const total = Duration(minutes: 10);

    test('çok kısa izleme kaldığı yer SAYILMAZ', () {
      expect(resumePosition(saved: const Duration(seconds: 3), duration: total), Duration.zero);
      expect(shouldOfferResume(saved: const Duration(seconds: 3), duration: total), isFalse);
    });

    test('anlamlı ilerleme devam ettirilir', () {
      expect(
        resumePosition(saved: const Duration(minutes: 4), duration: total),
        const Duration(minutes: 4),
      );
      expect(shouldOfferResume(saved: const Duration(minutes: 4), duration: total), isTrue);
    });

    test('neredeyse bitmiş video BAŞTAN başlar', () {
      // %95 ve üstü → bitmiş say.
      expect(
        resumePosition(saved: const Duration(minutes: 9, seconds: 40), duration: total),
        Duration.zero,
      );
    });

    test('süre bilinmiyorsa kayıtlı konum korunur', () {
      expect(
        resumePosition(saved: const Duration(minutes: 2), duration: Duration.zero),
        const Duration(minutes: 2),
      );
    });
  });

  group('izlendi durumu', () {
    test('%90 ve üstü izlendi', () {
      expect(
        isWatched(position: const Duration(seconds: 90), duration: const Duration(seconds: 100)),
        isTrue,
      );
      expect(
        isWatched(position: const Duration(seconds: 89), duration: const Duration(seconds: 100)),
        isFalse,
      );
    });

    test('süre sıfırsa izlendi sayılmaz (sıfıra bölme yok)', () {
      expect(isWatched(position: const Duration(seconds: 5), duration: Duration.zero), isFalse);
    });
  });

  group('bölümler', () {
    const chapters = [
      VideoChapter(t: 0, title: 'Başla'),
      VideoChapter(t: 2.7, title: 'Orta'),
      VideoChapter(t: 7.4, title: 'Bitir'),
    ];

    test('konuma göre etkin bölüm', () {
      expect(activeChapterIndex(chapters, Duration.zero), 0);
      expect(activeChapterIndex(chapters, const Duration(seconds: 3)), 1);
      expect(activeChapterIndex(chapters, const Duration(seconds: 8)), 2);
    });

    test('bölüm yoksa -1', () {
      expect(activeChapterIndex(const [], const Duration(seconds: 3)), -1);
    });

    test('sırasız veri doğru eşlenir', () {
      const unsorted = [
        VideoChapter(t: 7.4, title: 'Son'),
        VideoChapter(t: 0, title: 'İlk'),
        VideoChapter(t: 2.7, title: 'Orta'),
      ];
      // 3. saniyede "Orta" etkin olmalı — listedeki 2. öğe.
      expect(activeChapterIndex(unsorted, const Duration(seconds: 3)), 2);
    });

    test('işaret konumları 0..1 arasında ve uçlar hariç', () {
      final marks = chapterMarkerFractions(chapters, const Duration(seconds: 10));
      // t=0 dışarıda (çubuğun soluna yapışırdı); 2.7 ve 7.4 içeride.
      expect(marks, hasLength(2));
      expect(marks.first, closeTo(0.27, 0.001));
      expect(marks.last, closeTo(0.74, 0.001));
    });

    test('süre bilinmiyorsa işaret yok', () {
      expect(chapterMarkerFractions(chapters, Duration.zero), isEmpty);
    });
  });

  group('ilerleme ve arabellek oranı', () {
    test('ilerleme oranı sınırlanır', () {
      expect(progressFraction(const Duration(seconds: 5), const Duration(seconds: 10)), 0.5);
      expect(progressFraction(const Duration(seconds: 50), const Duration(seconds: 10)), 1.0);
      expect(progressFraction(const Duration(seconds: 5), Duration.zero), 0);
    });

    test('arabellek en uzak uçtan hesaplanır', () {
      final ranges = [const DurationRange(0, 2000), const DurationRange(4000, 6000)];
      expect(bufferedFraction(ranges, const Duration(seconds: 10)), 0.6);
    });

    test('arabellek yoksa 0', () {
      expect(bufferedFraction(const [], const Duration(seconds: 10)), 0);
    });
  });

  group('atlama ve hız', () {
    test('atlama sınırların dışına taşmaz', () {
      expect(
        seekBy(const Duration(seconds: 3), -kSkipStep, const Duration(seconds: 10)),
        Duration.zero,
      );
      expect(
        seekBy(const Duration(seconds: 8), kSkipStep, const Duration(seconds: 10)),
        const Duration(seconds: 10),
      );
    });

    test('hız döngüsü başa sarar', () {
      expect(nextSpeed(1.0), 1.25);
      expect(nextSpeed(2.0), 0.75);
      // Listede olmayan bir değer güvenli varsayılana düşer.
      expect(nextSpeed(3.0), 1.0);
    });
  });

  group('yer imleri', () {
    test('ekler ve sıralı tutar', () {
      var b = toggleBookmark(const [], 5000);
      b = toggleBookmark(b, 1000);
      expect(b, [1000, 5000]);
    });

    test('aynı ana yakın ikinci imleme KALDIRIR (tolerans)', () {
      final b = toggleBookmark(const [5000], 5400);
      expect(b, isEmpty);
    });

    test('tolerans dışındaki im ayrı kalır', () {
      final b = toggleBookmark(const [5000], 7000);
      expect(b, [5000, 7000]);
    });
  });

  group('durum kalıcılığı (JSON)', () {
    test('gidiş-dönüş', () {
      const s = VideoState(positionMs: 4200, durationMs: 9000, watched: true, bookmarks: [1000]);
      final back = VideoState.fromJson(s.toJson());
      expect(back.positionMs, 4200);
      expect(back.durationMs, 9000);
      expect(back.watched, isTrue);
      expect(back.bookmarks, [1000]);
    });

    test('eksik alanlar güvenli varsayılana düşer', () {
      final s = VideoState.fromJson(const {});
      expect(s.positionMs, 0);
      expect(s.watched, isFalse);
      expect(s.bookmarks, isEmpty);
    });

    test('izlenen video sayısı', () {
      const states = VideoStates({
        'a': VideoState(watched: true),
        'b': VideoState(watched: false),
        'c': VideoState(watched: true),
      });
      expect(states.watchedCount, 2);
      // Bilinmeyen kimlik boş durum verir (null döndürmez).
      expect(states.of('yok').positionMs, 0);
    });
  });
}
