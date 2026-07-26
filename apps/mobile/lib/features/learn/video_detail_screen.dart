import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart' show VideoPlayer, VideoPlayerController;

import '../../core/network/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/video_content.dart';
import '../../domain/video/captions.dart';
import '../../domain/video/playback.dart';
import '../../domain/video/video_progress.dart';
import 'videos_screen.dart' show absoluteMediaUrl;
import 'widgets/content_scope.dart';
import 'widgets/playback_controller.dart';
import 'widgets/video_controls.dart';

/// Evolution Faz E11 — video detayı: özel oynatıcı, bölümler, altyazı, yer imleri, kaldığı yerden
/// devam ve "izlendi" durumu.
class VideoDetailScreen extends StatelessWidget {
  const VideoDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      builder: (context, snapshot) {
        final video = snapshot.videoById(id);
        if (video == null || !video.isAvailable) {
          return Scaffold(
            appBar: AppBar(),
            body: const AppEmptyState(emoji: '🎬', title: 'Video bulunamadı'),
          );
        }
        return _VideoBody(video: video);
      },
    );
  }
}

class _VideoBody extends ConsumerStatefulWidget {
  const _VideoBody({required this.video});
  final VideoContent video;

  @override
  ConsumerState<_VideoBody> createState() => _VideoBodyState();
}

class _VideoBodyState extends ConsumerState<_VideoBody> with WidgetsBindingObserver {
  VideoPlayerController? _raw;
  VideoPlayerPlayback? _playback;
  bool _ready = false;
  bool _failed = false;

  List<Caption> _captions = const [];
  bool _captionsOn = false;

  /// Kaldığı yerden devam teklifi — bir kez gösterilir.
  Duration _resumeAt = Duration.zero;
  bool _resumeHandled = false;

  Timer? _saveTimer;

  VideoContent get _v => widget.video;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final saved = ref.read(videoProgressProvider).of(_v.id);
    final raw = VideoPlayerController.networkUrl(Uri.parse(absoluteMediaUrl(_v.src!)));
    _raw = raw;
    try {
      await raw.initialize();
      if (!mounted) return;
      _playback = VideoPlayerPlayback(raw);
      _resumeAt = resumePosition(saved: saved.position, duration: raw.value.duration);
      setState(() => _ready = true);

      // Konumu saniyede bir kaydet — her karede yazmak gereksiz disk trafiği olurdu.
      _saveTimer = Timer.periodic(const Duration(seconds: 1), (_) => _persist());
      raw.addListener(_onTick);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
    unawaited(_loadCaptions());
  }

  Future<void> _loadCaptions() async {
    final path = _v.captions;
    if (path == null || path.isEmpty) return;
    try {
      final res = await ref
          .read(dioProvider)
          .get<String>(
            absoluteMediaUrl(path),
            options: Options(responseType: ResponseType.plain),
          );
      final parsed = parseVtt(res.data ?? '');
      if (mounted && parsed.isNotEmpty) setState(() => _captions = parsed);
    } catch (_) {
      // Altyazı alınamazsa oynatma yine çalışır — sessiz düşmek doğru davranış.
    }
  }

  void _onTick() {
    final c = _raw;
    if (c == null || !mounted) return;
    if (isWatched(position: c.value.position, duration: c.value.duration)) {
      unawaited(ref.read(videoProgressProvider.notifier).markWatched(_v.id));
    }
  }

  void _persist() {
    final c = _raw;
    if (c == null || !c.value.isInitialized) return;
    unawaited(
      ref
          .read(videoProgressProvider.notifier)
          .savePosition(_v.id, position: c.value.position, duration: c.value.duration),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Arka plana giderken duraklat + kaydet: kullanıcı geri döndüğünde ses devam ediyor olmasın.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _raw?.pause();
      _persist();
    }
  }

  @override
  void dispose() {
    _persist();
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _raw?.removeListener(_onTick);
    _playback?.dispose();
    _raw?.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    final c = _raw;
    if (c == null) return;
    unawaited(ref.read(videoProgressProvider.notifier).toggleBookmarkAt(_v.id, c.value.position));
  }

