import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/content_snapshot.dart';
import '../../domain/content/traffic_sign.dart';
import 'widgets/content_scope.dart';
import 'widgets/traffic_sign_view.dart';

/// Trafik işaretleri galerisi — kategoriye göre gruplanmış, aranabilir. Her işaret parametrik
/// olarak çizilir (TrafficSignView).
class SignsScreen extends StatefulWidget {
  const SignsScreen({super.key});

  @override
  State<SignsScreen> createState() => _SignsScreenState();
}

class _SignsScreenState extends State<SignsScreen> {
  String _query = '';

  bool _matches(TrafficSign s) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return s.name.toLowerCase().contains(q) ||
        s.meaning.toLowerCase().contains(q) ||
        s.keywords.any((k) => k.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Trafik İşaretleri')),
      body: SafeArea(
        top: false,
        child: ContentBuilder(
          builder: (context, snapshot) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s2,
                    AppSpacing.s4,
                    AppSpacing.s2,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'İşaret ara (ad, anlam, anahtar kelime)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Aramayı temizle',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() => _query = ''),
                            ),
                    ),
                  ),
                ),
                Expanded(child: _grid(context, snapshot, p)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, ContentSnapshot snapshot, AppPalette p) {
    final grouped = snapshot.signsByCategory();
    final categories = SignCategory.values.where((c) => grouped.containsKey(c)).toList();

    final sections = <Widget>[];
    for (final cat in categories) {
      final signs = grouped[cat]!.where(_matches).toList();
      if (signs.isEmpty) continue;
      sections.add(SectionTitle('${cat.label}  ·  ${signs.length}'));
      sections.add(
        Wrap(
          spacing: AppSpacing.s3,
          runSpacing: AppSpacing.s3,
          children: [for (final s in signs) _SignTile(sign: s)],
        ),
      );
    }

    if (sections.isEmpty) {
      return const AppEmptyState(emoji: '🔍', title: 'Eşleşen işaret yok', subtitle: 'Farklı bir kelime dene.');
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s10),
      children: sections,
    );
  }
}

class _SignTile extends StatelessWidget {
  const _SignTile({required this.sign});
  final TrafficSign sign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // 3 sütun: (genişlik - 2*padding - 2*aralık) / 3
    final width = (MediaQuery.sizeOf(context).width - AppSpacing.s4 * 2 - AppSpacing.s3 * 2) / 3;
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: () => context.push('/learn/signs/${sign.id}'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3, horizontal: AppSpacing.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(child: TrafficSignView(sign: sign, size: width * 0.62)),
            const SizedBox(height: AppSpacing.s2),
            Text(
              sign.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.2, color: p.text2, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
