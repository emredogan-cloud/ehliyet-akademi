import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../design/app_card.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/practice/collections.dart';
import '../../domain/practice/exam.dart';
import '../../domain/practice/historical.dart';
import '../../domain/practice/question.dart';
import '../../domain/practice/question_bank.dart';
import '../../domain/practice/srs.dart';
import 'widgets/bank_scope.dart';
import 'widgets/question_view.dart';

enum ExamSource { standard, collection, historical }

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
  int _current = 0;
  int _secondsLeft = 0;
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
      ExamSource.standard => buildExam(bank.questions),
      ExamSource.historical => historicalExam(bank.questions, widget.id!),
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
    final col = collectionById(bank.questions, widget.id!, daySeed: daySeed, weekSeed: weekSeed);
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.titleText ?? 'Deneme Sınavı')),
      body: SafeArea(
        top: false,
        child: PracticeContentBuilder(
          builder: (context, bank) {
            _ensureBuilt(bank);
            final exam = _exam!;
            if (exam.questions.isEmpty) {
              return const AppEmptyState(emoji: '🗂️', title: 'Bu set için soru bulunamadı');
            }
            return _finished ? _ResultView(exam: exam, result: _result!) : _running(exam);
          },
        ),
      ),
    );
  }

  Widget _running(BuiltExam exam) {
    final p = context.palette;
    final q = exam.questions[_current];
    final answeredCount = _answers.where((a) => a != null).length;
    final timeLow = _secondsLeft <= 60;
    return Column(
      children: [
        // Zamanlayıcı + ilerleme
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s2),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: timeLow ? p.red : p.text2),
              const SizedBox(width: 6),
              Text(
                _fmt(_secondsLeft),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: timeLow ? p.red : p.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text('$answeredCount/${exam.questions.length} yanıtlandı',
                  style: TextStyle(color: p.text3, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: exam.questions.isEmpty ? 0 : answeredCount / exam.questions.length,
          minHeight: 3,
          backgroundColor: p.surface3,
          color: p.primary,
        ),
        // Soru haritası (yatay şerit)
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
            itemCount: exam.questions.length,
            itemBuilder: (_, i) => _MapDot(
              number: i + 1,
              current: i == _current,
              answered: _answers[i] != null,
              onTap: () => setState(() => _current = i),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s6),
            children: [
              QuestionStem(question: q, index: _current, total: exam.questions.length),
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
              OutlinedButton.icon(
                onPressed: _current > 0 ? () => setState(() => _current -= 1) : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                label: const Text('Önceki'),
              ),
              const Spacer(),
              if (_current < exam.questions.length - 1)
                FilledButton.icon(
                  onPressed: () => setState(() => _current += 1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  label: const Text('Sonraki'),
                )
              else
                FilledButton.icon(
                  onPressed: _confirmFinish,
                  icon: const Icon(Icons.flag_rounded, size: 18),
                  label: const Text('Bitir'),
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

class _MapDot extends StatelessWidget {
  const _MapDot({required this.number, required this.current, required this.answered, required this.onTap});
  final int number;
  final bool current;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = current
        ? p.primary
        : answered
        ? p.primary050
        : p.surface3;
    final fg = current
        ? Colors.white
        : answered
        ? p.primary
        : p.text3;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: current ? p.primary : p.border),
          ),
          child: Text('$number', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.exam, required this.result});
  final BuiltExam exam;
  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final passed = result.passed;
    final pct = result.total == 0 ? 0 : (result.correct / result.total * 100).round();
    final color = passed ? p.green : p.red;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s5, AppSpacing.s4, AppSpacing.s10),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded, color: color, size: 44),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(passed ? 'GEÇTİN 🎉' : 'KALDIN',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text('Baraj ${exam.passCorrect} doğru · ${result.correct}/${result.total} doğru',
                  style: TextStyle(color: p.text3, fontSize: 13)),
              if (!exam.fullBlueprint)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('(kısaltılmış deneme)', style: TextStyle(color: p.text3, fontSize: 11.5)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Row(
          children: [
            _Stat(label: 'Başarı', value: '%$pct', color: color),
            _Stat(label: 'Doğru', value: '${result.correct}', color: p.green),
            _Stat(label: 'Yanlış', value: '${result.wrong}', color: p.red),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ders bazında', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
              const SizedBox(height: AppSpacing.s3),
              for (final s in result.perSubject) _SubjectBar(score: s),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        FilledButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Bitir'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: p.text3)),
          ],
        ),
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
