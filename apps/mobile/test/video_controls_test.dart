import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/domain/content/video_content.dart';
import 'package:ehliyet_akademi/domain/video/captions.dart';
import 'package:ehliyet_akademi/domain/video/playback.dart' as pb;
import 'package:ehliyet_akademi/features/learn/widgets/playback_controller.dart';
import 'package:ehliyet_akademi/features/learn/widgets/video_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evolution Faz E11 — denetim yüzeyi testleri.
///
/// `PlaybackController` soyutlaması sayesinde platform kanalı GEREKMEZ: sahte oynatıcı bütün
/// denetimleri sürer ve çağrıların gerçekten yapıldığı doğrulanır.
class FakePlayback extends ChangeNotifier implements PlaybackController {
  FakePlayback({
    this.duration = const Duration(seconds: 100),
    Duration position = Duration.zero,
    bool playing = false,
  }) : _position = position,
       _playing = playing;

  @override
  final Duration duration;
  Duration _position;
  bool _playing;
  double _speed = 1.0;

  final List<Duration> seeks = [];
  int playCount = 0;
  int pauseCount = 0;

  @override
  bool get isInitialized => true;
  @override
  bool get isPlaying => _playing;
  @override
  bool get isBuffering => false;
  @override
  bool get isCompleted => _position >= duration && !_playing;
  @override
  Duration get position => _position;
  @override
  double get speed => _speed;
  @override
  double get aspectRatio => 16 / 9;
  @override
  List<pb.DurationRange> get buffered => [pb.DurationRange(0, duration.inMilliseconds ~/ 2)];

  @override
  Future<void> play() async {
    playCount++;
    _playing = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _playing = false;
    notifyListeners();
  }

  @override
  Future<void> seekTo(Duration p) async {
    seeks.add(p);
    _position = p;
    notifyListeners();
  }

  @override
  Future<void> setSpeed(double s) async {
    _speed = s;
    notifyListeners();
  }
}

