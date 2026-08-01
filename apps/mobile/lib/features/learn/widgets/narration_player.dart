import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/content/narration_source.dart';
import '../../../domain/content/lesson.dart';
import '../../../domain/content/narration.dart';

/// Sesli anlatım oynatıcısı — Premium Kalite Programı · Faz 5.
///
/// ## GÖRÜNMEME kuralı
///
/// Bu widget, kaynak gerçekten ses veremiyorsa **hiçbir şey çizmez**. "Yakında" rozeti,
/// devre dışı bir oynat düğmesi ya da boş bir ilerleme çubuğu koymaz.
///
/// Gerekçe Faz 0 denetiminden geliyor: ürün turu "geçmiş sınavları olduğu gibi çöz" diye
/// gerçekleşmeyen bir vaat veriyordu ve bu, kullanıcıya yalan söylemekti. Aynı hatanın
/// ses tarafındaki biçimi "sesli anlatım (yakında)" yazan bir düğme olurdu: özellik
/// listesini şişirir, kullanıcıya hiçbir şey vermez.
///
/// Ses üretilip `assets/audio/` altına konduğunda `narrationSourceProvider` değişir,
/// oynatıcı **kendiliğinden** görünür ve bu dosyada tek satır değişmez.
class NarrationPlayer extends ConsumerStatefulWidget {
  const NarrationPlayer({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<NarrationPlayer> createState() => _NarrationPlayerState();
}

class _NarrationPlayerState extends ConsumerState<NarrationPlayer> {
  NarrationSpeed _speed = NarrationSpeed.normal;

  @override
  Widget build(BuildContext context) {
    final narration = buildLessonNarration(widget.lesson);
    if (narration.isEmpty) return const SizedBox.shrink();

    final source = ref.watch(narrationSourceProvider);

    return FutureBuilder<List<String?>>(
      // Her parça için kaynağa AYRI AYRI sorulur; kısmi ses (yalnız özet seslendirilmiş)
      // geçerli bir durumdur ve oynatıcı o parçaları gösterir.
      future: Future.wait(
        narration.segments.map((s) => source.resolve(narration.lessonId, s)),
      ),
      builder: (context, snap) {
        // Beklerken de yer tutulmaz: yükleniyor iskeletini göstermek, ses olmadığı
        // durumda ekranda bir an beliren ve kaybolan bir kutu demekti.
        if (!snap.hasData) return const SizedBox.shrink();
        final playable = <(NarrationSegment, String)>[
          for (var i = 0; i < narration.segments.length; i++)
            if (snap.data![i] != null) (narration.segments[i], snap.data![i]!),
        ];
        if (playable.isEmpty) return const SizedBox.shrink();
        return _Panel(
          narration: narration,
          playable: playable,
          speed: _speed,
          onSpeed: () => setState(() => _speed = _speed.next),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.narration,
    required this.playable,
    required this.speed,
    required this.onSpeed,
  });

  final LessonNarration narration;
  final List<(NarrationSegment, String)> playable;
  final NarrationSpeed speed;
  final VoidCallback onSpeed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = playable.fold(0, (s, e) => s + e.$1.estimatedSeconds);
    final mins = (total / 60).ceil();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: p.primary050,
        border: Border.all(color: p.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.s3),
      ),
      child: Row(
        children: [
          Icon(Icons.headphones_rounded, color: p.primary, size: 22),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesli anlatım',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: p.text),
                ),
                Text(
                  '${playable.length} bölüm · yaklaşık $mins dakika',
                  style: TextStyle(fontSize: 11.5, color: p.text3),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSpeed,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            ),
            child: Text(speed.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.play_circle_fill_rounded, size: 34),
            color: p.primary,
            tooltip: 'Sesli anlatımı oynat',
          ),
        ],
      ),
    );
  }
}
