import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/content/content_queries.dart';
import '../../domain/content/vehicle_part.dart';
import 'widgets/content_scope.dart';

IconData vehicleSystemIcon(VehicleSystem s) => switch (s) {
  VehicleSystem.motorBolmesi => Icons.settings_suggest_rounded,
  VehicleSystem.kabin => Icons.dashboard_rounded,
  VehicleSystem.dis => Icons.tire_repair_rounded,
  VehicleSystem.muayene => Icons.fact_check_rounded,
};

/// Araç tekniği — sisteme göre gruplanmış bileşen listesi.
class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Araç Tekniği')),
      body: SafeArea(
        top: false,
        child: ContentBuilder(
          builder: (context, snapshot) {
            final grouped = snapshot.partsBySystem();
            final systems = VehicleSystem.values.where((s) => grouped.containsKey(s)).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              children: [
                for (final system in systems) ...[
                  SectionTitle('${system.label}  ·  ${grouped[system]!.length}'),
                  for (final part in grouped[system]!) ...[
                    _PartCard(part: part),
                    const SizedBox(height: AppSpacing.s3),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.part});
  final VehiclePart part;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: () => context.push('/learn/vehicle/${part.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(vehicleSystemIcon(part.system), color: p.accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(part.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    if (part.inspection.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.s2),
                      Icon(Icons.checklist_rounded, size: 15, color: p.text3),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  part.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.text3),
        ],
      ),
    );
  }
}
