import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart' as vp;

import '../../../domain/video/playback.dart' as pb;

/// Evolution Faz E11 — oynatıcı soyutlaması.
///
/// NEDEN VAR: `VideoPlayerController` platform kanalına bağlıdır; widget testlerinde
/// örneklenemez. Uygulamadaki yerleşik desen (arayüz + uygulama; bkz. `CommunityApi`/`SocialApi`)
/// buraya da uygulandı → **denetim yüzeyinin tamamı sahte bir oynatıcıyla test edilebilir**,
/// gerçek ekran ise ince bir adaptörle `video_player`'a bağlanır.
abstract class PlaybackController implements Listenable {
  bool get isInitialized;
  bool get isPlaying;
  bool get isBuffering;

  /// Oynatma bittiğinde `position == duration` olur ve `isPlaying` false döner.
  bool get isCompleted;

  Duration get position;
  Duration get duration;
  double get speed;
  double get aspectRatio;

  /// Arabellek aralıkları — saf katmanın taşıyıcısıyla (platform türü değil).
  List<pb.DurationRange> get buffered;

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);
}

/// Gerçek `video_player` adaptörü. Yalnız çeviri yapar — kural içermez.
class VideoPlayerPlayback extends ChangeNotifier implements PlaybackController {
  VideoPlayerPlayback(this._c) {
    _c.addListener(_forward);
  }

  final vp.VideoPlayerController _c;
  vp.VideoPlayerController get raw => _c;

  void _forward() => notifyListeners();

  @override
  bool get isInitialized => _c.value.isInitialized;
  @override
  bool get isPlaying => _c.value.isPlaying;
  @override
  bool get isBuffering => _c.value.isBuffering;
  @override
  bool get isCompleted => _c.value.isCompleted;
  @override
  Duration get position => _c.value.position;
  @override
  Duration get duration => _c.value.duration;
  @override
  double get speed => _c.value.playbackSpeed;
  @override
  double get aspectRatio =>
      _c.value.isInitialized && _c.value.aspectRatio > 0 ? _c.value.aspectRatio : 16 / 9;

  @override
  List<pb.DurationRange> get buffered => _c.value.buffered
      .map((r) => pb.DurationRange(r.start.inMilliseconds, r.end.inMilliseconds))
      .toList(growable: false);

  @override
  Future<void> play() => _c.play();
  @override
  Future<void> pause() => _c.pause();
  @override
  Future<void> seekTo(Duration position) => _c.seekTo(position);
  @override
  Future<void> setSpeed(double speed) => _c.setPlaybackSpeed(speed);

  @override
  void dispose() {
    _c.removeListener(_forward);
    super.dispose();
  }
}
