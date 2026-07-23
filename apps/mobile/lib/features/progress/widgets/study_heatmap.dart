import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Çalışma ısı haritası — son [weeks] hafta, her hücre bir gün; renk yoğunluğu o günkü soru sayısı.
class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({super.key, required this.perDay, this.weeks = 14});

  /// 'YYYY-MM-DD' → o gün cevaplanan soru sayısı.
  final Map<String, int> perDay;
  final int weeks;

  static String _key(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Haftanın pazartesi başladığı varsayımıyla en son sütunu bugünün haftasına hizala.
    final daysSinceMonday = (today.weekday - 1); // Mon=0
    final lastColMonday = today.subtract(Duration(days: daysSinceMonday));
    final firstMonday = lastColMonday.subtract(Duration(days: (weeks - 1) * 7));

    Color cellColor(int count) {
      if (count <= 0) return p.surface3;
      if (count < 5) return p.primary.withValues(alpha: 0.30);
      if (count < 10) return p.primary.withValues(alpha: 0.55);
      if (count < 20) return p.primary.withValues(alpha: 0.78);
      return p.primary;
    }

    // 7 satır (gün) × weeks sütun (hafta).
    final columns = <Widget>[];
    for (var w = 0; w < weeks; w++) {
      final cells = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final day = firstMonday.add(Duration(days: w * 7 + d));
        final future = day.isAfter(today);
        final count = future ? 0 : (perDay[_key(day)] ?? 0);
        cells.add(
          Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: future ? Colors.transparent : cellColor(count),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }
      columns.add(Column(children: cells));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(children: columns),
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Az', style: TextStyle(color: p.text3, fontSize: 11)),
            const SizedBox(width: 4),
            for (final a in [0.0, 0.30, 0.55, 0.78, 1.0])
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: a == 0.0 ? p.surface3 : p.primary.withValues(alpha: a),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const SizedBox(width: 4),
            Text('Çok', style: TextStyle(color: p.text3, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
