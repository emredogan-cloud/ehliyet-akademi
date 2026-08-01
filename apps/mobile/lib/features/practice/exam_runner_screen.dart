import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_event.dart';
import '../../core/analytics/analytics_ref.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../data/practice/progress_repository.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/brand.dart';
import '../../data/share/share_service.dart';
import '../../design/primitives.dart';
import '../../design/share_card.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/practice/collections.dart';
import '../../domain/practice/exam.dart';
import '../../domain/practice/exam_library.dart';
import '../../domain/practice/exam_v2.dart';
import '../../domain/practice/historical.dart';
import '../../domain/practice/question.dart';
import '../../domain/practice/question_bank.dart';
import '../../domain/practice/srs.dart';
import '../../domain/premium/conversion.dart';
import '../../domain/premium/premium_prompt.dart';
import '../../domain/premium/products.dart';
import '../../domain/feedback/rating_prompt.dart';
import '../feedback/rating_dialog.dart';
import '../premium/conversion_flow.dart';
import '../premium/premium_popups.dart';
import 'widgets/bank_scope.dart';
import 'widgets/question_view.dart';
import 'widgets/result_view.dart';

enum ExamSource {
  standard,
  collection,
  historical,

  /// Ürün Evrimi v1.1 · Faz 2 — sınav kütüphanesinden gelen sınav. `id` = `<kategori>-<tarih>`.
  library,
}

/// Sınav çalıştırıcı — standart 50-soruluk deneme, koleksiyon veya geçmiş (MEB) sınavı.
/// Zamanlayıcı, soru haritası, puanlama ve ders bazlı sonuç. Tamamen çevrimdışı (bankadan kurulur).
class ExamRunnerScreen extends ConsumerStatefulWidget {
  const ExamRunnerScreen({super.key, required this.source, this.id, this.titleText});
  final ExamSource source;
  final String? id;
  final String? titleText;

