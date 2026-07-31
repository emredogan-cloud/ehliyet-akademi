import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../design/app_card.dart';
import '../../../domain/coach/coach_insights.dart';
import '../../../domain/content/content_enums.dart';

/// Beta Faz 7 — AI Koç'un analiz kartları.
///
/// Hepsinin ortak kuralı: **iddia varsa kanıt da var**. "Şu konuda zayıfsın" cümlesinin yanında
/// her zaman sayı durur ("32 soruda 13 yanlış"). Kanıtsız bir iddia, kullanıcı katılmadığında
/// tartışılamaz — ve katılmadığı bir koça bir daha bakmaz.

/// Sınav tahmini kartı.
class ExamForecastCard extends StatelessWidget {
  const ExamForecastCard({super.key, required this.forecast});
  final ExamForecast forecast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Veri yoksa SAYI GÖSTERİLMEZ. Sıfır ya da "%50" yazmak uydurma bir tahmindir.
    if (forecast.confidence == PredictionConfidence.none) {
      return AppCard(
        child: Row(
          children: [
            Icon(Icons.insights_rounded, color: p.text3, size: 22),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                confidenceLabel(forecast),
                style: TextStyle(color: p.text2, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final passing = forecast.predictsPass;
    final accent = passing ? p.primary : p.accent;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: accent, size: 22),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'Sınav tahmini',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${forecast.predictedCorrect}',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 34),
              ),
              Text(
                ' / 50 doğru',
                style: TextStyle(color: p.text2, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              // Baraj HER ZAMAN yanında: 38 sayısı tek başına iyi mi kötü mü belli değil.
              Text('baraj 35', style: TextStyle(color: p.text3, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          // Güvenilirlik cümlesi sayının YANINDAN AYRILMAZ. Yalnız "38/50" gösterilirse kullanıcı
          // onu bir SÖZ sanır; sınavdan kalırsa suçlu uygulama olur.
          Text(
            confidenceLabel(forecast),
            style: TextStyle(color: p.text3, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// Zayıf konular kartı.
class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({super.key, required this.topics, this.onStudy});
  final List<WeakTopic> topics;
  final void Function(WeakTopic)? onStudy;

  static const _subjectLabel = {
    Subject.trafik: 'Trafik',
    Subject.ilkyardim: 'İlk Yardım',
    Subject.motor: 'Araç Tekniği',
    Subject.adab: 'Trafik Adabı',
    Subject.pratik: 'Pratik',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down_rounded, color: p.accent, size: 22),
              const SizedBox(width: AppSpacing.s2),
              Text(
                'En çok zorlandığın konular',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          for (final t in topics) ...[
            InkWell(
              onTap: onStudy == null ? null : () => onStudy!(t),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            humanizeTopic(t.topic),
                            style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // KANIT: "32 soruda 13 yanlış". Yüzde soyut, sayı somut.
                          Text(
                            '${_subjectLabel[t.subject] ?? ''} · ${t.answered} soruda ${t.wrong} yanlış',
                            style: TextStyle(color: p.text3, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      '%${t.accuracyPercent}',
                      style: TextStyle(
                        color: t.accuracy < 0.5 ? p.red : p.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (onStudy != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: p.text3, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Yedi günlük plan kartı.
class StudyPlanCard extends StatelessWidget {
  const StudyPlanCard({super.key, required this.plan});
  final List<StudyDay> plan;

  static const _dayLabels = ['Bugün', 'Yarın', '3. gün', '4. gün', '5. gün', '6. gün', '7. gün'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: p.primary, size: 22),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '7 günlük planın',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: p.text),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          for (final day in plan)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      _dayLabels[day.dayIndex],
                      style: TextStyle(
                        color: day.dayIndex == 0 ? p.primary : p.text3,
                        fontWeight: day.dayIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    day.isReviewDay ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                    size: 15,
                    color: day.isReviewDay ? p.accent : p.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      day.focus,
                      style: TextStyle(color: p.text2, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${day.questionCount} soru',
                    style: TextStyle(color: p.text3, fontSize: 11.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// İlerleme geri bildirimi — son hafta ile ondan önceki hafta.
class ProgressFeedbackCard extends StatelessWidget {
  const ProgressFeedbackCard({super.key, required this.trend});
  final ProgressTrend trend;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Karşılaştırma yapılamıyorsa kart HİÇ ÇİZİLMEZ (çağıran kontrol eder); burada ikinci bir
    // güvenlik: anlamsız veriyle yorum yapılmaz.
    if (!trend.isMeaningful) return const SizedBox.shrink();

    final improving = trend.isImproving;
    final declining = trend.isDeclining;
    final points = (trend.delta * 100).round().abs();

    final (icon, color, title, body) = improving
        ? (
            Icons.trending_up_rounded,
            p.primary,
            'Gelişiyorsun',
            'Son hafta doğruluğun %$points puan arttı '
                '(%${(trend.earlierAccuracy * 100).round()} → %${(trend.recentAccuracy * 100).round()}).',
          )
        : declining
        // Düşüşü SAKLAMAK yanlış olurdu: kullanıcı sınava girip kalırsa, uygulamanın ona
        // "gelişiyorsun" demiş olması en kötü sonuçtur. Ama suçlamadan söylenir.
        ? (
            Icons.trending_down_rounded,
            p.accent,
            'Bu hafta biraz düştü',
            'Doğruluğun %$points puan geriledi. Zorlandığın konulara dönmek iyi gelebilir.',
          )
        : (
            Icons.trending_flat_rounded,
            p.text3,
            'İstikrarlı',
            'Doğruluğun geçen haftayla aynı seviyede. Zayıf konulara ağırlık vermek fark yaratır.',
          );

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: p.text),
                ),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(color: p.text2, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
