import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/practice/historical.dart';

/// Geçmiş (MEB) sınavları — 18 gerçek oturum tarihi; her biri için özgün, MEB formatında deneme.
class HistoricalScreen extends StatelessWidget {
  const HistoricalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final byYear = historicalSessionsByYear();
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      appBar: AppBar(title: const Text('Geçmiş Sınavlar')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s10),
          children: [
            HubHeader(
              title: 'Geçmiş Sınavlar',
              subtitle: historicalLabel,
              mascot: AppImages.illPapers,
              mascotHeight: 120,
            ),
            const SizedBox(height: AppSpacing.s4),
            for (final year in years) ...[
              SectionTitle('$year', trailing: Icon(Icons.calendar_month_rounded, color: p.primary, size: 18)),
              for (final s in byYear[year]!) ...[
                GlowCard(
                  onTap: () => context.push('/practice/historical/${s.id}'),
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Row(
                    children: [
                      IconBadge(icon: Icons.assignment_rounded, color: p.primary, size: 50),
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.description_outlined, size: 13, color: p.text3),
                                const SizedBox(width: 4),
                                // Beta Faz 11 — esnek: 320 dp'de ve 1,3× yazıda satır taşıyordu.
                                Flexible(
                                  child: Text(
                                    '50 soru · MEB formatı',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: p.text3, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: p.primary.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.chevron_right_rounded, color: p.primary, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
