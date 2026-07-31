import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/analytics_ref.dart';
import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../design/coach_marks.dart';
import '../../design/readiness_ring.dart';
import '../onboarding/product_tour.dart';
import 'widgets/ai_welcome_dialog.dart';
import '../../domain/coach/nudge.dart';
import '../../domain/onboarding/ai_welcome_controller.dart';
import '../../domain/onboarding/coach_marks_controller.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/practice/srs.dart';
import '../../domain/progress/gamification.dart';
import '../premium/conversion_flow.dart';

/// Home — the app's center, bound to real local progress (readiness, streak, accuracy, a proactive
/// nudge, today's personalized plan). Falls back to gentle "get started" copy before any practice.
///
/// Beta R1: Ana Sayfa GÖRÜNDÜKTEN SONRA, ilk kare çizildiğinde bir kez AI karşılama popup'ı
/// açılır. Onboarding'e sayfa EKLENMEZ — kullanıcı önce ürünü görür, tanıtım sonra gelir.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // İLK KARE ÇİZİLDİKTEN SONRA: kullanıcı Ana Sayfa'yı görür, popup onun üstüne gelir.
    // `build` içinde açmak, ekran daha çizilmeden diyalog göstermek olurdu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFirstRunSequence());
  }

  /// İlk açılış SIRASI: AI karşılama penceresi → ürün turu → (Faz 4/5) tutundurma hatırlatması.
  ///
  /// Sıra bilinçli ve **seri**: ikisi aynı anda açılırsa karartma pencerenin üstüne biner ve
  /// kullanıcı ikisini de göremez. Pencere kapanmadan tur başlamaz.
  ///
  /// Tutundurma penceresi EN SONA konur ve yalnız ilk açılış zinciri bittiğinde bakılır: yeni
  /// kullanıcı daha uygulamayı görmeden "premium paketine bakmıştın" demek anlamsızdır (zaten
  /// koşulları da sağlanmaz, ama sıranın kendisi bunu garanti eder).
  Future<void> _runFirstRunSequence() async {
    await _maybeShowAiWelcome();
    await _maybeStartTour();
    if (!mounted) return;
    await maybeShowRetentionPrompt(
      context,
      ref,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _maybeShowAiWelcome() async {
    if (!mounted || ref.read(aiWelcomeSeenProvider)) return;
    await AiWelcomeDialog.show(context);
    // HANGİ YOLLA kapanırsa kapansın (CTA · zemin · geri tuşu) işaret buraya gelir.
    await ref.read(aiWelcomeSeenProvider.notifier).markSeen();
  }

  /// Faz 1 — ürün turu.
  ///
  /// Ev sahibi KABUKTA olduğu için Ana Sayfa yalnız "başlat" der; turun nasıl çizileceğini bilmez.
  /// Tur ister bitsin ister atlansın, işaret aynı yere konur: kullanıcı turu istemediğini
  /// söylediyse her açılışta ısrar etmek rahatsız edicidir.
  Future<void> _maybeStartTour() async {
    if (!mounted || ref.read(coachMarksSeenProvider)) return;
    final host = CoachMarkHost.maybeOf(context);
    if (host == null) return; // kabuk dışında (tekil widget testi) — tur yok, ekran çalışır.
    ref.track(AnalyticsEvent.coachMarksStarted);
    await host.start(
      productTourSteps,
      onFinished: (outcome, atStep, total) {
        ref.read(coachMarksSeenProvider.notifier).markSeen();
        ref.track(
          outcome == CoachMarkOutcome.completed
              ? AnalyticsEvent.coachMarksCompleted
              : AnalyticsEvent.coachMarksSkipped(atStep: atStep, totalSteps: total),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = ref.watch(progressRepositoryProvider).value;
    final profile = ref.watch(studyProfileProvider);
    final answers = progress?.loadAnswers() ?? const [];
    final readiness = answers.isNotEmpty ? progress!.readiness() : null;
    final streak = progress?.loadStreak() ?? StreakState.empty;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dueCount = progress == null
        ? 0
        : progress.loadCards().values.where((c) => c.dueAt <= now).length;
    final correct = answers.where((a) => a.correct).length;
    final accuracy = answers.isEmpty ? 0 : (correct / answers.length * 100).round();
    final level = levelForXp(xpFromAnswers(answers));

    final nudges = computeNudges(
      readiness: readiness,
      streak: streak,
      dueCount: dueCount,
      answered: answers.length,
      nowMs: now,
    );
    final topNudge = nudges.isNotEmpty ? nudges.first : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s10),
          children: [
            // Header
            Row(
              children: [
                const BrandMark(size: 46),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Merhaba 👋', style: TextStyle(color: p.text3, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Bugün de çalışalım', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                _NotificationBell(hasNudge: topNudge != null, onTap: () => context.push('/notifications')),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),

            // Readiness summary → full progress screen
            CoachAnchor(
              id: ProductTourAnchors.home,
              child: GlowCard(
              onTap: () => context.push('/progress'),
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  ReadinessRing(value: (readiness?.overall ?? 0) / 100),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Sınava hazırlık', style: Theme.of(context).textTheme.titleMedium)),
                            Icon(Icons.chevron_right_rounded, color: p.text3),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          readiness?.message ?? 'Çözmeye başla — ilerlemen ve zayıf konuların burada belirir.',
                          style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        // Faz 12 — üç istatistik kartın genişliğini PAYLAŞIR.
                        //
                        // Sabit aralıklı hâli, sayılar büyüdükçe (1250 soru, Lv 12) ve büyük
                        // sistem yazısında satırı taşırıyordu. Taşma cihazda sarı-siyah şeritli
                        // bir kare demek; kırpmak yerine paylaştırmak doğru çözüm.
                        //
                        // ARALARINDAKİ BOŞLUK ZORUNLU. `StatTile` içeriğini SOLA yaslar; paylar
                        // bitişik olduğunda geniş bir değer kendi payını doldurup komşusuna
                        // DEĞİYOR. Cihazda görüldü: %100 doğruluk + Lv 1 yan yana "%100Lv 1"
                        // olarak okunuyordu. Uygulamadaki diğer bütün `StatTile` satırları
                        // (davet ekranı, topluluk profili) zaten `s3` ile ayrılmış — burası
                        // ayrık kalmıştı.
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                value: '${answers.length}',
                                label: 'soru',
                                color: p.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s3),
                            Expanded(child: StatTile(value: '%$accuracy', label: 'doğruluk')),
                            const SizedBox(width: AppSpacing.s3),
                            Expanded(
                              child: StatTile(
                                value: 'Lv ${level.level}',
                                label: 'seviye',
                                color: p.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),

            // AI Koç hero
            CoachAnchor(id: ProductTourAnchors.aiCoach, child: _CoachHero(nudge: topNudge)),
            const SizedBox(height: AppSpacing.s2),

            SectionTitle('Bugünkü plan'),
            GlowCard(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                children: [
                  _PlanRow(
                    icon: Icons.bolt_rounded,
                    color: p.primary,
                    text: 'Akıllı çalışma oturumu (${profile.sessionSize} soru)',
                    done: streak.lastDay == _todayKey(now),
                    onTap: () => context.go('/practice/study'),
                  ),
                  Divider(height: AppSpacing.s5, color: p.border),
                  _PlanRow(
                    icon: Icons.refresh_rounded,
                    color: p.accent,
                    text: dueCount > 0 ? 'Tekrar zamanı gelen $dueCount kart' : 'Vadesi gelen kart yok',
                    done: dueCount == 0 && answers.isNotEmpty,
                    onTap: () => context.go('/practice/study'),
                  ),
                  Divider(height: AppSpacing.s5, color: p.border),
                  _PlanRow(
                    icon: Icons.assignment_turned_in_rounded,
                    color: p.green,
                    text: '1 deneme sınavı',
                    onTap: () => context.go('/practice/exam'),
                  ),
                ],
              ),
            ),

            SectionTitle('Hızlı işlemler'),
            // Faz 1: Ana Sayfa GERÇEK bir merkez oldu — turda tanıtılan her özelliğin buradan bir
            // girişi var. Eskiden "Çıkmış Sınavlar" ve "Premium" yalnız alt sayfalarda duruyordu;
            // kullanıcı ikisini de tesadüfen bulmak zorundaydı.
            Row(
              children: [
                CoachAnchor(
                  id: ProductTourAnchors.practiceExam,
                  child: _QuickTile(
                    icon: Icons.timer_outlined,
                    label: 'Deneme\nSınavı',
                    color: p.primary,
                    onTap: () => context.go('/practice/exam'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                CoachAnchor(
                  id: ProductTourAnchors.smartStudy,
                  child: _QuickTile(
                    icon: Icons.bolt_rounded,
                    label: 'Akıllı\nÇalışma',
                    color: p.accent,
                    onTap: () => context.go('/practice/study'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                CoachAnchor(
                  id: ProductTourAnchors.realExam,
                  child: _QuickTile(
                    icon: Icons.history_edu_rounded,
                    label: 'Çıkmış\nSınavlar',
                    color: p.green,
                    onTap: () => context.go('/practice/historical'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                _QuickTile(
                  icon: Icons.traffic_rounded,
                  label: 'İşaretler',
                  color: p.blue,
                  onTap: () => context.go('/learn/signs'),
                ),
                const SizedBox(width: AppSpacing.s3),
                _QuickTile(
                  icon: Icons.play_circle_outline_rounded,
                  label: 'Video\nDersler',
                  color: p.purple,
                  onTap: () => context.go('/learn/videos'),
                ),
                const SizedBox(width: AppSpacing.s3),
                CoachAnchor(
                  id: ProductTourAnchors.premium,
                  child: _QuickTile(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Premium',
                    color: p.accent,
                    onTap: () => context.push('/premium?from=home'),
                  ),
                ),
              ],
            ),

            SectionTitle('İlerleme'),
            CoachAnchor(
              id: ProductTourAnchors.progress,
              child: GlowCard(
              onTap: () => context.push('/progress'),
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  IconBadge(icon: Icons.insights_rounded, color: p.primary, size: 52, glow: true),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('İstatistiklerim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 3),
                        Text('Radar, çalışma haritası, rozetler ve seviyeni gör',
                            style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: p.text3),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _todayKey(int nowMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)}';
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasNudge, required this.onTap});
  final bool hasNudge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      onPressed: onTap,
      tooltip: 'Bildirimler',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, color: p.text2, size: 26),
          if (hasNudge)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle, border: Border.all(color: p.bg, width: 1.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoachHero extends StatelessWidget {
  const _CoachHero({this.nudge});
  final Nudge? nudge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = nudge?.body ?? 'İlk 10 soruyla başlayalım — birkaç dakikada temeli at.';
    final cta = nudge?.title ?? 'Hoş geldin!';
    final action = nudge?.action ?? '/practice/study';
    return GlowCard(
      accentColor: p.primary,
      selected: true,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, 0, AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Faz 12 — başlık dar cihazlarda (320 dp) maskotun yanında sıkışıp taşıyordu.
                // `Flexible` + küçültme, rozet ve başlığı bir arada tutar.
                Row(
                  children: [
                    IconBadge(icon: Icons.auto_awesome_rounded, color: p.primary, size: 40),
                    const SizedBox(width: AppSpacing.s3),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'AI Koç',
                          maxLines: 1,
                          style: TextStyle(
                            color: p.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                Text('👋 $body', style: TextStyle(color: p.text, fontSize: 14, height: 1.4)),
                const SizedBox(height: AppSpacing.s3),
                IntrinsicWidth(
                  child: GradientPillButton(
                    label: cta,
                    height: 46,
                    onPressed: () => GoRouter.of(context).go(action),
                  ),
                ),
              ],
            ),
          ),
          MascotImage(AppImages.owlWheel, height: 150, semanticLabel: 'AI Koç'),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: GlowCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3, horizontal: 4),
        child: Column(
          children: [
            IconBadge(icon: icon, color: color, size: 46, glow: true),
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              height: 30,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.text2, height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.text, required this.color, this.done = false, this.onTap});
  final IconData icon;
  final String text;
  final Color color;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      // Faz 12 — dokunma hedefi EN AZ 48 dp.
      //
      // Satır 30 dp yükseklikteydi; Android erişilebilirlik yönergesi (ve Play tarama denetimi)
      // 48 dp ister. Motor becerisi kısıtlı kullanıcılar için küçük hedefler ekranı kullanılamaz
      // yapar. Görsel yoğunluk korunuyor — yalnız dokunulabilir alan büyüdü.
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle_rounded : icon, color: done ? p.green : color, size: 22),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: done ? p.text3 : p.text,
                  decoration: done ? TextDecoration.lineThrough : null,
                  fontSize: 14,
                ),
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right_rounded, color: p.text3, size: 20),
          ],
        ),
      ),
    );
  }
}
