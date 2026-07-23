import 'dart:math' as math;

import '../content/content_enums.dart';
import 'question.dart';
import 'srs.dart' show examDistribution, examTotalQuestions;

/// e-Sınav oluşturucu — web `lib/exam.ts` + `qip/visual.ts` (mulberry32) + `content-schema` (FNV-1a)
/// birebir Dart limanı. Pratik/sınav TAMAMEN çevrimdışı, bankadan kurulur.

typedef Rng = double Function();

const List<Subject> theorySubjects = [
  Subject.trafik,
  Subject.ilkyardim,
  Subject.motor,
  Subject.adab,
];
const int examDurationMinutes = 45;
const int examPassCorrect = 35;

int _u32(int x) => x & 0xFFFFFFFF;

/// JS `Math.imul` — 32-bit imzalı çarpımın alt 32 biti (unsigned tutulur).
int _imul(int a, int b) {
  a = _u32(a);
  b = _u32(b);
  final ah = (a >>> 16) & 0xFFFF;
  final al = a & 0xFFFF;
  final bh = (b >>> 16) & 0xFFFF;
  final bl = b & 0xFFFF;
  return _u32(al * bl + _u32(_u32(ah * bl + al * bh) << 16));
}

/// Tohumlu deterministik PRNG (mulberry32) — web `seededRng` ile aynı.
Rng seededRng(int seed) {
  var a = _u32(seed);
  return () {
    a = _u32(a + 0x6D2B79F5);
    var t = a;
    t = _imul(t ^ (t >>> 15), _u32(1 | t));
    t = _u32(_u32(t + _imul(t ^ (t >>> 7), _u32(61 | t))) ^ t);
    return _u32(t ^ (t >>> 14)) / 4294967296.0;
  };
}

/// Rastgele (deterministik olmayan) üretim.
Rng randomRng() {
  final r = math.Random();
  return r.nextDouble;
}

/// FNV-1a 32-bit → 8 haneli hex (web `hash32`).
String hash32(String s) {
  var h = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    h = _u32(h ^ s.codeUnitAt(i));
    h = _imul(h, 0x01000193);
  }
  return _u32(h).toRadixString(16).padLeft(8, '0');
}

/// Tarih dizesinden kararlı tohum (web `seedFromDate`).
int seedFromDate(String dateStr) => _u32(int.parse(hash32(dateStr), radix: 16));

/// Fisher–Yates (enjekte rng, saf).
List<T> shuffle<T>(List<T> arr, Rng rng) {
  final a = List<T>.of(arr);
  for (var i = a.length - 1; i > 0; i--) {
    final j = (rng() * (i + 1)).floor();
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

class BuiltExam {
  const BuiltExam({
    required this.questions,
    required this.fullBlueprint,
    required this.durationSeconds,
    required this.passCorrect,
  });
  final List<Question> questions;

  /// Banka her dersi tam karşılıyorsa true (aksi hâlde oransal küçültülmüş).
  final bool fullBlueprint;
  final int durationSeconds;
  final int passCorrect;
}

/// Dağılıma birebir uyan 50 soruluk sınav kur (23/12/9/6). Banka bir derste yetersizse
/// eldeki kadar alınır + `fullBlueprint=false` (dürüst etiketleme).
BuiltExam buildExam(List<Question> pool, {Rng? rng}) {
  final r = rng ?? randomRng();
  final out = <Question>[];
  var full = true;
  for (final subject in theorySubjects) {
    final want = examDistribution[subject.name]!;
    final avail = shuffle(pool.where((q) => q.subject == subject).toList(), r);
    if (avail.length < want) full = false;
    out.addAll(avail.take(want));
  }
  final scale = out.length / examTotalQuestions;
  return BuiltExam(
    questions: shuffle(out, r),
    fullBlueprint: full,
    durationSeconds: examDurationMinutes * 60,
    passCorrect: full ? examPassCorrect : (examPassCorrect * scale).ceil(),
  );
}

class SubjectScore {
  const SubjectScore({required this.subject, required this.correct, required this.total});
  final Subject subject;
  final int correct;
  final int total;
}

class ExamResult {
  const ExamResult({
    required this.correct,
    required this.total,
    required this.passed,
    required this.perSubject,
  });
  final int correct;
  final int total;
  final bool passed;
  final List<SubjectScore> perSubject;

  int get wrong => total - correct;
}

/// Sınavı puanla — strict `answers[i] == answerIndex` (boş = yanlış). Baraj `correct >= passCorrect`.
ExamResult scoreExam(List<Question> questions, List<int?> answers, int passCorrect) {
  var correct = 0;
  final bySubject = <Subject, ({int correct, int total})>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    final s = bySubject[q.subject] ?? (correct: 0, total: 0);
    var c = s.correct;
    if (answers[i] == q.answerIndex) {
      correct += 1;
      c += 1;
    }
    bySubject[q.subject] = (correct: c, total: s.total + 1);
  }
  return ExamResult(
    correct: correct,
    total: questions.length,
    passed: correct >= passCorrect,
    perSubject: bySubject.entries
        .map((e) => SubjectScore(subject: e.key, correct: e.value.correct, total: e.value.total))
        .toList(),
  );
}
