import 'dart:io';

import 'package:ehliyet_akademi/core/dash_assets.dart';
import 'package:ehliyet_akademi/domain/content/dash_lights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E3 — gösterge paneli ikaz ışıkları kütüphanesi.
void main() {
  group('ikaz ışığı kataloğu', () {
    test('60 ışık, benzersiz kimlik, dolu içerik', () {
      expect(kDashLights.length, 60);
      final ids = <String>{};
      for (final l in kDashLights) {
        expect(ids.add(l.id), isTrue, reason: '${l.id} tekrar ediyor');
        expect(l.id, matches(RegExp(r'^[a-z0-9-]+$')));
        expect(l.name.trim(), isNotEmpty);
        expect(l.meaning.trim().length, greaterThan(25), reason: '${l.id} anlamı çok kısa');
        expect(l.tip.trim().length, greaterThan(10), reason: '${l.id} ipucu çok kısa');
      }
    });

    test('her ışığın ikonu var ve dosya diskte', () {
      for (final l in kDashLights) {
        expect(l.asset, isNotNull, reason: '${l.id} ikonu yok');
        expect(File(l.asset!).existsSync(), isTrue, reason: '${l.asset} yok');
      }
    });

    test('assets/dash içinde ölü varlık yok', () {
      final used = kDashLights.map((l) => l.asset).toSet();
      final onDisk = Directory('assets/dash')
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.webp'))
          .toSet();
      expect(onDisk.difference(used.cast<String>()), isEmpty);
      expect(kDashAsset.length, kDashLights.length);
    });

    test('boyut bütçesi — ikonlar küçük kalmalı', () {
      var total = 0;
      for (final l in kDashLights) {
        final size = File(l.asset!).lengthSync();
        expect(size, lessThanOrEqualTo(16 * 1024), reason: '${l.id} çok büyük');
        total += size;
      }
      expect(total, lessThanOrEqualTo(300 * 1024));
    });

    test('her önem düzeyi temsil ediliyor ve etiketi var', () {
      for (final s in DashSeverity.values) {
        expect(kDashLights.where((l) => l.severity == s), isNotEmpty, reason: '$s boş');
        expect(s.label.trim(), isNotEmpty);
      }
      // kırmızı grubu gerçekten "dur" gerektirenler olmalı — en az 10 ışık
      expect(kDashLights.where((l) => l.severity == DashSeverity.kirmizi).length, greaterThan(10));
    });
  });

  group('ekranlar', () {
    testWidgets('galeri açılır, önem filtresi ve arama çalışır', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('İkaz Işıkları'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İkaz Işıkları'));
      await tester.pumpAndSettle();

      expect(find.text('Fren Sistemi Uyarısı'), findsOneWidget);

      // önem filtresi: yalnız "dur" gerektirenler kalsın
      await tester.tap(find.text('Dur ve kontrol et'));
      await tester.pumpAndSettle();
      expect(find.text('Fren Sistemi Uyarısı'), findsOneWidget);
      expect(find.text('Sol Sinyal'), findsNothing);

      // arama, filtreyle birlikte çalışır
      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abs');
      await tester.pumpAndSettle();
      expect(find.text('ABS Uyarısı'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();
      expect(find.text('Sonuç yok'), findsOneWidget);
    });

    testWidgets('detay ekranı anlam, ipucu ve eylem düzeyini gösterir', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('İkaz Işıkları'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İkaz Işıkları'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yağ Basıncı Uyarısı'));
      await tester.pumpAndSettle();

      expect(find.text('Anlamı'), findsOneWidget);
      expect(find.text('🧠 Hafıza tekniği'), findsOneWidget);
      expect(find.text('Dur ve kontrol et'), findsOneWidget);
    });
  });
}
