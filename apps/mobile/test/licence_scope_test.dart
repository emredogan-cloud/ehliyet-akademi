import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/licence_scope.dart';
import 'package:ehliyet_akademi/domain/content/vehicle_part.dart';
import 'package:ehliyet_akademi/domain/onboarding/study_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E4 — çok-sınıflı temel (B · A · D).
void main() {
  VehiclePart part(String id, {List<String> licences = const []}) => VehiclePart(
    id: id,
    name: id,
    system: VehicleSystem.kabin,
    desc: '',
    tip: '',
    licences: licences,
  );

  final parts = [
    part('ortak-motor'), // sınıftan bağımsız
    part('otomatik-vites', licences: ['b']),
    part('kabin', licences: ['b', 'd']),
    part('moto-zincir', licences: ['a']),
    part('otobus-takograf', licences: ['d']),
  ];

  group('kapsamlama', () {
    test('etiketsiz içerik her sınıfta görünür', () {
      for (final c in LicenceCategory.values) {
        expect(matchesLicence(const [], c), isTrue);
      }
    });

    test('etiketli içerik yalnız kendi sınıfında görünür', () {
      expect(matchesLicence(const ['a'], LicenceCategory.a), isTrue);
      expect(matchesLicence(const ['a'], LicenceCategory.b), isFalse);
      expect(matchesLicence(const ['b', 'd'], LicenceCategory.d), isTrue);
      expect(matchesLicence(const ['b', 'd'], LicenceCategory.a), isFalse);
    });

    test('forLicence her sınıf için doğru kümeyi verir', () {
      expect(parts.forLicence(LicenceCategory.b).map((p) => p.id), [
        'ortak-motor',
        'otomatik-vites',
        'kabin',
      ]);
      expect(parts.forLicence(LicenceCategory.a).map((p) => p.id), ['ortak-motor', 'moto-zincir']);
      expect(parts.forLicence(LicenceCategory.d).map((p) => p.id), [
        'ortak-motor',
        'kabin',
        'otobus-takograf',
      ]);
    });

    test('prioritizedFor sınıfa özgü içeriği öne alır, ortak içeriği kaybetmez', () {
      final a = parts.prioritizedFor(LicenceCategory.a);
      expect(a.first.id, 'moto-zincir');
      expect(a.map((p) => p.id), containsAll(['moto-zincir', 'ortak-motor']));
      expect(a.length, 2);
    });

    test('hiçbir sınıf boş kalmaz (ortak içerik her zaman var)', () {
      for (final c in LicenceCategory.values) {
        expect(parts.forLicence(c), isNotEmpty);
      }
    });
  });

  group('Profil ehliyet sınıfı değiştirici', () {
    testWidgets('sınıf değiştirilebilir, kalıcıdır ve araç kütüphanesini yeniden kapsamlar', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Ehliyet sınıfı'), 300);
      await tester.pumpAndSettle();
      expect(find.text('B · Otomobil'), findsOneWidget);

      await tester.tap(find.text('Ehliyet sınıfı'));
      await tester.pumpAndSettle();
      expect(find.text('A · Motosiklet'), findsOneWidget);
      await tester.tap(find.text('A · Motosiklet'));
      await tester.pumpAndSettle();

      // satır güncellendi
      expect(find.text('A · Motosiklet'), findsOneWidget);
    });
  });
}
