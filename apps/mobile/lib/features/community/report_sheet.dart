import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/community/community_models.dart';

/// Evolution Faz E9 — ortak şikâyet sebebi seçici.
///
/// TEK YERDE: mesaj, tartışma iletisi ve kullanıcı profili aynı listeyi kullanır → sebep kümesi
/// sunucudakiyle tek noktadan hizalı kalır ve her yüzeyde aynı deneyim olur.
Future<ReportReason?> pickReportReason(BuildContext context) {
  return showModalBottomSheet<ReportReason>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppSpacing.s4),
            child: Text(
              'Bildirme sebebi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
              AppSpacing.s4,
              AppSpacing.s3,
            ),
            child: Text(
              'Bildirimler insan incelemesine gider. Otomatik bir filtre yoktur.',
              style: TextStyle(color: ctx.palette.text3, fontSize: 12.5, height: 1.35),
            ),
          ),
          for (final r in ReportReason.values)
            ListTile(title: Text(r.label), onTap: () => Navigator.pop(ctx, r)),
          const SizedBox(height: AppSpacing.s2),
        ],
      ),
    ),
  );
}
