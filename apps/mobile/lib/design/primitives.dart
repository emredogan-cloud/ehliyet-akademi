import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';
import 'app_card.dart';

/// Page header — emoji + title + subtitle (mirrors web `PageHeader`).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({super.key, required this.title, required this.emoji, this.subtitle});
  final String title;
  final String emoji;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(subtitle!, style: TextStyle(color: p.text3, fontSize: 13.5, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

/// Section title (mirrors web `.section-title`).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6, bottom: AppSpacing.s3),
      child: Row(
        children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

enum CalloutTone { info, success, warning, danger }

/// Callout box (mirrors web `Callout`).
class AppCallout extends StatelessWidget {
  const AppCallout({super.key, required this.text, this.tone = CalloutTone.info, this.title});
  final String text;
  final CalloutTone tone;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (tone) {
      CalloutTone.info => p.blue,
      CalloutTone.success => p.green,
      CalloutTone.warning => p.accent,
      CalloutTone.danger => p.red,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
            const SizedBox(height: 2),
          ],
          Text(text, style: TextStyle(color: p.text2, height: 1.4, fontSize: 13.5)),
        ],
      ),
    );
  }
}

/// Small labelled stat (used on dashboards).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color ?? p.text),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: p.text3)),
      ],
    );
  }
}

/// Empty state (mirrors web `EmptyState`).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.action});
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: AppSpacing.s3),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: p.text3)),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.s4), action!],
          ],
        ),
      ),
    );
  }
}

/// Section/overview row card (icon + title + subtitle + optional trailing).
class OverviewTile extends StatelessWidget {
  const OverviewTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = iconColor ?? p.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: c, size: 22),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s2),
            Text(trailing!, style: TextStyle(color: p.text2, fontWeight: FontWeight.w700)),
          ],
          if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}
