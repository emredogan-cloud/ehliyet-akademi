import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import 'markdown_text.dart';

/// Blok-düzeyi markdown-hafif oluşturucu (AI Koç yanıtları için): başlıklar (#/##/###), madde
/// listeleri (- / *), yatay çizgi (---), paragraflar + satır-içi `**kalın**`. LLM yanıtları bu
/// biçimi kullanır; ders içeriği yalnız `**kalın**` kullandığından orada [MarkdownText] yeterlidir.
class MarkdownBlock extends StatelessWidget {
  const MarkdownBlock(this.text, {super.key, this.baseColor, this.baseSize = 14.5});

  final String text;
  final Color? baseColor;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = baseColor ?? p.text;
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final blocks = <Widget>[];

    void addSpacing() {
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: AppSpacing.s2));
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        addSpacing();
        blocks.add(Divider(color: p.border, height: AppSpacing.s3));
        continue;
      }
      if (trimmed.startsWith('### ')) {
        addSpacing();
        blocks.add(_heading(trimmed.substring(4), color, baseSize + 1.5));
        continue;
      }
      if (trimmed.startsWith('## ')) {
        addSpacing();
        blocks.add(_heading(trimmed.substring(3), color, baseSize + 3));
        continue;
      }
      if (trimmed.startsWith('# ')) {
        addSpacing();
        blocks.add(_heading(trimmed.substring(2), color, baseSize + 5));
        continue;
      }
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        // Girinti seviyesi (2 boşluk = 1 kademe).
        final indent = (raw.length - raw.trimLeft().length) ~/ 2;
        blocks.add(_bullet(trimmed.substring(2), color, indent));
        continue;
      }
      // Numaralı liste "1. " → madde gibi.
      final numbered = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(trimmed);
      if (numbered != null) {
        blocks.add(_ordered(numbered.group(1)!, numbered.group(2)!, color));
        continue;
      }
      blocks.add(_paragraph(trimmed, color));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  Widget _heading(String t, Color color, double size) => Padding(
    padding: const EdgeInsets.only(top: 2, bottom: 2),
    child: Text.rich(
      TextSpan(children: MarkdownText.spansOf(t)),
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1.3),
    ),
  );

  Widget _paragraph(String t, Color color) => Text.rich(
    TextSpan(children: MarkdownText.spansOf(t)),
    style: TextStyle(fontSize: baseSize, height: 1.5, color: color),
  );

  Widget _bullet(String t, Color color, int indent) => Padding(
    padding: EdgeInsets.only(left: 8.0 + indent * 14, top: 2, bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: TextStyle(color: color, fontSize: baseSize, height: 1.5)),
        Expanded(
          child: Text.rich(
            TextSpan(children: MarkdownText.spansOf(t)),
            style: TextStyle(fontSize: baseSize, height: 1.5, color: color),
          ),
        ),
      ],
    ),
  );

  Widget _ordered(String n, String t, Color color) => Padding(
    padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$n. ', style: TextStyle(color: color, fontSize: baseSize, height: 1.5, fontWeight: FontWeight.w700)),
        Expanded(
          child: Text.rich(
            TextSpan(children: MarkdownText.spansOf(t)),
            style: TextStyle(fontSize: baseSize, height: 1.5, color: color),
          ),
        ),
      ],
    ),
  );
}
