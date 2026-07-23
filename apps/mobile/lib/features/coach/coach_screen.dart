import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/coach_card.dart';
import '../../design/primitives.dart';

/// AI Koç — proactive assistant overview. Live chat + the nudge engine arrive in Phase 5; this
/// screen is a complete introduction showing what the coach does (real, styled, non-placeholder).
class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Koç')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            const AppPageHeader(
              title: 'AI Koç',
              emoji: '🤖',
              subtitle:
                  'Sadece bir sohbet botu değil — ilerlemeni izleyen, sana özel öneren proaktif bir koç.',
            ),
            const SizedBox(height: AppSpacing.s2),
            CoachCard(
              message:
                  'Merhaba! Bugün 15 dakika çalışırsak sınava bir adım daha yaklaşırsın. Hazır mısın?',
              actionLabel: 'Bugünkü planı gör',
            ),
            SectionTitle('Koç neler yapar?'),
            AppCard(
              child: Column(
                children: const [
                  _CoachFeature(
                      icon: Icons.trending_down_rounded, text: 'Zayıf konularını bulur ve öneri sunar'),
                  _CoachFeature(
                      icon: Icons.notifications_active_outlined,
                      text: 'Çalışma zamanını hatırlatır, serini korur'),
                  _CoachFeature(
                      icon: Icons.insights_rounded, text: 'İlerlemeni özetler, hazırlık skorunu yorumlar'),
                  _CoachFeature(
                      icon: Icons.emoji_events_outlined, text: 'Başarılarını kutlar, seni motive eder'),
                  _CoachFeature(
                      icon: Icons.help_outline_rounded,
                      text: 'Sorularını yanıtlar — yalnız ehliyet ve trafik konularında',
                      last: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppCallout(
              tone: CalloutTone.info,
              title: 'Güvenilir bilgi',
              text:
                  'AI yanıtları platform içeriğine dayanır; kesin ve güncel kural için MEB/MTSK esastır.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachFeature extends StatelessWidget {
  const _CoachFeature({required this.icon, required this.text, this.last = false});
  final IconData icon;
  final String text;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: p.primary, size: 22),
          const SizedBox(width: AppSpacing.s3),
          Expanded(child: Text(text, style: TextStyle(color: p.text2, height: 1.35, fontSize: 14))),
        ],
      ),
    );
  }
}