  Future<void> _openFullscreen() async {
    final playback = _playback;
    if (playback == null) return;
    // KÖK gezginle it: iç içe (shell) gezgin kullanılırsa uygulamanın alt sekme çubuğu tam
    // ekranda GÖRÜNMEYE devam ediyor — cihazda ölçüldü. Tam ekran gerçekten tam ekran olmalı.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenPlayer(
          playback: playback,
          video: _v,
          captions: _captions,
          captionsEnabled: _captionsOn,
          bookmarks: ref.read(videoProgressProvider).of(_v.id).bookmarks,
          onToggleCaptions: () => setState(() => _captionsOn = !_captionsOn),
          onToggleBookmark: _toggleBookmark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = ref.watch(videoProgressProvider).of(_v.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(_v.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (state.watched)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s3),
              child: Icon(Icons.check_circle_rounded, color: p.green, size: 20),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            _playerBox(p, state),
            if (_resumeAt > Duration.zero && !_resumeHandled) ...[
              const SizedBox(height: AppSpacing.s3),
              _ResumeBanner(
                at: _resumeAt,
                onResume: () {
                  _raw?.seekTo(_resumeAt);
                  setState(() => _resumeHandled = true);
                },
                onRestart: () => setState(() => _resumeHandled = true),
              ),
            ],
            const SizedBox(height: AppSpacing.s4),
            Text(_v.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s2),
            Text(_v.description, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14)),
            if (_v.chapters.isNotEmpty) ...[
              const SectionTitle('Bölümler'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _v.chapters.length; i++)
                      _ChapterRow(
                        chapter: _v.chapters[i],
                        isLast: i == _v.chapters.length - 1,
                        isActive:
                            _ready && activeChapterIndex(_v.chapters, _raw!.value.position) == i,
                        onTap: _ready
                            ? () => _raw!.seekTo(
                                Duration(milliseconds: (_v.chapters[i].t * 1000).round()),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ],
            if (state.bookmarks.isNotEmpty) ...[
              const SectionTitle('Yer imlerin'),
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  for (final ms in state.bookmarks)
                    ActionChip(
                      avatar: Icon(Icons.bookmark_rounded, size: 16, color: p.yellow),
                      label: Text(formatDuration(Duration(milliseconds: ms))),
                      onPressed: _ready ? () => _raw!.seekTo(Duration(milliseconds: ms)) : null,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _playerBox(AppPalette p, VideoState state) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface3,
            borderRadius: BorderRadius.circular(AppRadii.base),
          ),
          alignment: Alignment.center,
          child: Text('Video yüklenemedi', style: TextStyle(color: p.text3)),
        ),
      );
    }
    if (!_ready || _playback == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface3,
            borderRadius: BorderRadius.circular(AppRadii.base),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.base),
      child: AspectRatio(
        aspectRatio: _playback!.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_raw!),
            VideoControls(
              controller: _playback!,
              chapters: _v.chapters,
              captions: _captions,
              bookmarks: state.bookmarks,
              captionsEnabled: _captionsOn,
              onToggleCaptions: () => setState(() => _captionsOn = !_captionsOn),
              onToggleBookmark: _toggleBookmark,
              onFullscreen: _openFullscreen,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tam ekran oynatıcı — YATAY yönelime geçer, çıkışta dikeye döner.
///
/// AYNI `PlaybackController` örneği kullanılır → tam ekrana geçerken video baştan başlamaz;
/// konum, hız ve arabellek korunur.
class _FullscreenPlayer extends StatefulWidget {
  const _FullscreenPlayer({
    required this.playback,
    required this.video,
    required this.captions,
    required this.captionsEnabled,
    required this.bookmarks,
    required this.onToggleCaptions,
    required this.onToggleBookmark,
  });

  final VideoPlayerPlayback playback;
  final VideoContent video;
  final List<Caption> captions;
  final bool captionsEnabled;
  final List<int> bookmarks;
  final VoidCallback onToggleCaptions;
  final VoidCallback onToggleBookmark;

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  late bool _captionsOn = widget.captionsEnabled;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: widget.playback.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(widget.playback.raw),
              VideoControls(
                controller: widget.playback,
                chapters: widget.video.chapters,
                captions: widget.captions,
                bookmarks: widget.bookmarks,
                captionsEnabled: _captionsOn,
                isFullscreen: true,
                onToggleCaptions: () {
                  widget.onToggleCaptions();
                  setState(() => _captionsOn = !_captionsOn);
                },
                onToggleBookmark: widget.onToggleBookmark,
                onFullscreen: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.at, required this.onResume, required this.onRestart});
  final Duration at;
  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: p.primary, size: 20),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              '${formatDuration(at)} konumunda kalmıştın.',
              style: TextStyle(color: p.text2, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRestart, child: const Text('Baştan')),
          FilledButton(onPressed: onResume, child: const Text('Devam et')),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.isLast,
    required this.onTap,
    this.isActive = false,
  });

  final VideoChapter chapter;
  final bool isLast;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          color: isActive ? p.primary050 : null,
          border: isLast ? null : Border(bottom: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.play_arrow_rounded : Icons.play_circle_outline_rounded,
              size: 18,
              color: p.primary,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                chapter.title,
                style: TextStyle(
                  color: isActive ? p.primary : p.text2,
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              formatDuration(Duration(milliseconds: (chapter.t * 1000).round())),
              style: TextStyle(
                color: p.text3,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
