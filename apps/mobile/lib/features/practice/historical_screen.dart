import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            AppCallout(text: historicalLabel, title: 'ℹ️ Bilgi', tone: CalloutTone.info),
            for (final year in years) ...[
              SectionTitle('$year'),
              for (final s in byYear[year]!) ...[
                AppCard(
                  onTap: () => context.push('/practice/historical/${s.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.primary050,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Icon(Icons.history_edu_rounded, color: p.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.label,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('50 soru · MEB formatı',
                                style: TextStyle(color: p.text3, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.text3),
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
