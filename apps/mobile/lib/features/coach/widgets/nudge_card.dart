import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../design/app_card.dart';
import '../../../domain/coach/nudge.dart';

/// Proaktif koç kartı — emoji + başlık + gövde + eylem. Ton'a göre sol vurgu çubuğu.
class NudgeCard extends StatelessWidget {
  const NudgeCard({super.key, required this.nudge, required this.onTap});
  final Nudge nudge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (nudge.tone) {
      NudgeTone.good => p.green,
      NudgeTone.warn => p.accent,
      NudgeTone.info => p.primary,
    };
    return AppCard(
      accent: color,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nudge.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nudge.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                const SizedBox(height: 3),
                Text(nudge.body, style: TextStyle(color: p.text2, height: 1.4, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}
