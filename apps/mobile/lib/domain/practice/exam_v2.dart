import '../content/content_enums.dart';
import 'exam.dart';
import 'question.dart';
import 'srs.dart' show examDistribution, examTotalQuestions;

/// QIP v3 · Faz 5 — SINAV ÜRETECİ V2.
///
/// ## Neden yeni bir üreteç
///
/// Mevcut [buildExam] tek işi yapıyor: her dersten payı kadar rastgele soru al, karıştır. Web'deki
/// `buildDynamicExam` ise zorluk dengeler, aynı aileden iki soru almaz, aynı görseli tekrarlamaz,
/// şıkları karıştırır ve yapılandırılabilir. Ürün mobil olduğu için bu fark **doğrudan
/// kullanıcının gördüğü sınavın kalitesi** demekti.
///
/// [buildExam] **kaldırılmadı**: tarihsel sınav ve mevcut testler onu çağırıyor ve davranışı
/// birebir korunmalı. V2 onun yanında durur.
///
/// ## Kipler
///
/// Kip, "hangi ayarlar" sorusunun kısayoludur — çağıran taraf on parametre doldurmak zorunda
/// kalmasın diye. Her kip [ExamConfig.forMode] içinde tek yerde tanımlı.

enum ExamMode {
  /// Gerçek e-Sınav: 50 soru, 45 dakika, MEB dağılımı.
  exam,

  /// Serbest alıştırma — süre baskısı yok, zorluk dengeli.
  practice,

  /// Hızlı tur: 10 soru.
  quick,

  /// Tamamen rastgele — dağılım gözetmez (keşif/eğlence).
  random,

  /// Tarihsel oturum — sınav ayarları + tarihten tohum.
  historical,

  /// Uyarlanabilir — zayıf konulara ağırlık verir.
  adaptive;

  String get label => switch (this) {
    ExamMode.exam => 'Deneme Sınavı',
    ExamMode.practice => 'Alıştırma',
    ExamMode.quick => 'Hızlı Tur',
    ExamMode.random => 'Rastgele',
    ExamMode.historical => 'Geçmiş Sınav',
    ExamMode.adaptive => 'Sana Özel',
  };
}

class ExamConfig {
  const ExamConfig({
    this.mode = ExamMode.exam,
    this.count,
    this.subjects,
    this.difficultyBalance = true,
    this.avoidSameTopicRun = true,
    this.noRepeatImage = true,
    this.randomizeChoices = true,
    this.visualRatio,
    this.weakTopics = const [],
    this.seed,
    this.durationSeconds,
    this.passCorrect,
  });

  final ExamMode mode;

  /// Soru adedi. Verilmezse kipin varsayılanı.
  final int? count;

  /// Ders → adet. Verilmezse MEB dağılımı [count]'a ölçeklenir.
  final Map<Subject, int>? subjects;

  /// Kolay/orta/zor arasında dengeli seçim.
  final bool difficultyBalance;

  /// Aynı konudan iki soruyu ARKA ARKAYA koyma.
  ///
  /// Web'deki "aile" kavramının mobil karşılığı: mobil soruda `family` alanı yok, ama `topic`
  /// var ve pratikte aynı işi görüyor. Amaç sınavın "aynı şeyi üç kez sormuş" hissi vermemesi.
  final bool avoidSameTopicRun;

  /// Aynı görseli iki soruda kullanma.
  final bool noRepeatImage;

  /// Şık sırasını karıştır (doğru cevap indeksi yeniden eşlenir).
  final bool randomizeChoices;

  /// Görsel soru oranı hedefi (0..1). Verilmezse karışıma müdahale edilmez.
  final double? visualRatio;

  /// Öncelik verilecek zayıf konular (uyarlanabilir kip).
  final List<String> weakTopics;

  final int? seed;
  final int? durationSeconds;
  final int? passCorrect;

  /// Kipin varsayılan ayarları — tek kaynak.
  static ExamConfig forMode(ExamMode mode, {int? seed, List<String> weakTopics = const []}) =>
      switch (mode) {
        ExamMode.exam => ExamConfig(mode: mode, count: examTotalQuestions, seed: seed),
        ExamMode.historical => ExamConfig(mode: mode, count: examTotalQuestions, seed: seed),
        ExamMode.practice => ExamConfig(mode: mode, count: 20, seed: seed),
        ExamMode.quick => ExamConfig(mode: mode, count: 10, seed: seed),
        // Rastgele kipte dağılım BİLİNÇLİ olarak gözetilmez; `subjects` boş bırakılır.
        ExamMode.random => ExamConfig(
          mode: mode,
          count: 20,
          subjects: const {},
          difficultyBalance: false,
          seed: seed,
        ),
        ExamMode.adaptive => ExamConfig(
          mode: mode,
          count: 20,
          weakTopics: weakTopics,
          // Zayıf konu çalışılırken "aynı konu arka arkaya gelmesin" kuralı amaca ters düşer.
          avoidSameTopicRun: false,
          seed: seed,
        ),
      };

  int get effectiveCount => count ?? examTotalQuestions;
}

