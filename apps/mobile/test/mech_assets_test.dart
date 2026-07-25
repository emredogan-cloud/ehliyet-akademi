import 'dart:io';

import 'package:ehliyet_akademi/core/mech_assets.dart';
import 'package:ehliyet_akademi/core/theme/app_theme.dart';
import 'package:ehliyet_akademi/design/mech_image.dart';
import 'package:ehliyet_akademi/domain/content/vehicle_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E2 — mekanik görsel kütüphanesi.
void main() {
  group('mekanik varlık kataloğu', () {
    test('her giriş assets/mech altında bir WebP gösterir', () {
      expect(kMechAsset.length, greaterThanOrEqualTo(100));
      for (final entry in kMechAsset.entries) {
        expect(entry.key, matches(RegExp(r'^[a-z0-9-]+$')));
        expect(entry.value, equals('assets/mech/${entry.key}.webp'));
        expect(File(entry.value).existsSync(), isTrue, reason: '${entry.value} yok');
      }
    });

    test('assets/mech içindeki her dosya katalogda (ölü varlık yok)', () {
      final used = kMechAsset.values.toSet();
      final onDisk = Directory('assets/mech')
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.webp'))
          .toSet();
      expect(onDisk.difference(used), isEmpty);
    });

    test('boyut bütçesi: varlık başına ve toplam', () {
      var total = 0;
      for (final path in kMechAsset.values) {
        final size = File(path).lengthSync();
        expect(size, lessThanOrEqualTo(120 * 1024), reason: '$path çok büyük');
        total += size;
      }
      expect(total, lessThanOrEqualTo(2600 * 1024), reason: 'toplam mekanik varlık bütçesi aşıldı');
    });

    test('varlıklar şeffaflık taşıyor (WebP alfa)', () {
      // WebP başlığı: RIFF....WEBP + VP8X (alfa bayrağı) veya VP8L (alfa taşıyabilir).
      var withAlpha = 0;
      for (final path in kMechAsset.values) {
        final head = File(path).openSync().readSync(20);
        final tag = String.fromCharCodes(head.sublist(12, 16));
        if (tag == 'VP8X' || tag == 'VP8L') withAlpha++;
      }
      expect(withAlpha, kMechAsset.length, reason: 'bazı varlıklar alfa kanalı taşımıyor');
    });
  });

  group('içerik eşlemesi', () {
    test('her araç bileşeni eşlemesi gerçek bir varlığa çözülür', () {
      expect(kVehiclePartAsset, isNotEmpty);
      for (final entry in kVehiclePartAsset.entries) {
        expect(mechAsset(entry.value), isNotNull, reason: '${entry.key} → ${entry.value} yok');
        expect(vehiclePartAsset(entry.key), isNotNull);
      }
    });

    test('kabin kumandaları: varlık, benzersiz kimlik ve dolu metin', () {
      expect(kCabinControls.length, greaterThanOrEqualTo(30));
      final seen = <String>{};
      for (final c in kCabinControls) {
        expect(mechAsset(c.asset), isNotNull, reason: '${c.asset} yok');
        expect(seen.add(c.asset), isTrue, reason: '${c.asset} tekrar ediyor');
        expect(c.title.trim(), isNotEmpty);
        expect(c.desc.trim().length, greaterThan(20));
        expect(c.group.trim(), isNotEmpty);
      }
    });

    test('eşlenmemiş bileşen için görsel null döner (çizim ikona düşer)', () {
      expect(vehiclePartAsset('boyle-bir-parca-yok'), isNull);
    });
  });

  group('ekranlar', () {
    testWidgets('MechImage varlığı çizer, eksik id\'de ikona düşer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          // MechImage tasarım paletini okur → uygulama teması şart.
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: Column(children: [MechImage(id: 'battery-12v'), MechImage(id: 'yok-boyle')]),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.build_rounded), findsOneWidget);
    });

    testWidgets('Kabin Kumandaları galerisi açılır, arar ve boş durumu gösterir', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      // hub satırı 800×600 test görüş alanının altında kalıyor
      await tester.ensureVisible(find.text('Kabin Kumandaları'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kabin Kumandaları'));
      await tester.pumpAndSettle();

      // ilk grup görünür olan; liste tembel olduğu için alttaki gruplar henüz kurulmaz
      expect(find.textContaining('Kollar & Farlar'), findsOneWidget);
      expect(find.text('Silecek Kolu (fasılalı)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'sis');
      await tester.pumpAndSettle();
      expect(find.text('Sis Farı Düğmesi'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pumpAndSettle();
      expect(find.text('Sonuç yok'), findsOneWidget);
    });
  });
}
