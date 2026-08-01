import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/exam_library.dart';
import 'package:ehliyet_akademi/domain/practice/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ürün Evrimi v1.1 · Faz 2 — sınav kütüphanesi kapısı.
///
/// Kütüphanenin üç iddiası ölçülebilir olmalı:
/// 1. Takvim YUVARLANIR (bayat tarih yok).
/// 2. Aynı (kategori, tarih) HEP aynı sınavı verir.
/// 3. İlk üç sınav ücretsiz, gerisi premium — ve sınır kategori başına DEĞİL.

Question _q(String id, Subject s, {String? asset}) => Question(
  id: id,
  subject: s,
  topic: 'Konu-${id.hashCode % 7}',
  difficulty: Difficulty.values[id.hashCode.abs() % 3],
  stem: 'Soru gövdesi $id',
  options: const ['Birinci seçenek', 'İkinci seçenek', 'Üçüncü seçenek', 'Dördüncü seçenek'],
  answerIndex: id.hashCode.abs() % 4,
  explanation: 'Açıklama $id',
  kind: asset == null ? QuestionKind.text : QuestionKind.sign,
  media: asset == null
      ? null
      : QuestionMedia(images: [QuestionImage(assetId: asset, alt: 'alt $asset')]),
);

/// Her dersten bolca soru + görselli bir bölüm.
List<Question> _bank() => [
  for (final s in Subject.values)
    for (var i = 0; i < 60; i++) _q('${s.name}-$i', s),
  for (var i = 0; i < 40; i++) _q('gorsel-$i', Subject.trafik, asset: 'sign-$i'),
];

final _today = DateTime(2026, 8, 1);

