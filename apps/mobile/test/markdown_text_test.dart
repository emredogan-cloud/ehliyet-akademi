import 'package:ehliyet_akademi/design/markdown_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkdownText.spansOf', () {
    test('plain text → single span', () {
      final spans = MarkdownText.spansOf('düz metin');
      expect(spans, hasLength(1));
      expect((spans.single as TextSpan).text, 'düz metin');
    });

    test('**bold** → bold span between plain spans', () {
      final spans = MarkdownText.spansOf('renk **niyeti** söyler');
      expect(spans, hasLength(3));
      expect((spans[0] as TextSpan).text, 'renk ');
      expect((spans[1] as TextSpan).text, 'niyeti');
      expect((spans[1] as TextSpan).style!.fontWeight, FontWeight.w700);
      expect((spans[2] as TextSpan).text, ' söyler');
    });

    test('multiple bolds on one line', () {
      final spans = MarkdownText.spansOf('**a** ve **b**');
      final bold = spans.whereType<TextSpan>().where((s) => s.style?.fontWeight == FontWeight.w700);
      expect(bold.map((s) => s.text), ['a', 'b']);
    });
  });

  testWidgets('MarkdownText renders without overflow and shows text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: MarkdownText('trafik **tanzim** işareti'))),
      ),
    );
    expect(find.byType(MarkdownText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
