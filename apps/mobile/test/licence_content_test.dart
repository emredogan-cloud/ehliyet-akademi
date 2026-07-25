import 'dart:io';

import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/content/content_queries.dart';
import 'package:ehliyet_akademi/domain/content/content_snapshot.dart';
import 'package:ehliyet_akademi/domain/content/lesson.dart';
import 'package:ehliyet_akademi/domain/content/licence_scope.dart';
import 'package:ehliyet_akademi/domain/onboarding/study_profile.dart';
import 'package:ehliyet_akademi/domain/practice/collections.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Evolution Faz E5 — A ve D sınıfı içeriği, kapsamlama, işaret ağırlıklandırması ve odak setleri.
void main() {
  Lesson lesson(String id, {List<String> licences = const [], Subject subject = Subject.trafik}) =>
      Lesson(
        id: id,
        slug: id,
        no: 1,
        subject: subject,
        title: id,
        summary: 'özet',
        minutes: 5,
        objectives: const ['hedef'],
        sections: const [LessonSection(heading: 'h', body: 'b')],
        licences: licences,
      );

  final lessons = [
    lesson('ortak-trafik'), // etiketsiz = her sınıf
    lesson('ortak-ilkyardim', subject: Subject.ilkyardim),
    lesson('moto-donanim', licences: ['a'], subject: Subject.motor),
    lesson('otobus-takograf', licences: ['d']),
  ];

  group('ders kapsamlama', () {
    test('etiketsiz ortak dersler her sınıfta görünür', () {
      for (final c in LicenceCategory.values) {
        final ids = lessons.forLicence(c).map((l) => l.id);
        expect(ids, containsAll(['ortak-trafik', 'ortak-ilkyardim']));
      }
    });

    test('sınıfa özgü ders yalnız kendi sınıfında görünür', () {
      expect(lessons.forLicence(LicenceCategory.a).map((l) => l.id), [
        'ortak-trafik',
        'ortak-ilkyardim',
        'moto-donanim',
      ]);
      expect(lessons.forLicence(LicenceCategory.d).map((l) => l.id), [
        'ortak-trafik',
        'ortak-ilkyardim',
        'otobus-takograf',
      ]);
      // B sınıfında A/D dersleri YOKTUR ama ortak teori tamdır.
      expect(lessons.forLicence(LicenceCategory.b).map((l) => l.id), [
        'ortak-trafik',
        'ortak-ilkyardim',
      ]);
    });

    test('specificFor yalnız sınıfa özgü dersleri, shared yalnız ortakları verir', () {
      expect(lessons.specificFor(LicenceCategory.a).map((l) => l.id), ['moto-donanim']);
      expect(lessons.specificFor(LicenceCategory.d).map((l) => l.id), ['otobus-takograf']);
      expect(lessons.specificFor(LicenceCategory.b), isEmpty);
      expect(lessons.shared.map((l) => l.id), ['ortak-trafik', 'ortak-ilkyardim']);
    });

    test('hiçbir sınıf derssiz kalamaz (ortak teori her zaman var)', () {
      for (final c in LicenceCategory.values) {
        expect(lessons.forLicence(c), isNotEmpty);
      }
    });

    test('anlık görüntü sorguları sınıfa göre doğru sayar ve gruplar', () {
      final snap = sampleSnapshot().copyWith(lessons: lessons);
      expect(snap.lessonCountFor(LicenceCategory.a), 3);
      expect(snap.lessonCountFor(LicenceCategory.b), 2);
      expect(snap.licenceLessons(LicenceCategory.d).map((l) => l.id), ['otobus-takograf']);
      final grouped = snap.lessonsBySubject(licence: LicenceCategory.a);
      expect(grouped[Subject.motor]!.map((l) => l.id), ['moto-donanim']);
      expect(grouped.containsKey(Subject.pratik), isFalse);
    });
  });

  group('işaret ağırlıklandırma (filtre DEĞİL)', () {
    test('A ve D için öne çıkan işaret listesi var, B için yoktur', () {
      expect(signFocusFor(LicenceCategory.a), isNotEmpty);
      expect(signFocusFor(LicenceCategory.d), isNotEmpty);
      expect(signFocusFor(LicenceCategory.b), isEmpty);
    });

    test('her öne çıkan işaret benzersizdir ve gerekçesi doludur', () {
      for (final c in [LicenceCategory.a, LicenceCategory.d]) {
        final focus = signFocusFor(c);
        final ids = focus.map((f) => f.signId).toList();
        expect(ids.toSet().length, ids.length, reason: '$c içinde tekrar eden işaret var');
        for (final f in focus) {
          expect(f.why.length, greaterThan(30), reason: '${f.signId} gerekçesi çok kısa');
          expect(f.why.trim().endsWith('.'), isTrue, reason: '${f.signId} gerekçesi cümle değil');
        }
      }
    });

    test('her öne çıkan işaret gerçek işaret kataloğunda vardır (ölü referans yok)', () {
      // Kaynak doğruluk: içerik anlık görüntüsünü besleyen web kataloğu.
      final file = File('../web/content/signs.ts');
      expect(file.existsSync(), isTrue, reason: 'işaret kataloğu bulunamadı: ${file.path}');
      final catalog = RegExp(r"id: '([a-z0-9-]+)'")
          .allMatches(file.readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();
      for (final c in [LicenceCategory.a, LicenceCategory.d]) {
        for (final f in signFocusFor(c)) {
          expect(catalog.contains(f.signId), isTrue, reason: 'katalogda yok: ${f.signId}');
        }
      }
    });

    test('focusSignsFor yalnız anlık görüntüde bulunan işaretleri döner', () {
      // Örnek anlık görüntüde yalnız 'kaygan-yol' A odak listesindedir.
      final resolved = sampleSnapshot().focusSignsFor(LicenceCategory.a);
      expect(resolved.map((e) => e.sign.id), ['kaygan-yol']);
      expect(resolved.single.why, isNotEmpty);
      expect(sampleSnapshot().focusSignsFor(LicenceCategory.b), isEmpty);
    });
  });

  group('sınıfa özgü odak seti (gerçek banka soruları)', () {
    Question q(String id, String stem) => Question(
      id: id,
      subject: Subject.trafik,
      topic: 'genel',
      difficulty: Difficulty.orta,
      stem: stem,
      options: const ['a', 'b'],
      answerIndex: 0,
      explanation: 'açıklama',
    );

    final bank = [
      q('t-1', 'Motosiklet sürücüsü kask takmak zorunda mıdır?'),
      q('t-2', 'Otobüs durağına kaç metre mesafede duraklamak yasaktır?'),
      q('t-3', 'Kırmızı ışıkta ne yapılır?'),
      q('t-4', 'Kasko sigortası ile trafik sigortası arasındaki fark nedir?'),
    ];

    test('A seti motosiklet sorularını alır; "kasko" yanlış eşleşmez', () {
      final ids = licenceFocusQuestions(bank, LicenceCategory.a).map((x) => x.id);
      expect(ids, ['t-1']);
    });

    test('D seti otobüs/ticari taşımacılık sorularını alır', () {
      final ids = licenceFocusQuestions(bank, LicenceCategory.d).map((x) => x.id);
      expect(ids, ['t-2']);
    });

    test('B için ayrı bir alt küme üretilmez (banka zaten B odaklı)', () {
      expect(licenceFocusQuestions(bank, LicenceCategory.b), isEmpty);
    });

    test('odak koleksiyonu listenin başında gelir ve gerçek sayıyı taşır', () {
      final a = examCollections(bank, daySeed: 7, weekSeed: 9, licence: LicenceCategory.a);
      expect(a.first.id, 'motosiklet-odakli');
      expect(a.first.count, 1);
      final d = examCollections(bank, daySeed: 7, weekSeed: 9, licence: LicenceCategory.d);
      expect(d.first.id, 'otobus-odakli');
      // Sınıf verilmezse davranış eskisiyle aynıdır (geriye dönük uyumlu).
      final plain = examCollections(bank, daySeed: 7, weekSeed: 9);
      expect(plain.any((c) => c.id == 'motosiklet-odakli'), isFalse);
      expect(collectionById(bank, 'motosiklet-odakli', daySeed: 7, weekSeed: 9), isNull);
      expect(
        collectionById(
          bank,
          'motosiklet-odakli',
          daySeed: 7,
          weekSeed: 9,
          licence: LicenceCategory.a,
        ),
        isNotNull,
      );
    });
  });

  group('ekranlar', () {
    ContentSnapshot snapshotWithLicenceLessons() => sampleSnapshot().copyWith(
      lessons: [
        ...sampleSnapshot().lessons,
        lesson('moto-koruyucu-donanim', licences: ['a'], subject: Subject.motor)
            .copyWith(title: 'Motosiklette Koruyucu Donanım'),
      ],
    );

    testWidgets('Dersler ekranı sınıfa özel bölümü gösterir ve ortak dersleri korur', (
      tester,
    ) async {
      await pumpApp(
        tester,
        content: snapshotWithLicenceLessons(),
        studyProfile: StudyProfile.empty.copyWith(category: LicenceCategory.a),
      );
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dersler'));
      await tester.pumpAndSettle();

      expect(find.text('Dersler · A'), findsOneWidget);
      expect(find.text('Sınıfına özel · A Motosiklet'), findsOneWidget);
      expect(find.text('Motosiklette Koruyucu Donanım'), findsOneWidget);
      // Ortak teori dersleri kaybolmaz.
      expect(find.text('Trafiğe Giriş'), findsOneWidget);
    });

    testWidgets('B sınıfında "Sınıfına özel" bölümü hiç görünmez', (tester) async {
      await pumpApp(tester, content: snapshotWithLicenceLessons());
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dersler'));
      await tester.pumpAndSettle();

      expect(find.text('Dersler · B'), findsOneWidget);
      expect(find.textContaining('Sınıfına özel'), findsNothing);
      expect(find.text('Motosiklette Koruyucu Donanım'), findsNothing);
      expect(find.text('Trafiğe Giriş'), findsOneWidget);
    });

    testWidgets('İşaret galerisi A için öne çıkanlar bölümünü ekler, galeriyi kısmaz', (
      tester,
    ) async {
      await pumpApp(
        tester,
        studyProfile: StudyProfile.empty.copyWith(category: LicenceCategory.a),
      );
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trafik İşaretleri'));
      await tester.pumpAndSettle();

      expect(find.text('A sınıfı için öne çıkanlar  ·  1'), findsOneWidget);
      // Kaygan Yol hem öne çıkanlarda hem kendi kategorisinde görünür (kısılma yok).
      expect(find.text('Kaygan Yol'), findsNWidgets(2));
      // Öne çıkanlar bölümü galeriyi kısaltmaz: diğer kategoriler aşağıda tam hâliyle durur
      // (yeni bölüm alttakileri tembel listede kat dışına ittiği için önce kaydırılır).
      // Arama alanı da bir Scrollable içerir → galeri listesini açıkça hedefle.
      await tester.scrollUntilVisible(
        find.text('Dur'),
        200,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
      );
      expect(find.text('Dur'), findsOneWidget);
      expect(find.text('Azami Hız 30'), findsOneWidget);
    });

    testWidgets('İşaret detayı sınıfa özel gerekçeyi gösterir', (tester) async {
      await pumpApp(
        tester,
        studyProfile: StudyProfile.empty.copyWith(category: LicenceCategory.a),
      );
      await tester.tap(find.text('Öğren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trafik İşaretleri'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaygan Yol').first);
      await tester.pumpAndSettle();

      expect(find.text('🎯 A sınıfı için neden kritik?'), findsOneWidget);
    });

    testWidgets('Pratik hub teori sınavının ortak olduğunu açıkça yazar', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Pratik'));
      await tester.pumpAndSettle();

      expect(find.text('Teori sınavı tüm sınıflarda ortaktır'), findsOneWidget);
    });
  });
}