void main() {
  const chapters = [
    VideoChapter(t: 0, title: 'Yaklaş ve hizalan'),
    VideoChapter(t: 30, title: 'Geri ve sağa kır'),
    VideoChapter(t: 70, title: 'Ortala ve bitir'),
  ];

  Future<void> pumpControls(
    WidgetTester tester,
    FakePlayback playback, {
    List<Caption> captions = const [],
    bool captionsEnabled = false,
    List<int> bookmarks = const [],
    VoidCallback? onToggleCaptions,
    VoidCallback? onToggleBookmark,
    VoidCallback? onFullscreen,
    bool isFullscreen = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 225,
            child: VideoControls(
              controller: playback,
              chapters: chapters,
              captions: captions,
              captionsEnabled: captionsEnabled,
              bookmarks: bookmarks,
              onToggleCaptions: onToggleCaptions,
              onToggleBookmark: onToggleBookmark,
              onFullscreen: onFullscreen,
              isFullscreen: isFullscreen,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('oynat / duraklat', () {
    testWidgets('duraklatılmışken oynat düğmesi görünür ve oynatır', (tester) async {
      final p = FakePlayback();
      await pumpControls(tester, p);

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();

      expect(p.playCount, 1);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('oynarken duraklatır', (tester) async {
      final p = FakePlayback(playing: true);
      await pumpControls(tester, p);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();
      expect(p.pauseCount, 1);
    });

    testWidgets('BİTMİŞ videoda yeniden oynat simgesi çıkar ve başa sarar', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 100));
      await pumpControls(tester, p);

      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.replay_rounded));
      await tester.pump();

      // Önce başa sarmalı, sonra oynatmalı — aksi hâlde "oynat"a basınca hiçbir şey olmazdı.
      expect(p.seeks.first, Duration.zero);
      expect(p.playCount, 1);
    });
  });

  group('atlama', () {
    testWidgets('10 sn ileri ve geri', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 40));
      await pumpControls(tester, p);

      await tester.tap(find.byIcon(Icons.forward_10_rounded));
      await tester.pump();
      expect(p.seeks.last, const Duration(seconds: 50));

      await tester.tap(find.byIcon(Icons.replay_10_rounded));
      await tester.pump();
      expect(p.seeks.last, const Duration(seconds: 40));
    });

    testWidgets('sınırların dışına TAŞMAZ', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 3));
      await pumpControls(tester, p);

      await tester.tap(find.byIcon(Icons.replay_10_rounded));
      await tester.pump();
      expect(p.seeks.last, Duration.zero);
    });
  });

  group('hız', () {
    testWidgets('döngüsel olarak değişir ve etiket güncellenir', (tester) async {
      final p = FakePlayback();
      await pumpControls(tester, p);

      expect(find.text('1x'), findsOneWidget);
      await tester.tap(find.text('1x'));
      await tester.pump();
      expect(p.speed, 1.25);
      expect(find.text('1.25x'), findsOneWidget);
    });
  });

  group('zaman çizgisi', () {
    testWidgets('konum ve süre yazılır', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 42));
      await pumpControls(tester, p);
      expect(find.text('0:42 / 1:40'), findsOneWidget);
    });

    testWidgets('çubuğa dokunmak o konuma sarar', (tester) async {
      final p = FakePlayback();
      await pumpControls(tester, p);

      final bar = find.bySemanticsLabel('Video zaman çizgisi');
      expect(bar, findsOneWidget);
      final rect = tester.getRect(bar);
      // Çubuğun ortasına dokun → yaklaşık yarısına sarmalı.
      await tester.tapAt(Offset(rect.center.dx, rect.center.dy));
      await tester.pump();

      expect(p.seeks, isNotEmpty);
      final ms = p.seeks.last.inMilliseconds;
      expect(ms, greaterThan(40000));
      expect(ms, lessThan(60000));
    });
  });

  group('altyazı', () {
    final cues = parseVtt('WEBVTT\n\n00:00.000 --> 00:05.000\nSağdan gelene yol ver.\n');

    testWidgets('kapalıyken metin GÖRÜNMEZ', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 2));
      await pumpControls(tester, p, captions: cues, onToggleCaptions: () {});
      expect(find.text('Sağdan gelene yol ver.'), findsNothing);
    });

    testWidgets('SATIR İÇİ oynatıcıda denetimler görünürken altyazı gizlenir', (tester) async {
      // Cihazda ölçüldü: 16:9 satır içi kutuya (~210 px) altyazı + alt çubuk birlikte sığmıyor.
      final p = FakePlayback(position: const Duration(seconds: 2), playing: true);
      await pumpControls(tester, p, captions: cues, captionsEnabled: true, onToggleCaptions: () {});
      expect(find.text('Sağdan gelene yol ver.'), findsNothing);

      // Denetimler kendiliğinden gizlenince altyazı yerini alır.
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Sağdan gelene yol ver.'), findsOneWidget);

      await p.pause();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('TAM EKRANDA altyazı ve denetimler BİRLİKTE görünür', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 2));
      await pumpControls(
        tester,
        p,
        captions: cues,
        captionsEnabled: true,
        isFullscreen: true,
        onToggleCaptions: () {},
      );
      expect(find.text('Sağdan gelene yol ver.'), findsOneWidget);
    });

    testWidgets('aralık dışındayken metin yok', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 30));
      await pumpControls(
        tester,
        p,
        captions: cues,
        captionsEnabled: true,
        isFullscreen: true,
        onToggleCaptions: () {},
      );
      expect(find.text('Sağdan gelene yol ver.'), findsNothing);
    });

    testWidgets('altyazı YOKSA düğme hiç çıkmaz', (tester) async {
      final p = FakePlayback();
      await pumpControls(tester, p, onToggleCaptions: () {});
      expect(find.byIcon(Icons.closed_caption_off_outlined), findsNothing);
      expect(find.byIcon(Icons.closed_caption_rounded), findsNothing);
    });

    testWidgets('düğme geri çağırıyı tetikler', (tester) async {
      var toggled = 0;
      final p = FakePlayback();
      await pumpControls(tester, p, captions: cues, onToggleCaptions: () => toggled++);

      await tester.tap(find.byIcon(Icons.closed_caption_off_outlined));
      await tester.pump();
      expect(toggled, 1);
    });
  });

  group('bölüm başlığı', () {
    testWidgets('o anki bölümün adı üstte yazar', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 45));
      await pumpControls(tester, p);
      expect(find.text('Geri ve sağa kır'), findsOneWidget);
    });

    testWidgets('konum ilerleyince başlık değişir', (tester) async {
      final p = FakePlayback(position: const Duration(seconds: 45));
      await pumpControls(tester, p);
      await p.seekTo(const Duration(seconds: 80));
      await tester.pump();
      expect(find.text('Ortala ve bitir'), findsOneWidget);
    });
  });

  group('yer imi ve tam ekran', () {
    testWidgets('yer imi düğmesi geri çağırıyı tetikler', (tester) async {
      var marked = 0;
      await pumpControls(tester, FakePlayback(), onToggleBookmark: () => marked++);

      await tester.tap(find.byIcon(Icons.bookmark_add_outlined));
      await tester.pump();
      expect(marked, 1);
    });

    testWidgets('tam ekran düğmesi durumuna göre simge değiştirir', (tester) async {
      await pumpControls(tester, FakePlayback(), onFullscreen: () {});
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);

      await pumpControls(tester, FakePlayback(), onFullscreen: () {}, isFullscreen: true);
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);
    });

    testWidgets('geri çağırı verilmezse düğmeler ÇIKMAZ', (tester) async {
      await pumpControls(tester, FakePlayback());
      expect(find.byIcon(Icons.fullscreen_rounded), findsNothing);
      expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);
    });
  });

  group('denetimlerin gizlenmesi', () {
    testWidgets('oynarken 3 sn sonra gizlenir, dokununca geri gelir', (tester) async {
      final p = FakePlayback(playing: true);
      await pumpControls(tester, p);

      // Başlangıçta görünür.
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);

      await tester.pump(const Duration(seconds: 4));
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);

      // Yüzeye dokun → geri gel.
      await tester.tapAt(tester.getCenter(find.byType(VideoControls)));
      await tester.pump();
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);

      // Sonraki zamanlayıcı testi bitirmeden temizlensin.
      await p.pause();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('DURAKLATILMIŞKEN gizlenmez', (tester) async {
      await pumpControls(tester, FakePlayback());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
    });
  });
}
