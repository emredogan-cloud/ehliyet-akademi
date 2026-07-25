import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/practice/question_repository.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../data/premium/quota_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/practice/collections.dart';
import '../../domain/premium/premium_prompt.dart';
import '../premium/premium_popups.dart';

/// Pratik hub — akıllı çalışma, deneme sınavı, koleksiyonlar, geçmiş sınavlar.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final licence = ref.watch(studyProfileProvider).category;
    final bank = ref.watch(questionBankProvider).value;
    // Sınıfa özgü odak seti — sorular bankadan gelir, uydurma soru yoktur (Faz E5).
    final focus = bank == null
        ? const []
        : licenceFocusQuestions(bank.questions, licence);
    final focusId = switch (licence) {
      LicenceCategory.a => 'motosiklet-odakli',
      LicenceCategory.d => 'otobus-odakli',
      LicenceCategory.b => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Pratik')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s10),
          children: [
            const HubHeader(
              title: 'Pratik & Sınav',
              subtitle: 'Akıllı çalışma, gerçek MEB formatında denemeler ve koleksiyonlarla pekiştir.',
              mascot: AppImages.owlTeacher,
            ),
            const SizedBox(height: AppSpacing.s4),
            // Dürüst bilgilendirme (Faz E5): teori sınavı sınıftan bağımsızdır — ayrı bir sınav
            // uydurulmaz. Sınıfa özgü fark içerikte ve araç tekniğindedir.
            const AppCallout(
              tone: CalloutTone.info,
              title: 'Teori sınavı tüm sınıflarda ortaktır',
              text:
                  'e-Sınav **B, A ve D için aynıdır**: 50 soru · 45 dakika · aynı konu dağılımı. Sınıfına özgü olan araç tekniği, mekanik ve mevzuat farkıdır — onları **Öğren > Dersler**\'deki "Sınıfına özel" bölümünde bulursun.',
            ),
            const SizedBox(height: AppSpacing.s5),
            if (focusId != null && focus.isNotEmpty) ...[
              HubRow(
                icon: licence == LicenceCategory.a
                    ? Icons.two_wheeler_rounded
                    : Icons.directions_bus_rounded,
                color: p.green,
                title: '${licence.badge} Sınıfı Odak Seti',
                subtitle: 'Bankadaki ${licence.title.toLowerCase()} konulu gerçek sorular',
                count: '${focus.length}',
                onTap: () => context.push('/practice/collection/$focusId'),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],
            HubRow(
              icon: Icons.bolt_rounded,
              color: p.accent,
              title: 'Akıllı Çalışma',
              subtitle: 'Aralıklı tekrar ile zayıf konulara odaklan',
              onTap: () => context.push('/practice/study'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.timer_outlined,
              color: p.primary,
              title: 'Deneme Sınavı',
              subtitle: '50 soru · 45 dk · MEB dağılımı (23/12/9/6)',
              onTap: () => _startExam(context, ref),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.grid_view_rounded,
              color: p.blue,
              title: 'Koleksiyonlar',
              subtitle: 'Günün Sınavı, Zor Sorular, Yalnız İşaretler…',
              onTap: () => context.push('/practice/collections'),
            ),
            const SizedBox(height: AppSpacing.s3),
            HubRow(
              icon: Icons.history_edu_rounded,
              color: p.purple,
              title: 'Geçmiş Sınavlar',
              subtitle: 'MEB formatında hazırlanmış özgün deneme sınavları',
              onTap: () => context.push('/practice/historical'),
            ),
          ],
        ),
      ),
    );
  }

  void _startExam(BuildContext context, WidgetRef ref) {
    final owned = ref.read(entitlementsProvider);
    final quota = ref.read(quotaRepositoryProvider).value;
    if (quota != null && !quota.canStartExam(owned)) {
      // Ücretsiz kota doldu → bağlamsal premium teşviki (açık kullanıcı eylemi).
      showPremiumIncentive(context, trigger: PremiumTrigger.examQuota);
      return;
    }
    quota?.consumeExam(owned);
    context.push('/practice/exam');
  }
}