/// Üretimin ÖLÇÜLEN sonucu — üreteç ne yaptığını raporlar.
///
/// Bu alanlar arayüzde gösterilmiyor; **testler ve teşhis** için. "Zorluk dengeledim" iddiası
/// ancak sayılabiliyorsa doğrulanabilir.
class ExamPlan {
  const ExamPlan({
    required this.exam,
    required this.bySubject,
    required this.byDifficulty,
    required this.visualCount,
    required this.repeatedImages,
    required this.weakTopicCount,
  });

  final BuiltExam exam;
  final Map<Subject, int> bySubject;
  final Map<Difficulty, int> byDifficulty;
  final int visualCount;
  final int repeatedImages;
  final int weakTopicCount;
}

/// Ders payları — açık verilmişse o, yoksa MEB dağılımı [count]'a ölçeklenir.
Map<Subject, int> _targets(ExamConfig config) {
  final explicit = config.subjects;
  if (explicit != null) return explicit;
  final count = config.effectiveCount;
  final out = <Subject, int>{};
  for (final s in theorySubjects) {
    final share = examDistribution[s.name]!;
    out[s] = (share / examTotalQuestions * count).round().clamp(1, count);
  }
  return out;
}

/// Zorluk dengeli seçim: havuzu üç kovaya ayır, sırayla al.
///
/// Neden sırayla: doğrudan karıştırıp almak, havuzda hangi zorluk çoksa sınavı ona kaydırır.
/// Bankada `orta` baskın olduğu için dengeleme olmadan sınavlar ortaya yığılıyordu.
List<Question> _balanced(List<Question> pool, int want, Rng rng) {
  final buckets = <Difficulty, List<Question>>{
    for (final d in Difficulty.values) d: [],
  };
  for (final q in pool) {
    buckets[q.difficulty]!.add(q);
  }
  for (final b in buckets.values) {
    final s = shuffle(b, rng);
    b
      ..clear()
      ..addAll(s);
  }
  final out = <Question>[];
  final order = [Difficulty.kolay, Difficulty.orta, Difficulty.zor];
  var i = 0;
  while (out.length < want) {
    var progressed = false;
    for (final d in order) {
      if (out.length >= want) break;
      final b = buckets[d]!;
      if (i < b.length) {
        out.add(b[i]);
        progressed = true;
      }
    }
    // Bütün kovalar tükendiyse döngü sonsuza gitmesin.
    if (!progressed) break;
    i++;
  }
  return out;
}

/// Zayıf konuları öne al — uyarlanabilir kip.
List<Question> _weakFirst(List<Question> pool, List<String> weakTopics, Rng rng) {
  if (weakTopics.isEmpty) return shuffle(pool, rng);
  final weak = <Question>[];
  final rest = <Question>[];
  for (final q in pool) {
    (weakTopics.contains(q.topic) ? weak : rest).add(q);
  }
  return [...shuffle(weak, rng), ...shuffle(rest, rng)];
}

/// Şıkları karıştır, doğru cevabı yeniden eşle.
///
/// `answerIndex`in yeniden eşlenmemesi, üretecin sessizce yanlış cevap öğretmesi demektir —
/// bu yüzden ayrı bir fonksiyon ve ayrı bir test.
Question _shuffleChoices(Question q, Rng rng) {
  final order = shuffle(List<int>.generate(q.options.length, (i) => i), rng);
  return q.copyWith(
    options: [for (final i in order) q.options[i]],
    answerIndex: order.indexOf(q.answerIndex),
  );
}

String? _imageKey(Question q) {
  final m = q.media;
  if (m == null || m.images.isEmpty) return null;
  return m.images.first.assetId;
}

/// Aynı konudan iki soru ARKA ARKAYA gelmesin diye sırayı yumuşat.
///
/// Tam bir dağıtım (her konuyu eşit aralıklara serpmek) gereksiz karmaşık; burada yalnız
/// ardışık tekrar kırılıyor — kullanıcının fark ettiği şey bu.
List<Question> _breakTopicRuns(List<Question> qs) {
  final out = <Question>[...qs];
  for (var i = 1; i < out.length; i++) {
    if (out[i].topic != out[i - 1].topic) continue;
    // Sonraki farklı konulu soruyla yer değiştir.
    for (var j = i + 1; j < out.length; j++) {
      if (out[j].topic != out[i - 1].topic) {
        final tmp = out[i];
        out[i] = out[j];
        out[j] = tmp;
        break;
      }
    }
  }
  return out;
}

