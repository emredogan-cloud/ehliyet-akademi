import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/assets.dart';
import '../../../core/theme/tokens.dart';
import '../../../design/brand.dart';
import '../../../domain/onboarding/onboarding_insights.dart';

/// Evolution Faz E6 — onboarding'de AI Koç'un konuştuğu, dönen içgörü kartı.
///
/// TASARIM KARARI: koç maskotu ile içgörü kartı TEK bileşendir. Ayrı bir maskot bloğu her adıma
/// dikey yükseklik eklerdi; oysa bu fazın diğer şartı ekranların KAYDIRMASIZ sığmasıdır. Maskotu
/// kartın içine almak, koçu her adımda görünür kılarken boş alanı değerlendirir ve yükseklik
/// maliyetini tek bir kompakt satıra indirir.
///
/// ERİŞİLEBİLİRLİK: `MediaQuery.disableAnimations` açıksa maskot sallanmaz ve kart DÖNMEZ —
/// ilk içgörüde sabit kalır. Bu aynı zamanda widget testleri için doğal bir sabitleyicidir
/// (`pumpAndSettle` sonsuz kare kuyruğuna takılmaz); dönüşü test eden testler hareketi açar.
class CoachInsightCard extends StatefulWidget {
  const CoachInsightCard({
    super.key,
    required this.step,
    this.rotation = const Duration(seconds: 3),
    this.compact = false,
  });

  /// Onboarding adımı (0..5) — içgörü kümesini seçer.
  final int step;

  /// Kart değişim aralığı.
  final Duration rotation;

  /// Dar düzen: küçük maskot ve daralmış iç boşluk (dikey bütçe kısıtlı ekranlar).
  final bool compact;

  @override
  State<CoachInsightCard> createState() => _CoachInsightCardState();
}

class _CoachInsightCardState extends State<CoachInsightCard> {
  Timer? _timer;
  int _tick = 0;
  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = !MediaQuery.disableAnimationsOf(context);
    if (motion != _motion || (_motion && _timer == null)) {
      _motion = motion;
      _restartTimer();
    }
  }

  @override
  void didUpdateWidget(covariant CoachInsightCard old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) _tick = 0;
    if (old.rotation != widget.rotation) _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_motion) return;
    _timer = Timer.periodic(widget.rotation, (_) {
      if (!mounted) return;
      setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final insight = insightAt(widget.step, _tick);
    final color = _colorFor(insight.kind, p);

    return Semantics(
      liveRegion: true,
      label: 'AI Koç ipucu: ${insight.kind.label}. ${insight.text}',
      excludeSemantics: true,
      child: Container(
        padding: widget.compact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 6)
            : const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IdleMascot(AppImages.owlWave, height: widget.compact ? 38 : 54, semanticLabel: 'AI Koç'),
            SizedBox(width: widget.compact ? AppSpacing.s2 : AppSpacing.s3),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                switchInCurve: AppMotion.easeOut,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                child: Column(
                  key: ValueKey('${widget.step}-$_tick'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dar düzende tür etiketi düşer; kartın kenar rengi türü zaten taşıyor.
                    if (!widget.compact) ...[
                      Text(
                        insight.kind.label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      insight.text,
                      style: TextStyle(
                        color: p.text2,
                        fontSize: widget.compact ? 11.5 : 12.5,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(InsightKind kind, AppPalette p) => switch (kind) {
    InsightKind.ipucu => p.primary,
    InsightKind.bilgi => p.blue,
    InsightKind.motivasyon => p.accent,
    InsightKind.surus => p.purple,
    InsightKind.sinav => p.red,
    InsightKind.strateji => p.green,
  };
}

/// Yumuşak "nefes alan" maskot — hafif dikey süzülme. `MediaQuery.disableAnimations` açıkken
/// hiç hareket etmez (hareket azaltma tercihi) ve tekrar eden kare kuyruğu oluşturmaz.
class IdleMascot extends StatefulWidget {
  const IdleMascot(
    this.asset, {
    super.key,
    required this.height,
    this.semanticLabel,
    this.amplitude = 3.5,
    this.period = const Duration(milliseconds: 2600),
  });

  final String asset;
  final double height;
  final String? semanticLabel;

  /// Dikey süzülme genliği (px).
  final double amplitude;
  final Duration period;

  @override
  State<IdleMascot> createState() => _IdleMascotState();
}

class _IdleMascotState extends State<IdleMascot> with SingleTickerProviderStateMixin {
  // DİKKAT: `late final ... = ` (tembel) OLMAZ. Hareket azaltma açıkken denetleyiciye hiç
  // dokunulmaz ve ilk erişim `dispose()` içinde olur; orada ticker için ata aramak yasaktır
  // ("Looking up a deactivated widget's ancestor is unsafe"). Bu yüzden initState'te kurulur.
  late final AnimationController _c;
  bool _motion = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = !MediaQuery.disableAnimationsOf(context);
    if (motion == _motion) return;
    _motion = motion;
    if (motion) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = MascotImage(
      widget.asset,
      height: widget.height,
      fit: BoxFit.contain,
      semanticLabel: widget.semanticLabel,
    );
    if (!_motion) return image;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -widget.amplitude * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: image,
    );
  }
}
