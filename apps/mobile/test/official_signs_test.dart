import 'dart:io';

import 'package:ehliyet_akademi/core/official_signs.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/traffic_sign.dart';
import 'package:ehliyet_akademi/features/learn/widgets/traffic_sign_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evolution Faz E1 — resmî trafik levhası vektörleri.
/// Varlıklar `tool/extract_official_signs.py` ile üretilir; bu testler kataloğun bütünlüğünü ve
/// çizicinin doğru kaynağı seçtiğini garanti eder.
void main() {
  const signsDir = 'assets/signs';

  TrafficSign sign(String id, {SignShape shape = SignShape.triangle, String? glyphText}) =>
      TrafficSign(
        id: id,
        category: SignCategory.tehlike,
        name: id,
        shape: shape,
        glyphText: glyphText,
        meaning: '',
        memoryTip: '',
        examImportance: ExamImportance.orta,
      );

  group('resmî levha kataloğu', () {
    test('boş değil ve her giriş assets/signs altında bir SVG gösterir', () {
      expect(kOfficialSignAsset.length, greaterThanOrEqualTo(80));
      for (final entry in kOfficialSignAsset.entries) {
        expect(entry.key, matches(RegExp(r'^[a-z0-9-]+$')), reason: 'işaret id kebab-case olmalı');
        expect(entry.value, startsWith('$signsDir/'));
        expect(entry.value, endsWith('.svg'));
        expect(File(entry.value).existsSync(), isTrue, reason: '${entry.value} yok');
      }
    });

    test('her SVG normalize edilmiş: kare viewBox, yalnız path, raster yok', () {
      for (final path in kOfficialSignAsset.values.toSet()) {
        final svg = File(path).readAsStringSync();
        expect(svg, contains('viewBox="0 0 100 100"'), reason: '$path viewBox normalize değil');
        expect(svg.contains('<image'), isFalse, reason: '$path raster içeriyor');
        expect(svg.contains('<text'), isFalse, reason: '$path gömülü metin içeriyor');
        expect(RegExp(r'<path').allMatches(svg).length, greaterThan(0));
      }
    });

    test('performans bütçesi: levha başına eleman/boyut ve toplam boyut sınırlı', () {
      var total = 0;
      for (final path in kOfficialSignAsset.values.toSet()) {
        final svg = File(path).readAsStringSync();
        final paths = RegExp(r'<path').allMatches(svg).length;
        expect(paths, lessThanOrEqualTo(420), reason: '$path çok parçalı ($paths)');
        expect(svg.length, lessThanOrEqualTo(80 * 1024), reason: '$path çok büyük');
        total += svg.length;
      }
      expect(total, lessThanOrEqualTo(900 * 1024), reason: 'toplam levha varlığı bütçeyi aşıyor');
    });

    test('assets/signs içindeki her dosya katalogda kullanılıyor (ölü varlık yok)', () {
      final used = kOfficialSignAsset.values.toSet();
      final onDisk = Directory(signsDir)
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.svg'))
          .toSet();
      expect(onDisk.difference(used), isEmpty, reason: 'kullanılmayan levha varlığı var');
    });
  });

  group('TrafficSignView kaynak seçimi', () {
    testWidgets('resmî karşılığı olan işaret vektör varlığını çizer, üstüne metin bindirmez', (
      tester,
    ) async {
      expect(officialSignAsset('dur'), isNotNull);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: TrafficSignView(sign: sign('dur', shape: SignShape.octagon)))),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('DUR'), findsNothing); // "DUR" resmî vektörün içinde
    });

    testWidgets('resmî karşılığı olmayan işaret parametrik çizicide kalır', (tester) async {
      expect(officialSignAsset('azami-hiz-50'), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrafficSignView(
              sign: sign('azami-hiz-50', shape: SignShape.ring, glyphText: '50'),
            ),
          ),
        ),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('50'), findsOneWidget); // sayı widget olarak bindiriliyor
    });
  });
}
