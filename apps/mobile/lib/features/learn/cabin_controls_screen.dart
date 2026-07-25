import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/mech_image.dart';
import '../../design/primitives.dart';
import '../../domain/content/vehicle_visuals.dart';

/// Kabin Kumandaları — gerçek araç içi düğme/kol/soket fotoğraflarıyla görsel kütüphane
/// (Evolution Faz E2). Ne olduğunu tanımak sınavda ve direksiyonda doğrudan işe yarar.
class CabinControlsScreen extends StatefulWidget {
  const CabinControlsScreen({super.key});

  @override
  State<CabinControlsScreen> createState() => _CabinControlsScreenState();
}

class _CabinControlsScreenState extends State<CabinControlsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? kCabinControls
        : kCabinControls
              .where((c) => '${c.title} ${c.desc} ${c.group}'.toLowerCase().contains(q))
              .toList();
    final groups = <String, List<CabinControl>>{};
    for (final c in items) {
      groups.putIfAbsent(c.group, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kabin Kumandaları')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s2,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Kumanda ara (ad, işlev)',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const AppEmptyState(emoji: '🔍', title: 'Sonuç yok')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s4,
                        0,
                        AppSpacing.s4,
                        AppSpacing.s10,
                      ),
                      children: [
                        for (final entry in groups.entries) ...[
                          SectionTitle('${entry.key}  ·  ${entry.value.length}'),
                          for (final c in entry.value) ...[
                            _ControlCard(control: c),
                            const SizedBox(height: AppSpacing.s3),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.control});
  final CabinControl control;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MechImage(id: control.asset, size: 62),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  control.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  control.desc,
                  style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
