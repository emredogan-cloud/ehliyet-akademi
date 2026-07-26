import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../domain/content/video_content.dart';
import '../../../domain/video/captions.dart';
import '../../../domain/video/playback.dart';
import 'playback_controller.dart';

/// Evolution Faz E11 — özel oynatıcı denetimleri.
///
/// KÜTÜPHANE KARARI (raporda gerekçesiyle): `video_player` korunup denetim katmanı ELLE yazıldı.
/// Hazır bir oynatıcı kabuğu (chewie vb.) kendi görsel dilini getirir ve tasarım token'larımızın
/// dışına çıkardı; burada her piksel `context.palette` üzerinden gelir.
///
/// TEST EDİLEBİLİRLİK: bu widget [PlaybackController] soyutlamasını alır → widget testleri sahte
/// bir oynatıcıyla bütün denetimleri sürer, platform kanalı gerekmez.
class VideoControls extends StatefulWidget {
  const VideoControls({
    super.key,
    required this.controller,
    required this.chapters,
    this.captions = const [],
    this.bookmarks = const [],
    this.captionsEnabled = false,
    this.onToggleCaptions,
    this.onToggleBookmark,
    this.onFullscreen,
    this.isFullscreen = false,
    this.showChapterTitle = true,
  });

  final PlaybackController controller;
  final List<VideoChapter> chapters;
  final List<Caption> captions;

  /// Milisaniye cinsinden yer imleri — zaman çubuğunda ayrı renkle gösterilir.
  final List<int> bookmarks;

