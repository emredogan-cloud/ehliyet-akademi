import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/practice/enriched_bank.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/practice/exam_library.dart';
import '../../domain/premium/products.dart';

/// Ürün Evrimi v1.1 · Faz 2 — sınav kütüphanesi kataloğu.
///
/// Referans uygulamanın "Sınav Soruları" ekranının karşılığı: kategoriler, her birinin kaç sınav
/// ve kaç soru içerdiği. Fark: bizde sınavlar SAKLANMIYOR, üretiliyor — dolayısıyla "kaç sınav"
/// takvimden, "kaç soru" bankadan hesaplanır. Uydurma sayı yok.
class ExamLibraryScreen extends ConsumerWidget {
  const ExamLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final bank = ref.watch(enrichedBankProvider).value;
    final premium = isPremium(ref.watch(entitlementsProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Sınav Arşivi')),
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
            HubHeader(
              title: 'Sınav Arşivi',
              subtitle: libraryDisclaimer,
              mascot: AppImages.illPapers,
              mascotHeight: 120,
            ),
            const SizedBox(height: AppSpacing.s4),
            if (!premium)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: AppCallout(
                  tone: CalloutTone.info,
                  title: 'İlk $kFreeExamCount sınav ücretsiz',
                  text:
                      'Genel Sınav kategorisindeki en yeni $kFreeExamCount sınavı ücretsiz '
                      'çözebilirsin. Gerisi premium.',
                ),
              ),
            for (final c in ExamCategory.values) ...[
              GlowCard(
                onTap: () => context.push('/practice/library/${c.name}'),
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Row(
                  children: [
                    IconBadge(icon: _iconFor(c), color: p.primary, size: 50),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          // SAYILAR HESAPLANIR, yazılmaz: sınav sayısı takvimden, soru havuzu
                          // bankadan gelir. Sabit bir sayı yazmak, banka büyüdüğünde yalan olurdu.
                          Row(
                            children: [
                              Icon(Icons.description_outlined, size: 13, color: p.text3),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  bank == null
                                      ? c.blurb
                                      : '$kLibraryExamsPerCategory sınav · '
                                            '${poolSizeFor(c, bank.questions)} soruluk havuz',
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
        ),
      ),
    );
  }

  static IconData _iconFor(ExamCategory c) => switch (c) {
    ExamCategory.genel => Icons.assignment_rounded,
    ExamCategory.trafik => Icons.traffic_rounded,
    ExamCategory.ilkyardim => Icons.medical_services_rounded,
    ExamCategory.motor => Icons.settings_rounded,
    ExamCategory.adab => Icons.handshake_rounded,
    ExamCategory.gorsel => Icons.image_rounded,
  };
}

/// Bir kategorinin tarih listesi. Kullanıcı yalnız TARİH görür.
class ExamLibraryDatesScreen extends ConsumerWidget {
  const ExamLibraryDatesScreen({super.key, required this.category});

  final ExamCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final premium = isPremium(ref.watch(entitlementsProvider));
    final exams = libraryExams(category, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          itemCount: exams.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                child: Text(
                  libraryDisclaimer,
                  style: TextStyle(color: p.text3, fontSize: 12, height: 1.35),
                ),
              );
            }
            final e = exams[i - 1];
            final open = canOpenExam(e, premium: premium);
            return GlowCard(
              // KİLİTLİ SINAV DA DOKUNULABİLİR — ödeme ekranına götürür. Dokunulamaz bir kart
              // kullanıcıya "burada yapacak bir şey yok" der; oysa yapacağı şey var.
              onTap: () => open
                  ? context.push('/practice/library/${category.name}/${e.date}')
                  : context.push('/premium?from=exam-library'),
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  IconBadge(
                    icon: open ? Icons.play_arrow_rounded : Icons.lock_rounded,
                    color: open ? p.primary : p.text3,
                    size: 46,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        // `Flexible` DEĞİL: burası bir Column ve dikey kısıt sınırsız —
                        // esneme payı hesaplanamaz. Yatayda taşmayı `maxLines` + `ellipsis`
                        // zaten engelliyor.
                        Text(
                          open
                              ? '${category.questionCount} soru'
                              : '${category.questionCount} soru · Premium',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.text3, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  if (isExamFree(e))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.green.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        'Ücretsiz',
                        style: TextStyle(
                          color: p.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