/// SINAV ÜRETECİ V2.
///
/// Havuz yetersizse **elde ne varsa** onunla kurar ve `fullBlueprint: false` ile dürüstçe
/// bildirir — eksik sınavı gizlemez.
ExamPlan buildExamV2(List<Question> pool, ExamConfig config, {Rng? rng}) {
  final r = rng ?? (config.seed != null ? seededRng(config.seed!) : randomRng());

  // Biçimi bozuk soru sınava GİRMEZ (Faz 11 kuralı — sunucudan gelen banka istemcinin
  // kontrolü dışında).
  final clean = pool.where(isWellFormedQuestion).toList();

  final targets = _targets(config);
  final usedImages = <String>{};
  final picked = <Question>[];
  var full = true;

  void take(List<Question> from, int want) {
    for (final q in from) {
      if (picked.length >= config.effectiveCount) return;
      if (want <= 0) return;
      final key = _imageKey(q);
      if (config.noRepeatImage && key != null && !usedImages.add(key)) continue;
      picked.add(q);
      want--;
    }
  }

  if (targets.isEmpty) {
    // Ders gözetmeyen yol (rastgele kip ve `subjects: {}` verilen çağrılar).
    //
    // Zayıf konu önceliği BURADA DA uygulanmalı: ilk yazımda yalnız ders döngüsünde vardı ve
    // uyarlanabilir kip `subjects: {}` ile çağrıldığında zayıf konular hiç öne alınmıyordu —
    // yani kipin tek işi sessizce çalışmıyordu. Test bunu yakaladı.
    final ordered = config.weakTopics.isNotEmpty
        ? _weakFirst(clean, config.weakTopics, r)
        : (config.difficultyBalance ? _balanced(clean, config.effectiveCount, r) : shuffle(clean, r));
    take(ordered, config.effectiveCount);
    if (picked.length < config.effectiveCount) full = false;
  } else {
    for (final entry in targets.entries) {
      final subjectPool = clean.where((q) => q.subject == entry.key).toList();
      final ordered = config.weakTopics.isNotEmpty
          ? _weakFirst(subjectPool, config.weakTopics, r)
          : (config.difficultyBalance ? _balanced(subjectPool, entry.value, r) : shuffle(subjectPool, r));
      final before = picked.length;
      take(ordered, entry.value);
      if (picked.length - before < entry.value) full = false;
    }
  }

  // Görsel oranı hedefi — havuzda yeterli görsel soru varsa karışımı ona yaklaştır.
  final ratio = config.visualRatio;
  if (ratio != null && picked.isNotEmpty) {
    final wantVisual = (picked.length * ratio).round();
    final have = picked.where((q) => q.media != null).length;
    if (have < wantVisual) {
      final spare = shuffle(
        clean.where((q) => q.media != null && !picked.contains(q)).toList(),
        r,
      );
      final textIdx = [
        for (var i = 0; i < picked.length; i++)
          if (picked[i].media == null) i,
      ];
      var swapped = 0;
      for (final q in spare) {
        if (swapped >= wantVisual - have || swapped >= textIdx.length) break;
        final key = _imageKey(q);
        if (key != null && !usedImages.add(key)) continue;
        picked[textIdx[swapped]] = q;
        swapped++;
      }
    }
  }

  var ordered = shuffle(picked, r);
  if (config.avoidSameTopicRun) ordered = _breakTopicRuns(ordered);
  if (config.randomizeChoices) {
    ordered = [for (final q in ordered) _shuffleChoices(q, r)];
  }

  final scale = config.effectiveCount == 0 ? 0.0 : ordered.length / config.effectiveCount;
  final exam = BuiltExam(
    questions: ordered,
    fullBlueprint: full,
    durationSeconds: config.durationSeconds ?? (config.mode == ExamMode.exam || config.mode == ExamMode.historical
        ? examDurationMinutes * 60
        : ordered.length * 54),
    passCorrect: config.passCorrect ??
        (full
            ? (config.effectiveCount * 0.7).ceil()
            : ((config.effectiveCount * 0.7).ceil() * scale).ceil()),
  );

  final bySubject = <Subject, int>{};
  final byDifficulty = <Difficulty, int>{};
  final seenImages = <String>{};
  var repeated = 0;
  for (final q in ordered) {
    bySubject[q.subject] = (bySubject[q.subject] ?? 0) + 1;
    byDifficulty[q.difficulty] = (byDifficulty[q.difficulty] ?? 0) + 1;
    final key = _imageKey(q);
    if (key != null && !seenImages.add(key)) repeated++;
  }

  return ExamPlan(
    exam: exam,
    bySubject: bySubject,
    byDifficulty: byDifficulty,
    visualCount: ordered.where((q) => q.media != null).length,
    repeatedImages: repeated,
    weakTopicCount: config.weakTopics.isEmpty
        ? 0
        : ordered.where((q) => config.weakTopics.contains(q.topic)).length,
  );
}

extension ExamConfigTweaks on ExamConfig {
  /// Görsel oranını değiştir — kip varsayılanını bozmadan tek alanı ayarlamak için.
  ExamConfig copyWithVisualRatio(double ratio) => ExamConfig(
    mode: mode,
    count: count,
    subjects: subjects,
    difficultyBalance: difficultyBalance,
    avoidSameTopicRun: avoidSameTopicRun,
    noRepeatImage: noRepeatImage,
    randomizeChoices: randomizeChoices,
    visualRatio: ratio,
    weakTopics: weakTopics,
    seed: seed,
    durationSeconds: durationSeconds,
    passCorrect: passCorrect,
  );
}
