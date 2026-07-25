import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/dash_lights.dart';

/// İkaz ışığının rengi — önem düzeyine göre tasarım token'ından.
Color dashSeverityColor(BuildContext context, DashSeverity s) => switch (s) {
  DashSeverity.kirmizi => context.palette.red,
  DashSeverity.sari => context.palette.accent,
  DashSeverity.bilgi => context.palette.green,
};

/// Gösterge İkaz Işıkları — 60 gerçek ikon, anlamı ve gerektirdiği eylem (Evolution Faz E3).
class DashLightsScreen extends StatefulWidget {
  const DashLightsScreen({super.key});

  @override
  State<DashLightsScreen> createState() => _DashLightsScreenState();
}

class _DashLightsScreenState extends State<DashLightsScreen> {
  String _query = '';
  DashSeverity? _filter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = _query.trim().toLowerCase();
    final items = kDashLights.where((l) {
      if (_filter != null && l.severity != _filter) return false;
      if (q.isEmpty) return true;
      return '${l.name} ${l.meaning} ${l.tip}'.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('İkaz Işıkları')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'İkaz ışığı ara (ad, anlam)',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
                children: [
                  _FilterChip(
                    label: 'Tümü',
                    color: p.text3,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final s in DashSeverity.values)
                    _FilterChip(
                      label: s.label,
                      color: dashSeverityColor(context, s),
                      selected: _filter == s,
                      onTap: () => setState(() => _filter = s),
                    ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const AppEmptyState(emoji: '🔍', title: 'Sonuç yok')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s4,
                        AppSpacing.s2,
                        AppSpacing.s4,
                        AppSpacing.s10,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: AppSpacing.s3,
                        crossAxisSpacing: AppSpacing.s3,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _LightTile(light: items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.18) : p.surface2,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: selected ? color : p.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : p.text2,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _LightTile extends StatelessWidget {
  const _LightTile({required this.light});
  final DashLight light;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final asset = light.asset;
    return AppCard(
      onTap: () => context.push('/learn/lights/${light.id}'),
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 54,
            child: asset == null
                ? Icon(Icons.warning_amber_rounded, color: p.accent, size: 34)
                : Image.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(height: AppSpacing.s2),
          Expanded(
            child: Text(
              light.name,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

/// İkaz ışığı detayı — anlam, hafıza tekniği ve ne yapılması gerektiği.
class DashLightDetailScreen extends StatelessWidget {
  const DashLightDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final light = kDashLights.where((l) => l.id == id).firstOrNull;
    if (light == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(emoji: '🔍', title: 'İkaz ışığı bulunamadı'),
      );
    }
    final color = dashSeverityColor(context, light.severity);
    final asset = light.asset;
    return Scaffold(
      appBar: AppBar(title: Text(light.name, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: asset == null
                    ? Icon(Icons.warning_amber_rounded, color: color, size: 70)
                    : Image.asset(asset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  light.severity.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: p.primary),
                      const SizedBox(width: AppSpacing.s2),
                      const Text('Anlamı', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(light.meaning, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            AppCallout(text: light.tip, title: '🧠 Hafıza tekniği', tone: CalloutTone.success),
          ],
        ),
      ),
    );
  }
}
