import 'dart:convert';

import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/content_queries.dart';
import 'package:ehliyet_akademi/domain/content/content_snapshot.dart';
import 'package:ehliyet_akademi/domain/content/lesson.dart';
import 'package:ehliyet_akademi/domain/content/traffic_sign.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('content model json', () {
    test('TrafficSign enum @JsonValue maps Turkish/hyphenated wire values', () {
      final sign = TrafficSign.fromJson(const {
        'id': 'yol-ver',
        'category': 'oncelik',
        'name': 'Yol Ver',
        'shape': 'inv-triangle',
        'meaning': 'Yol ver.',
        'memoryTip': 'Ters üçgen',
        'examImportance': 'çok yüksek',
        'keywords': ['yol', 'ver'],
      });
      expect(sign.shape, SignShape.invTriangle);
      expect(sign.examImportance, ExamImportance.cokYuksek);
      expect(sign.category, SignCategory.oncelik);
      // round-trip preserves the wire value
      expect(sign.toJson()['shape'], 'inv-triangle');
      expect(sign.toJson()['examImportance'], 'çok yüksek');
    });

    test('Lesson parses nested sections/callout/compare with defaults', () {
      final lesson = Lesson.fromJson(const {
        'id': 'l',
        'slug': 'l',
        'no': 1,
        'subject': 'motor',
        'title': 'Motor Temeli',
        'summary': 'Motorun temelleri.',
        'minutes': 8,
        'objectives': ['Öğren'],
        'sections': [
          {
            'heading': 'Giriş',
            'body': 'Metin',
            'callout': {'tone': 'warning', 'text': 'Dikkat'},
          },
        ],
      });
      expect(lesson.subject, Subject.motor);
      expect(lesson.sections.single.callout!.tone, CalloutTone.warning);
      // defaults applied for omitted arrays
      expect(lesson.tips, isEmpty);
      expect(lesson.premium, isFalse);
    });

    test('ContentSnapshot round-trips through json', () {
      final snap = sampleSnapshot();
      // Mirrors the offline cache path: encode to a JSON string, decode back, parse.
      final restored = ContentSnapshot.fromJson(
        jsonDecode(jsonEncode(snap.toJson())) as Map<String, dynamic>,
      );
      expect(restored.counts.signs, snap.counts.signs);
      expect(restored.signs.length, snap.signs.length);
      expect(restored.lessons.first.slug, 'trafik-temel');
      expect(restored.signs.firstWhere((s) => s.id == 'azami-30').glyphText, '30');
    });
  });

  group('content queries', () {
    final snap = sampleSnapshot();

    test('groups signs by category and finds by id', () {
      final byCat = snap.signsByCategory();
      expect(byCat[SignCategory.oncelik]!.single.id, 'dur');
      expect(snap.signById('kaygan-yol')!.glyph, 'slippery');
      expect(snap.signById('yok'), isNull);
    });

    test('groups lessons by subject and parts by system', () {
      final bySubject = snap.lessonsBySubject();
      expect(bySubject[Subject.trafik]!.single.slug, 'trafik-temel');
      expect(bySubject[Subject.ilkyardim], isNotNull);
      final bySystem = snap.partsBySystem();
      expect(bySystem[VehicleSystem.motorBolmesi]!.single.id, 'engine-bay');
    });

    test('lessonBySlug / videoById lookups', () {
      expect(snap.lessonBySlug('ilk-yardim-temel')!.title, 'İlk Yardım Temeli');
      expect(snap.videoById('parallel-park')!.isAvailable, isTrue);
      expect(snap.videoById('planned-video')!.isAvailable, isFalse);
    });
  });
}
