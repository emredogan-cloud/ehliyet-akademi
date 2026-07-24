import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../design/app_card.dart';
import '../../design/markdown_text.dart';
import '../../design/primitives.dart';
import '../../domain/content/content_enums.dart';
import '../../domain/onboarding/study_profile.dart';
import '../../domain/practice/question.dart';
import '../../domain/practice/question_bank.dart';
import '../../domain/practice/srs.dart';
import '../../domain/premium/premium_prompt.dart';
import '../premium/premium_popups.dart';
import 'widgets/bank_scope.dart';
import 'widgets/question_view.dart';
import 'widgets/result_view.dart';

/// Akıllı çalışma (SRS) — vadesi gelen + zayıf konu ağırlıklı oturum; oturum boyu kullanıcının
/// kişiselleştirme profilindeki günlük hedeften türetilir (yoğun tempo → daha uzun oturum). Her
/// cevaptan sonra anında geri bildirim + açıklama; SM-2 kartları güncellenir. Çevrimdışı + kalıcı.
class PracticeRunnerScreen extends ConsumerStatefulWidget {
  const PracticeRunnerScreen({super.key});

  @override
  ConsumerState<PracticeRunnerScreen> createState() => _PracticeRunnerScreenState();
}

class _PracticeRunnerScreenState extends ConsumerState<PracticeRunnerScreen> {
  List<Question> _queue = const [];
  int _index = 0;
  int? _picked;
  bool _revealed = false;
  int _correct = 0;
  bool _built = false;
  bool _done = false;
  int _startMs = 0;
  late Map<String, SrsCard> _cards;
  late ProgressRepository _progress;

  void _ensureBuilt(QuestionBank bank, ProgressRepository progress) {
    if (_built) return;
    _progress = progress;
    _cards = progress.loadCards();
    final now = DateTime.now().millisecondsSinceEpoch;
    _startMs = now;
    final stats = statsFromAnswers(progress.loadAnswers());
    final pool = bank.questions.where((q) => q.subject != Subject.pratik).toList();
    final byId = {for (final q in pool) q.id: q};
    // Oturum boyu = kişisel günlük hedef (10..25 sınırlı).
    final sessionSize = ref.read(studyProfileProvider).sessionSize;
    final ids = selectNext(pool, _cards, stats.topicMastery, now, sessionSize);
    _queue = ids.map((i) => byId[i]).whereType<Question>().toList();
    _built = true;
  }

  void _choose(int idx) {
    if (_revealed) return;
    final q = _queue[_index];
    final correct = idx == q.answerIndex;
    final now = DateTime.now().millisecondsSinceEpoch;
    final card = _cards[q.id] ?? newCard(q.id, now);
    _cards[q.id] = review(card, toGrade(correct ? 'good' : 'again'), now);
    _progress.saveCards(_cards);
    _progress.appendAnswers([
      AnswerLog(questionId: q.id, subject: q.subject, topic: q.topic, correct: correct, at: now),
    ]);
    _progress.touchStreak(now);
    setState(() {
      _picked = idx;
      _revealed = true;
      if (correct) _correct += 1;
    });
  }

  void _next() {
    if (_index < _queue.length - 1) {
      setState(() {
        _index += 1;
        _picked = null;
        _revealed = false;
      });
    } else {
      setState(() => _done = true);
      // Oturum tamamlandı → bağlamsal premium teşviki (sık-gösterim sınırlı).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          maybeShowPremiumIncentive(context, ref, PremiumTrigger.engagement,
              nowMs: DateTime.now().millisecondsSinceEpoch);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akıllı Çalışma')),
      body: SafeArea(
        top: false,
        child: ref
            .watch(progressRepositoryProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const AppEmptyState(emoji: '⚠️', title: 'İlerleme yüklenemedi'),
              data: (progress) => PracticeContentBuilder(
                builder: (context, bank) {
                  _ensureBuilt(bank, progress);
                  if (_queue.isEmpty) {
                    return const AppEmptyState(
                      emoji: '🎉',
                      title: 'Şu an çalışılacak soru yok',
                      subtitle: 'Daha sonra tekrar gel — vadesi gelen kartlar burada birikir.',
                    );
                  }
                  return _done ? _doneView() : _questionView();
                },
              ),
            ),
      ),
    );
  }

  Widget _questionView() {
    final p = context.palette;
    final q = _queue[_index];
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_index + (_revealed ? 1 : 0)) / _queue.length,
          minHeight: 3,
          backgroundColor: p.surface3,
          color: p.primary,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s6),
            children: [
              QuestionStem(question: q, index: _index, total: _queue.length),
              const SizedBox(height: AppSpacing.s5),
              for (var i = 0; i < q.options.length; i++)
                OptionTile(
                  letter: optionLetter(i),
                  text: q.options[i],
                  state: _optionState(q, i),
                  onTap: _revealed ? null : () => _choose(i),
                ),
              if (_revealed) ...[
                const SizedBox(height: AppSpacing.s2),
                _Explanation(question: q, correct: _picked == q.answerIndex),
              ],
            ],
          ),
        ),
        if (_revealed)
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s3),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _next,
                icon: Icon(
                  _index < _queue.length - 1 ? Icons.arrow_forward_rounded : Icons.flag_rounded,
                  size: 18,
                ),
                label: Text(_index < _queue.length - 1 ? 'Sonraki soru' : 'Bitir'),
              ),
            ),
          ),
      ],
    );
  }

  OptionState _optionState(Question q, int i) {
    if (!_revealed) return OptionState.idle;
    if (i == q.answerIndex) return OptionState.correct;
    if (i == _picked) return OptionState.wrong;
    return OptionState.idle;
  }

  Widget _doneView() {
    final p = context.palette;
    final total = _queue.length;
    final pct = total == 0 ? 0 : (_correct / total * 100).round();
    final wrong = total - _correct;
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - _startMs) / 1000).round();
    String fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return SessionResultView(
      title: 'Oturum tamam!',
      subtitle: 'Harika! Bugünkü hedefin için büyük bir adım attın.',
      percent: pct,
      accent: p.primary,
      stats: [
        ResultStat(icon: Icons.check_circle_rounded, color: p.green, value: '$_correct', label: 'Doğru'),
        ResultStat(icon: Icons.cancel_rounded, color: p.red, value: '$wrong', label: 'Yanlış'),
        ResultStat(icon: Icons.schedule_rounded, color: p.purple, value: fmt(elapsed), label: 'Süre'),
      ],
      actions: [
        ResultAction(
          label: 'Yeni oturum',
          icon: Icons.refresh_rounded,
          primary: true,
          onTap: () => setState(() {
            _built = false;
            _done = false;
            _index = 0;
            _correct = 0;
            _picked = null;
            _revealed = false;
          }),
        ),
        ResultAction(label: 'Ana sayfaya dön', icon: Icons.home_rounded, onTap: () => context.go('/home')),
      ],
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.question, required this.correct});
  final Question question;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = correct ? p.green : p.red;
    return AppCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 18),
              const SizedBox(width: 6),
              Text(correct ? 'Doğru!' : 'Yanlış',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          MarkdownText(question.explanation, style: TextStyle(color: p.text2, height: 1.5, fontSize: 14)),
          if (question.whyWrong.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            for (final w in question.whyWrong)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: p.text3)),
                    Expanded(
                      child: MarkdownText(w, style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
