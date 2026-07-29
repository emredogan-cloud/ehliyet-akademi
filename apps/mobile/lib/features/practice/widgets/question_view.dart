import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../design/markdown_text.dart';
import '../../../domain/practice/question.dart';

/// Soru gövdesi — ders/konu etiketi + kök metin (markdown-hafif).
class QuestionStem extends StatelessWidget {
  const QuestionStem({super.key, required this.question, required this.index, required this.total});
  final Question question;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: 3),
              decoration: BoxDecoration(
                color: p.primary050,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                '${question.subject.label} · ${question.difficulty.label}',
                style: TextStyle(color: p.primary, fontWeight: FontWeight.w700, fontSize: 11.5),
              ),
            ),
            const Spacer(),
            Text(
              '${index + 1} / $total',
              style: TextStyle(color: p.text3, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        MarkdownText(
          question.stem,
          style: TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600, color: p.text),
        ),
      ],
    );
  }
}

/// Bir seçenek satırı (A/B/C/D). [state] görsel durumu belirler.
enum OptionState { idle, picked, correct, wrong }

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    this.onTap,
  });
  final String letter;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, border, fg, accent, filledBadge) = switch (state) {
      OptionState.idle => (p.surface2, p.border, p.text, p.text3, false),
      OptionState.picked => (p.primary.withValues(alpha: 0.10), p.primary, p.text, p.primary, true),
      OptionState.correct => (p.green.withValues(alpha: 0.12), p.green, p.text, p.green, true),
      OptionState.wrong => (p.red.withValues(alpha: 0.12), p.red, p.text, p.red, true),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.base),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.base),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.base),
              border: Border.all(color: border, width: state == OptionState.idle ? 1 : 1.6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filledBadge ? accent : accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: filledBadge ? Colors.white : accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: MarkdownText(text, style: TextStyle(color: fg, height: 1.35, fontSize: 14.5)),
                ),
                const SizedBox(width: AppSpacing.s2),
                _trailing(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing(AppPalette p) {
    switch (state) {
      case OptionState.correct:
        return _dot(p.green, Icons.check_rounded);
      case OptionState.wrong:
        return _dot(p.red, Icons.close_rounded);
      case OptionState.picked:
        return _dot(p.primary, Icons.check_rounded);
      case OptionState.idle:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.borderStrong, width: 2)),
        );
    }
  }

  Widget _dot(Color c, IconData i) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        child: Icon(i, size: 15, color: Colors.white),
      );
}

/// Sıradan harfe: 0→A, 1→B, 2→C, 3→D. (Kural `domain/practice/question.dart` içinde.)
String optionLetter(int index) => String.fromCharCode(65 + index);
