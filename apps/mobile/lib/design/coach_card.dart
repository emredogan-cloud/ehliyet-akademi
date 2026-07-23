import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

/// Proactive AI Coach nudge card (mirrors `AI_MOBILE_BEHAVIOR.md` home-card). A single
/// highest-priority suggestion with an action. Phase 5 wires it to the nudge engine.
class CoachCard extends StatelessWidget {
  const CoachCard({super.key, required this.message, required this.actionLabel, this.onAction});
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.base),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withValues(alpha: p.brightness == Brightness.dark ? 0.22 : 0.12),
            p.accent.withValues(alpha: p.brightness == Brightness.dark ? 0.16 : 0.08),
          ],
        ),
        border: Border.all(color: p.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
              ),
              const SizedBox(width: AppSpacing.s3),
              Text('AI Koç', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(message, style: TextStyle(color: p.text, height: 1.4, fontSize: 14.5)),
          const SizedBox(height: AppSpacing.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick-action grid tile for the home screen.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.base),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4, horizontal: AppSpacing.s2),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadii.base),
            border: Border.all(color: p.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