void main() {
  group('takvim', () {
    test('bugünden geriye günlük — en yeni başta', () {
      final list = libraryExams(ExamCategory.genel, _today);
      expect(list, hasLength(kLibraryExamsPerCategory));
      expect(list.first.date, '2026-08-01');
      expect(list.first.label, '1 Ağustos 2026 Sınav Soruları');
      expect(list[1].date, '2026-07-31');
      expect(list.last.date, '2026-07-03');
    });

    /// Eski `historical.dart` 2015–2018 arasında SABİT 18 tarih tutuyordu ve bayatlıyordu.
    test('tarihler BAYATLAMAZ — takvim bugüne bağlı', () {
      final a = libraryExams(ExamCategory.genel, DateTime(2026, 8, 1)).first.date;
      final b = libraryExams(ExamCategory.genel, DateTime(2027, 3, 15)).first.date;
      expect(a, '2026-08-01');
      expect(b, '2027-03-15');
    });

    test('gün içi saat listeyi değiştirmez', () {
      final sabah = libraryExams(ExamCategory.genel, DateTime(2026, 8, 1, 6));
      final aksam = libraryExams(ExamCategory.genel, DateTime(2026, 8, 1, 23, 59));
      expect(sabah.map((e) => e.id), aksam.map((e) => e.id));
    });
  });

  group('kategoriler', () {
    test('ders sınavının uzunluğu MEB payına eşit', () {
      expect(ExamCategory.genel.questionCount, 50);
      expect(ExamCategory.trafik.questionCount, 23);
      expect(ExamCategory.ilkyardim.questionCount, 12);
      expect(ExamCategory.motor.questionCount, 9);
      expect(ExamCategory.adab.questionCount, 6);
    });

    test('altı kategori — referanstaki katalogla aynı kırılım', () {
      expect(ExamCategory.values, hasLength(6));
      expect(
        ExamCategory.values.map((c) => c.label),
        containsAll(['Genel Sınav', 'Trafik ve Çevre Bilgisi', 'Görsel Sorular']),
      );
    });

    /// "Animasyonlu" demiyoruz: elimizde animasyon yok. Olmayan bir şeyi vaat etmek,
    /// ürün turundaki "gerçek sınavları olduğu gibi çöz" hatasının aynısı olurdu.
    test('görsel kategori ANİMASYON vaat etmez', () {
      expect(ExamCategory.gorsel.label, isNot(contains('Animasyon')));
      expect(ExamCategory.gorsel.blurb, isNot(contains('animasyon')));
    });
  });

  group('üretim', () {
    test('genel sınav MEB dağılımını kurar', () {
      final exam = buildLibraryExam(_bank(), libraryExams(ExamCategory.genel, _today).first);
      expect(exam.questions, hasLength(50));
      final bySubject = <Subject, int>{};
      for (final q in exam.questions) {
        bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
      }
      expect(bySubject[Subject.trafik], 23);
      expect(bySubject[Subject.ilkyardim], 12);
      expect(bySubject[Subject.motor], 9);
      expect(bySubject[Subject.adab], 6);
    });

    test('ders sınavı YALNIZ o dersten kurulur', () {
      for (final c in [
        ExamCategory.trafik,
        ExamCategory.ilkyardim,
        ExamCategory.motor,
        ExamCategory.adab,
      ]) {
        final exam = buildLibraryExam(_bank(), libraryExams(c, _today).first);
        expect(exam.questions, hasLength(c.questionCount), reason: c.label);
        expect(
          exam.questions.every((q) => q.subject == c.subject),
          isTrue,
          reason: '${c.label} sınavında başka dersten soru var',
        );
      }
    });

    test('görsel sınavı görselli sorulardan kurulur', () {
      final exam = buildLibraryExam(_bank(), libraryExams(ExamCategory.gorsel, _today).first);
      expect(exam.questions, isNotEmpty);
      expect(
        exam.questions.every((q) => q.kind.needsMedia),
        isTrue,
        reason: 'görsel sınavında metin sorusu bulunmamalı',
      );
    });

    /// Kullanıcı yarım bıraktığı sınava dönünce aynı soruları bulmalı.
    test('aynı tarih + aynı kategori HEP aynı sınav', () {
      final e = libraryExams(ExamCategory.genel, _today).first;
      final a = buildLibraryExam(_bank(), e);
      final b = buildLibraryExam(_bank(), e);
      expect(a.questions.map((q) => q.id), b.questions.map((q) => q.id));
    });

    test('farklı tarih FARKLI sınav', () {
      final list = libraryExams(ExamCategory.genel, _today);
      final a = buildLibraryExam(_bank(), list[0]);
      final b = buildLibraryExam(_bank(), list[1]);
      expect(a.questions.map((q) => q.id), isNot(b.questions.map((q) => q.id)));
    });

    /// Aynı GÜNÜN farklı kategorileri aynı tohumu paylaşmamalı.
    test('aynı gün, farklı kategori → farklı tohum', () {
      final genel = libraryExams(ExamCategory.genel, _today).first;
      final trafik = libraryExams(ExamCategory.trafik, _today).first;
      expect(examConfigFor(genel).seed, isNot(examConfigFor(trafik).seed));
    });
  });

  group('ücretsiz / premium', () {
    test('ilk üç GENEL sınav ücretsiz', () {
      final list = libraryExams(ExamCategory.genel, _today);
      expect(isExamFree(list[0]), isTrue);
      expect(isExamFree(list[1]), isTrue);
      expect(isExamFree(list[2]), isTrue);
      expect(isExamFree(list[3]), isFalse);
    });

    /// Sınır kategori başına olsaydı altı kategoride 18 ücretsiz sınav olurdu.
    test('sınır KATEGORİ BAŞINA DEĞİL — ders sınavlarının hiçbiri ücretsiz değil', () {
      for (final c in ExamCategory.values.where((c) => c != ExamCategory.genel)) {
        expect(
          libraryExams(c, _today).where(isExamFree),
          isEmpty,
          reason: '${c.label} içinde ücretsiz sınav çıktı — sınır kategori başına uygulanmış',
        );
      }
      final freeTotal = ExamCategory.values
          .expand((c) => libraryExams(c, _today))
          .where(isExamFree)
          .length;
      expect(freeTotal, kFreeExamCount);
    });

    test('premium her sınavı açar', () {
      for (final c in ExamCategory.values) {
        for (final e in libraryExams(c, _today)) {
          expect(canOpenExam(e, premium: true), isTrue);
        }
      }
    });

    test('premium değilken yalnız ücretsiz olanlar açılır', () {
      final list = libraryExams(ExamCategory.genel, _today);
      expect(canOpenExam(list[0], premium: false), isTrue);
      expect(canOpenExam(list[5], premium: false), isFalse);
    });
  });

  group('kimlik', () {
    test('kimlikten sınav çözülür', () {
      final e = libraryExams(ExamCategory.motor, _today)[4];
      final back = libraryExamById(e.id, _today);
      expect(back, isNotNull);
      expect(back!.category, ExamCategory.motor);
      expect(back.date, e.date);
      expect(back.index, 4);
    });

    test('tanınmayan kimlik null', () {
      expect(libraryExamById('yok-2020-01-01', _today), isNull);
    });
  });

  test('telif etiketi açıkça özgün üretim diyor', () {
    expect(libraryDisclaimer, contains('ÖZGÜN'));
    expect(libraryDisclaimer, contains('Telifli sınav kâğıdı sunulmaz'));
  });
}