  final bool captionsEnabled;
  final VoidCallback? onToggleCaptions;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onFullscreen;
  final bool isFullscreen;
  final bool showChapterTitle;

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  /// Denetimler oynatma sırasında kendiliğinden gizlenir; dokununca geri gelir.
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
    _restartHideTimer();
  }

  @override
  void didUpdateWidget(covariant VideoControls old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTick);
      widget.controller.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    // Duraklatılmışken gizleme — kullanıcı bir şey yapmak istiyordur.
    if (!widget.controller.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  void _poke() {
    setState(() => _visible = true);
    _restartHideTimer();
  }

  Future<void> _togglePlay() async {
    final c = widget.controller;
    if (c.isPlaying) {
      await c.pause();
    } else {
      // Sona gelmişse baştan başlat — "oynat"a basınca hiçbir şey olmaması kafa karıştırır.
      if (c.isCompleted) await c.seekTo(Duration.zero);
      await c.play();
    }
    _poke();
  }

  Future<void> _skip(Duration delta) async {
    final c = widget.controller;
    await c.seekTo(seekBy(c.position, delta, c.duration));
    _poke();
  }

  Future<void> _cycleSpeed() async {
    await widget.controller.setSpeed(nextSpeed(widget.controller.speed));
    _poke();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = context.palette;
    final caption = widget.captionsEnabled ? captionAt(widget.captions, c.position) : null;

    // Satır içi 16:9 oynatıcı ~210 px yüksekliktedir; üst çubuk + orta düğmeler + altyazı + alt
    // çubuk oraya SIĞMAZ (cihazda ölçüldü: alt çubuk kutunun dışına taşıyordu). Bu yüzden satır
    // içi oynatıcıda altyazı, denetimler GÖRÜNÜRKEN gösterilmez — denetimler 3 sn sonra
    // kendiliğinden gizlenince altyazı yerini alır. Tam ekranda ikisi birlikte rahatça sığar,
    // orada altyazı alt çubuğun hemen üstünde akışın içinde durur.
    final captionInColumn = caption != null && widget.isFullscreen && _visible;
    final captionOverlaid = caption != null && !_visible;

    return Semantics(
      container: true,
      label: 'Video oynatıcı denetimleri',
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dokunma alanı: denetimleri göster/gizle.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _visible ? setState(() => _visible = false) : _poke(),
            ),
          ),

          // Altyazı, denetimler GİZLİYKEN serbest yerleşimle en altta durur. Denetimler
          // görünürken ise akışın içine (alt çubuğun hemen üstüne) alınır — sabit bir uzaklık
          // kullanmak kısa/satır içi oynatıcıda ortadaki düğmelerin ÜSTÜNE biniyordu (cihazda ölçüldü).
          if (captionOverlaid)
            Positioned(
              left: AppSpacing.s4,
              right: AppSpacing.s4,
              bottom: AppSpacing.s4,
              child: _CaptionBox(text: caption.text),
            ),

          if (c.isBuffering && !c.isPlaying)
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _visible ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_visible,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
                child: Column(
                  children: [
                    if (widget.showChapterTitle) _topBar(p),
                    const Spacer(),
                    _centerButtons(),
                    const Spacer(),
                    if (captionInColumn)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s4,
                          0,
                          AppSpacing.s4,
                          AppSpacing.s2,
                        ),
                        child: _CaptionBox(text: caption.text),
                      ),
                    _bottomBar(p),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(AppPalette p) {
    final idx = activeChapterIndex(widget.chapters, widget.controller.position);
    final title = idx >= 0 ? widget.chapters[idx].title : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s3, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
              ),
            ),
          ),
          if (widget.onToggleBookmark != null)
            _IconAction(
              icon: Icons.bookmark_add_outlined,
              tooltip: 'Yer imi ekle/çıkar',
              onPressed: () {
                widget.onToggleBookmark!.call();
                _poke();
              },
            ),
        ],
      ),
    );
  }

  Widget _centerButtons() {
    final c = widget.controller;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IconAction(
          icon: Icons.replay_10_rounded,
          tooltip: '10 saniye geri',
          size: 30,
          onPressed: () => _skip(-kSkipStep),
        ),
        const SizedBox(width: AppSpacing.s6),
        _IconAction(
          // Bittiyse "yeniden oynat" göstermek doğru geri bildirimdir.
          icon: c.isCompleted
              ? Icons.replay_rounded
              : (c.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          tooltip: c.isPlaying ? 'Duraklat' : 'Oynat',
          size: 44,
          onPressed: _togglePlay,
        ),
        const SizedBox(width: AppSpacing.s6),
        _IconAction(
          icon: Icons.forward_10_rounded,
          tooltip: '10 saniye ileri',
          size: 30,
          onPressed: () => _skip(kSkipStep),
        ),
      ],
    );
  }

  Widget _bottomBar(AppPalette p) {
    final c = widget.controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s3, 0, AppSpacing.s3, AppSpacing.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Timeline(
            position: c.position,
            duration: c.duration,
            buffered: bufferedFraction(c.buffered, c.duration),
            chapterMarks: chapterMarkerFractions(widget.chapters, c.duration),
            bookmarkMarks: _bookmarkFractions(c.duration),
            onSeek: (f) {
              c.seekTo(Duration(milliseconds: (c.duration.inMilliseconds * f).round()));
              _poke();
            },
          ),
          Row(
            children: [
              Text(
                '${formatDuration(c.position)} / ${formatDuration(c.duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              const Spacer(),
              if (widget.captions.isNotEmpty && widget.onToggleCaptions != null)
                _IconAction(
                  icon: widget.captionsEnabled
                      ? Icons.closed_caption_rounded
                      : Icons.closed_caption_off_outlined,
                  tooltip: widget.captionsEnabled ? 'Altyazıyı kapat' : 'Altyazıyı aç',
                  onPressed: () {
                    widget.onToggleCaptions!.call();
                    _poke();
                  },
                ),
              _SpeedButton(speed: c.speed, onPressed: _cycleSpeed),
              if (widget.onFullscreen != null)
                _IconAction(
                  icon: widget.isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  tooltip: widget.isFullscreen ? 'Tam ekrandan çık' : 'Tam ekran',
                  onPressed: () {
                    widget.onFullscreen!.call();
                    _poke();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _bookmarkFractions(Duration duration) {
    if (duration.inMilliseconds <= 0) return const [];
    return widget.bookmarks
        .map((ms) => ms / duration.inMilliseconds)
        .where((f) => f >= 0 && f <= 1)
        .toList(growable: false);
  }
}

/// Sürüklenebilir zaman çubuğu: arabellek + bölüm işaretleri + yer imleri.
///
/// `Slider` KULLANILMADI: arabellek aralığını ve işaretleri aynı çubukta göstermek gerekiyor;
/// Slider bunu desteklemiyor ve dokunma alanı çok kalın kalıyordu.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.chapterMarks,
    required this.bookmarkMarks,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final double buffered;
  final List<double> chapterMarks;
  final List<double> bookmarkMarks;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = progressFraction(position, duration);

    return LayoutBuilder(
      builder: (context, constraints) {
        void seekAt(Offset local) {
          final f = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onSeek(f);
        }

        return Semantics(
          slider: true,
          label: 'Video zaman çizgisi',
          value: '${formatDuration(position)} / ${formatDuration(duration)}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => seekAt(d.localPosition),
            onHorizontalDragUpdate: (d) => seekAt(d.localPosition),
            child: SizedBox(
              height: 28,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Zemin
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                    // Arabellek
                    FractionallySizedBox(
                      widthFactor: buffered,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                    // İlerleme
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: p.primary,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                    // Bölüm işaretleri
                    for (final f in chapterMarks)
                      Positioned(
                        left: f * constraints.maxWidth - 1,
                        child: Container(height: 4, width: 2, color: Colors.white70),
                      ),
                    // Yer imleri — bölümden ayırt edilsin diye farklı renk ve boy.
                    for (final f in bookmarkMarks)
                      Positioned(
                        left: f * constraints.maxWidth - 1.5,
                        top: -3,
                        child: Container(height: 10, width: 3, color: p.yellow),
                      ),
                    // Tutamaç
                    Positioned(
                      left: (progress * constraints.maxWidth) - 6,
                      top: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CaptionBox extends StatelessWidget {
  const _CaptionBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 22,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
        size: size,
        shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onPressed});
  final double speed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // 1.0 → "1x", 1.25 → "1.25x" (gereksiz sıfır yok).
    final label = speed == speed.roundToDouble()
        ? '${speed.toStringAsFixed(0)}x'
        : '${speed.toString()}x';
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 40),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
        ),
      ),
    );
  }
}
