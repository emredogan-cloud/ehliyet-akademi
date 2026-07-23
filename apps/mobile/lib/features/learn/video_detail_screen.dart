import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/video_content.dart';
import 'videos_screen.dart' show absoluteMediaUrl;
import 'widgets/content_scope.dart';

/// Video detayı — gerçek oynatıcı (video_player) + bölümler + açıklama.
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
        return Scaffold(
          appBar: AppBar(title: Text(video.title, overflow: TextOverflow.ellipsis)),
          body: SafeArea(top: false, child: _VideoBody(video: video)),
        );
      },
    );
  }
}

class _VideoBody extends StatefulWidget {
  const _VideoBody({required this.video});
  final VideoContent video;

  @override
  State<_VideoBody> createState() => _VideoBodyState();
}

class _VideoBodyState extends State<_VideoBody> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(absoluteMediaUrl(widget.video.src!)))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = widget.video;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s10),
      children: [
        _player(p),
        const SizedBox(height: AppSpacing.s4),
        Text(v.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s2),
        Text(v.description, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14)),
        if (v.chapters.isNotEmpty) ...[
          const SectionTitle('Bölümler'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < v.chapters.length; i++)
                  _ChapterRow(
                    chapter: v.chapters[i],
                    isLast: i == v.chapters.length - 1,
                    onTap: _ready ? () => _controller.seekTo(Duration(seconds: v.chapters[i].t)) : null,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _player(AppPalette p) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: p.surface3, borderRadius: BorderRadius.circular(AppRadii.base)),
          alignment: Alignment.center,
          child: Text('Video yüklenemedi', style: TextStyle(color: p.text3)),
        ),
      );
    }
    if (!_ready) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(color: p.surface3, borderRadius: BorderRadius.circular(AppRadii.base)),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.base),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
        child: GestureDetector(
          onTap: _togglePlay,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              if (!_controller.value.isPlaying)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(playedColor: p.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.isLast, this.onTap});
  final VideoChapter chapter;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_outline_rounded, size: 18, color: p.primary),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(chapter.title, style: TextStyle(color: p.text2, fontSize: 13.5))),
            Text(
              _fmt(chapter.t),
              style: TextStyle(color: p.text3, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
