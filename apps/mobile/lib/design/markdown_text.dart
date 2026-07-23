import 'package:flutter/material.dart';

/// İçerik-hafif markdown metni — `**kalın**` işaretlemesini kalın span'e çevirir (web `mdBold`
/// eşleniği). İçerik gövdeleri bu basit biçimi kullanır; başka markdown yoktur.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static final _bold = RegExp(r'\*\*(.+?)\*\*');

  /// `**x**` → kalın span; kalan metin düz. Eşleşme yoksa tek düz span.
  static List<InlineSpan> spansOf(String text) {
    if (!text.contains('**')) return [TextSpan(text: text)];
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _bold.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(style: base, children: spansOf(text)),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