  @override
  ConsumerState<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends ConsumerState<ExamRunnerScreen> {
  BuiltExam? _exam;
  late List<int?> _answers;
  final Set<int> _flagged = {};
  int _current = 0;
  int _secondsLeft = 0;
  int _elapsed = 0;
  Timer? _timer;
  bool _finished = false;
  ExamResult? _result;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureBuilt(QuestionBank bank) {
    if (_exam != null) return;
    final built = switch (widget.source) {
      // QIP v3 · Faz 5 — Üreteç V2: zorluk dengesi, görsel tekrarı engeli, şık karıştırma
      // ve karışıma görsel soru enjeksiyonu. Eski `buildExam` yerinde duruyor (koleksiyon
      // yolu ve testler onu kullanıyor).
      ExamSource.standard => buildExamV2(
        bank.questions,
        const ExamConfig(mode: ExamMode.exam, visualRatio: 0.2),
      ).exam,
      ExamSource.historical => historicalExam(bank.questions, widget.id!),
      // Kimlik çözülemezse (elle yazılmış/bayat bağlantı) standart denemeye düşülür — boş
      // ekran göstermek yerine kullanılabilir bir sınav verilir.
      ExamSource.library => () {
        final e = libraryExamById(widget.id ?? '', DateTime.now());
        return e == null
            ? buildExamV2(bank.questions, const ExamConfig(mode: ExamMode.exam, visualRatio: 0.2)).exam
            : buildLibraryExam(bank.questions, e);
      }(),
      ExamSource.collection => _fromCollection(bank),
    };
    _exam = built;
    _answers = List<int?>.filled(built.questions.length, null);
    _secondsLeft = built.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) _finish();
      });
    });
  }

  BuiltExam _fromCollection(QuestionBank bank) {
    final now = DateTime.now();
    String p(int n) => n.toString().padLeft(2, '0');
    final daySeed = seedFromDate('${now.year}-${p(now.month)}-${p(now.day)}');
    final weekSeed = seedFromDate('week:${now.year}-${p(now.month)}');
    final byId = {for (final q in bank.questions) q.id: q};
    final col = collectionById(
      bank.questions,
      widget.id!,
      daySeed: daySeed,
      weekSeed: weekSeed,
      licence: ref.read(studyProfileProvider).category,
    );
    final qs = (col?.questionIds ?? const <String>[])
        .map((i) => byId[i])
        .whereType<Question>()
        .toList();
    return BuiltExam(
      questions: qs,
      fullBlueprint: true,
      durationSeconds: qs.length * 54,
      passCorrect: (qs.length * 0.7).ceil(),
    );
  }

  void _finish() {
    _timer?.cancel();
    final exam = _exam!;
    _elapsed = exam.durationSeconds - _secondsLeft;
    final result = scoreExam(exam.questions, _answers, exam.passCorrect);
    final progress = ref.read(progressRepositoryProvider).value;
    if (progress != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final logs = [
        for (var i = 0; i < exam.questions.length; i++)
          AnswerLog(
            questionId: exam.questions[i].id,
            subject: exam.questions[i].subject,
            topic: exam.questions[i].topic,
            correct: _answers[i] == exam.questions[i].answerIndex,
            at: now,
          ),
      ];
      progress.appendAnswers(logs);
      progress.touchStreak(now);
      progress.incrementExamsFinished();
    }
    setState(() {
      _finished = true;
      _result = result;
    });

    // ── Beta Faz 3 — sınav ölçümü ────────────────────────────────────────────────────────────
    //
    // `first_exam` ETKİNLEŞME (activation) metriğidir: kullanıcının hayatındaki ilk sınavı. Cihaz
    // ömründe bir kez gider (`trackOnce`); tekrarı kurulum sayısını gerçek etkinleşmeden ayırmayı
    // imkânsız kılardı.
    //
    // `exam_completed` her sınavda gider ve `passed` boyutunu taşır. `exam_passed`/`exam_failed`
    // AYRICA gönderilir — panoda "kaç kişi geçti" sorusunu tek bir sayımla cevaplayabilmek için;
    // ikisi aynı gerçeğin iki okunuşudur, çelişemezler çünkü aynı yerden üretiliyorlar.
    ref.trackOnce(AnalyticsEvent.firstExam);
    ref.track(
      AnalyticsEvent.examCompleted(
        correct: result.correct,
        total: exam.questions.length,
        passed: result.passed,
        durationSeconds: _elapsed,
      ),
    );
    ref.track(
      result.passed
          ? AnalyticsEvent.examPassed(correct: result.correct, total: exam.questions.length)
          : AnalyticsEvent.examFailed(correct: result.correct, total: exam.questions.length),
    );
    // Deneme tamamlandı → bağlamsal pencereler (ikisi de sık-gösterim sınırlı).
    //
    // SIRA: premium teşviki ÖNCE, puanlama SONRA — ve ikisi aynı anda AÇILMAZ. Puanlama yalnız
    // üçüncü sınavda tetiklenir; premium teşviki kendi soğuma süresine tabidir. Aynı karede iki
    // pencere açmak, ikincisini birincinin arkasında bırakırdı.
    final examsFinished = progress?.examsFinished() ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (ratingTriggeredByExams(examsFinished)) {
        // Faz 7 — kullanıcı ürünün asıl işini üç kez yaptı; sormak için en iyi an bu.
        await maybeShowRatingPrompt(context, ref, RatingTrigger.examsCompleted, nowMs: nowMs);
        return;
      }
      if (!mounted) return;

      // Faz 3 — HAYATTAKİ İLK sınav: koç önce TEBRİK eder, teklif ancak kullanıcı isterse gelir.
      //
      // Eskiden burada her sınav sonunda doğrudan premium teşviki açılıyordu ve pencerenin adı
      // `firstExam` olmasına rağmen ilk sınav olup olmadığı HİÇ SORULMUYORDU — yalnız soğuma
      // süresine bakılıyordu. Yani "ilk sınavını tamamladın!" başlığı beşinci sınavdan sonra da
      // çıkabiliyordu. Artık koşul gerçekten sayıya bakıyor.
      final premium = isPremium(ref.read(entitlementsProvider));
      if (shouldRunFirstExamConversion(
        examsFinished: examsFinished,
        premium: premium,
        alreadyShown: ref.read(premiumPromptProvider).count > 0,
      )) {
        await showFirstExamConversion(
          context,
          ref,
          correct: result.correct,
          total: exam.questions.length,
          passMark: exam.passCorrect,
          nowMs: nowMs,
        );
        return;
      }

      if (mounted) {
        await maybeShowPremiumIncentive(context, ref, PremiumTrigger.engagement, nowMs: nowMs);
      }
    });
  }

  Future<void> _confirmFinish() async {
    final unanswered = _answers.where((a) => a == null).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sınavı bitir?'),
        content: Text(
          unanswered == 0
              ? 'Tüm soruları yanıtladın. Sonucu görmek ister misin?'
              : '$unanswered soru boş. Yine de bitirmek istiyor musun?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Devam et')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bitir')),
        ],
      ),
    );
    if (ok == true) _finish();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titleText ?? 'Deneme Sınavı'),
        actions: [
          if (_exam != null && !_finished)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s3),
              child: TextButton.icon(
                onPressed: _confirmFinish,
                icon: Icon(Icons.assignment_turned_in_outlined, size: 18, color: p.red),
                label: Text('Sınavı Bitir', style: TextStyle(color: p.red, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: PracticeContentBuilder(
          builder: (context, bank) {
            _ensureBuilt(bank);
            final exam = _exam!;
            if (exam.questions.isEmpty) {
              return const AppEmptyState(emoji: '🗂️', title: 'Bu set için soru bulunamadı');
            }
            if (!_finished) return _running(exam);
            // Ekran dışı paylaşım kartı ağaçta OLMALI: boyanmamış bir sınırın görüntüsü alınamaz.
            return Stack(
        // `Clip.none` ŞART — süs değil.
        //
        // `Stack` varsayılan olarak çocuklarını sınırlarına KIRPAR (`Clip.hardEdge`). Ekran dışına
        // konan paylaşım kartı bu yüzden hiç BOYANMIYOR, boyanmayan bir sınırın `toImage`'ı da
        // hiçbir zaman tamamlanmıyordu — paylaşım sonsuza kadar "Hazırlanıyor…" kalıyordu
        // (testte `pumpAndSettle` zaman aşımıyla yakalandı).
        clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _resultView(exam, _result!)),
                _offscreenShareCard(_result!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _resultView(BuiltExam exam, ExamResult result) {
    final p = context.palette;
    final pct = result.total == 0 ? 0 : (result.correct / result.total * 100).round();
    final passed = result.passed;
    final color = passed ? p.green : p.red;
    return SessionResultView(
      title: passed ? 'Tebrikler, geçtin! 🎉' : 'Bu sefer olmadı',
      subtitle: passed
          ? 'Baraj ${exam.passCorrect} doğru — sınav için hazırsın.'
          : 'Baraj ${exam.passCorrect} doğru. Zayıf konulara odaklan, tekrar dene.',
      percent: pct,
      accent: color,
      stats: [
        ResultStat(icon: Icons.check_circle_rounded, color: p.green, value: '${result.correct}', label: 'Doğru'),
        ResultStat(icon: Icons.cancel_rounded, color: p.red, value: '${result.wrong}', label: 'Yanlış'),
        ResultStat(icon: Icons.schedule_rounded, color: p.purple, value: _fmt(_elapsed), label: 'Süre'),
      ],
      extra: _SubjectCard(scores: result.perSubject),
      actions: [
        ResultAction(label: 'Bitir', icon: Icons.check_rounded, primary: true, onTap: () => context.pop()),
        // Faz 10 — sonuç TEK DOKUNUŞLA paylaşılır: kart cihazda çizilir, PNG'ye çevrilir ve
        // sistem paylaşım sayfasına verilir. Sunucuya hiçbir şey yüklenmez.
        ResultAction(
          label: _sharing ? 'Hazırlanıyor…' : 'Sonucu paylaş',
          icon: Icons.ios_share_rounded,
          onTap: _sharing ? () {} : () => _shareResult(result, exam),
        ),
        ResultAction(label: 'Ana sayfaya dön', icon: Icons.home_rounded, onTap: () => context.go('/home')),
      ],
    );
  }

  /// Paylaşılacak kartın görüntüsünü almak için sınır anahtarı.
  final GlobalKey _shareCardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareResult(ExamResult result, BuiltExam exam) async {
    setState(() => _sharing = true);
    final pct = result.total == 0 ? 0 : (result.correct / result.total * 100).round();
    final text = result.passed
        ? 'Ehliyet Akademi deneme sınavını geçtim — ${result.correct}/${result.total} doğru (%$pct)!'
        : 'Ehliyet Akademi deneme sınavı sonucum: ${result.correct}/${result.total} doğru (%$pct).';

    final png = await captureBoundary(_shareCardKey);
    final service = ref.read(shareServiceProvider);
    // Görüntü alınamazsa metin paylaşılır — kullanıcı elinde hiçbir şey olmadan kalmaz.
    final ok = png == null
        ? await service.shareText(text)
        : await service.shareImage(pngBytes: png, fileName: 'ehliyet-deneme-sonucu', text: text);
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım açılamadı.')),
      );
    }
  }

  /// Paylaşılacak kart EKRANIN DIŞINDA, SABİT ölçüde çizilir (1080×1350).
  ///
  /// Sonuç ekranının kendisini fotoğraflamak, telefon genişliğine göre değişen ve sosyal
  /// uygulamalarda kırpılan bir görsel üretirdi.
  Widget _offscreenShareCard(ExamResult result) => Positioned(
    left: -3000,
    top: 0,
    child: RepaintBoundary(
      key: _shareCardKey,
      child: ExamResultShareCard(
        correct: result.correct,
        total: result.total,
        passed: result.passed,
        durationLabel: _fmt(_elapsed),
      ),
    ),
  );

  Widget _running(BuiltExam exam) {
    final p = context.palette;
    final q = exam.questions[_current];
    final answeredCount = _answers.where((a) => a != null).length;
    final timeLow = _secondsLeft <= 60;
    return Column(
      children: [
        // Zamanlayıcı + ilerleme kartı
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s2),
          child: GlowCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 26, color: timeLow ? p.red : p.primary),
                    const SizedBox(width: AppSpacing.s2),
                    // Sayaç bloğu ESNEK: yanındaki ilerleme metniyle birlikte dar ekranda
                    // satırı taşırıyordu.
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fmt(_secondsLeft),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: timeLow ? p.red : p.text,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            'Kalan süre',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.text3, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$answeredCount / ${exam.questions.length}',
                            maxLines: 1,
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: p.primary),
                          ),
                          Text(
                            'yanıtlandı',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.text3, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    value: exam.questions.isEmpty ? 0 : answeredCount / exam.questions.length,
                    minHeight: 6,
                    backgroundColor: p.surface3,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Soru haritası (yatay şerit)
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
            itemCount: exam.questions.length,
            itemBuilder: (_, i) => _MapDot(
              number: i + 1,
              current: i == _current,
              answered: _answers[i] != null,
              flagged: _flagged.contains(i),
              onTap: () => setState(() => _current = i),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s6),
            children: [
              QuestionStem(
                question: q,
                index: _current,
                total: exam.questions.length,
                signs: ref.watch(contentSnapshotProvider).value?.signs ?? const [],
              ),
              const SizedBox(height: AppSpacing.s5),
              for (var i = 0; i < q.options.length; i++)
                OptionTile(
                  letter: optionLetter(i),
                  text: q.options[i],
                  state: _answers[_current] == i ? OptionState.picked : OptionState.idle,
                  onTap: () => setState(() => _answers[_current] = i),
                ),
            ],
          ),
        ),
        // Alt gezinme
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s3),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _current > 0 ? () => setState(() => _current -= 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  label: const Text('Önceki'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.text,
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              _FlagButton(
                flagged: _flagged.contains(_current),
                onTap: () => setState(() {
                  _flagged.contains(_current) ? _flagged.remove(_current) : _flagged.add(_current);
                }),
              ),
              Expanded(
                child: _current < exam.questions.length - 1
                    ? _NextButton(label: 'Sonraki', icon: Icons.chevron_right_rounded, onTap: () => setState(() => _current += 1))
                    : _NextButton(label: 'Bitir', icon: Icons.flag_rounded, onTap: _confirmFinish),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({required this.flagged, required this.onTap});
  final bool flagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = flagged ? p.accent : p.text3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(flagged ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: c, size: 24),
            Text('İşaretle', style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [p.primary, p.primaryBright]),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -4, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beta Faz 11 — etiket ESNEK. Dar ekranda (320 dp) ve büyük sistem yazısında
              // (1,3×) sabit metin satırı taşırıyordu. Kırpmak yerine KÜÇÜLTME seçildi:
              // bir eylemin adı yarım okunmamalı (Faz 12'de `GradientPillButton` için verilen
              // aynı karar).
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot({
    required this.number,
    required this.current,
    required this.answered,
    required this.flagged,
    required this.onTap,
  });
  final int number;
  final bool current;
  final bool answered;
  final bool flagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = current
        ? p.primary
        : answered
        ? p.primary.withValues(alpha: 0.14)
        : p.surface3;
    final fg = current
        ? Colors.white
        : answered
        ? p.primary
        : p.text3;
    final borderColor = flagged ? p.accent : (current ? p.primary : p.border);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: flagged || current ? 2 : 1),
            boxShadow: current ? [BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: -2)] : null,
          ),
          child: Text('$number', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.scores});
  final List<SubjectScore> scores;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ders bazında', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: AppSpacing.s3),
          for (final s in scores) _SubjectBar(score: s),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.score});
  final SubjectScore score;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final frac = score.total == 0 ? 0.0 : score.correct / score.total;
    final label = Subject.values.firstWhere((s) => s == score.subject).label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(color: p.text2, fontSize: 13))),
              Text('${score.correct}/${score.total}',
                  style: TextStyle(color: p.text3, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 6,
              backgroundColor: p.surface3,
              color: frac >= 0.7 ? p.green : (frac >= 0.5 ? p.accent : p.red),
            ),
          ),
        ],
      ),
    );
  }
}
