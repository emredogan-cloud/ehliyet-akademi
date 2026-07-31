import 'package:flutter/foundation.dart';

import '../content/content_enums.dart';
import '../practice/exam.dart';
import '../practice/srs.dart';

// ─────────────────────────────────────────────────────────────────────────────────────────────
// Beta Faz 7 — AI Koç'un "öğrenme arkadaşı" katmanı.
//
// NEDEN LLM YOK
//
// Buradaki her çıktı CİHAZDAKİ GERÇEK CEVAP DEFTERİNDEN deterministik olarak hesaplanır. Üç sebeple:
//
// 1. ÇEVRİMDIŞI. Faz 5'in kuralı: sınava hazırlıkla ilgili her şey internetsiz çalışmalı. Zayıf
//    konu analizi, kullanıcının uçakta en çok ihtiyaç duyduğu şeydir.
// 2. DÜRÜSTLÜK. "Şu konuda zayıfsın" bir İDDİADIR ve arkasında kanıt olmalı. Sayıdan türetildiğinde
//    kanıt gösterilebilir ("32 soruda %41"); bir dil modelinden geldiğinde gösterilemez ve yanlış
//    olduğunda kullanıcı bunu ürünün geneline yayar.
// 3. ÖLÇÜLEBİLİRLİK. Saf fonksiyon test edilir; üretilen metin edilemez.
//
// AI sohbeti (`/api/ai/ask`) yerinde duruyor ve internet istiyor. Bu katman onun YERİNE değil
// YANINA gelir: sohbet "sorduğunu açıklar", bu katman "sormadığını söyler".
// ─────────────────────────────────────────────────────────────────────────────────────────────

/// Bir konunun zayıflık kanıtı.
@immutable
class WeakTopic {
  const WeakTopic({
    required this.topic,
    required this.subject,
    required this.answered,
    required this.correct,
  });

  final String topic;
  final Subject subject;
  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  /// Yüzde olarak doğruluk (arayüzde gösterilen).
  int get accuracyPercent => (accuracy * 100).round();

  /// Kaç soru yanlış — "kaç tane" somut, "%41" soyut.
  int get wrong => answered - correct;
}

/// Yeterli veri olmadan zayıflık İDDİA EDİLMEZ.
///
/// Üç soruda iki yanlış "%33 doğruluk" diye gösterilebilir ama bu bir istatistik değil, gürültüdür.
/// Kullanıcıyı olmayan bir zayıflığa yönlendirmek, gerçek zayıflığından uzaklaştırır. Sekiz,
/// gürültüyü eleyip erken sinyali kaçırmayan eşiktir.
const int kMinAnswersForWeakness = 8;

/// Bu oranın altı "zayıf" sayılır.
const double kWeakAccuracyThreshold = 0.7;

/// Zayıf konuları bul — en zayıf önce.
///
/// Sıralama YALNIZ doğruluğa göre DEĞİL: `wrong` (yanlış sayısı) ikincil ölçüt. Aynı doğruluktaki
/// iki konudan, daha çok soru görülmüş olan daha güvenilirdir ve sınavda daha çok yer kaplar.
List<WeakTopic> weakTopics(List<AnswerLog> answers, {int limit = 5}) {
  final byTopic = <String, ({Subject subject, int answered, int correct})>{};
  for (final a in answers) {
    final prev = byTopic[a.topic] ?? (subject: a.subject, answered: 0, correct: 0);
    byTopic[a.topic] = (
      subject: prev.subject,
      answered: prev.answered + 1,
      correct: prev.correct + (a.correct ? 1 : 0),
    );
  }

  final weak = <WeakTopic>[];
  for (final entry in byTopic.entries) {
    final v = entry.value;
    if (v.answered < kMinAnswersForWeakness) continue;
    final topic = WeakTopic(
      topic: entry.key,
      subject: v.subject,
      answered: v.answered,
      correct: v.correct,
    );
    if (topic.accuracy < kWeakAccuracyThreshold) weak.add(topic);
  }

  weak.sort((a, b) {
    final byAccuracy = a.accuracy.compareTo(b.accuracy);
    if (byAccuracy != 0) return byAccuracy;
    return b.wrong.compareTo(a.wrong);
  });
  return weak.take(limit).toList();
}

/// Son N günün doğruluk eğilimi.
@immutable
class ProgressTrend {
  const ProgressTrend({
    required this.recentAccuracy,
    required this.earlierAccuracy,
    required this.recentAnswered,
    required this.earlierAnswered,
  });

  final double recentAccuracy;
  final double earlierAccuracy;
  final int recentAnswered;
  final int earlierAnswered;

  /// Karşılaştırma yapmaya yetecek veri var mı.
  ///
  /// İki dönemin de anlamlı olması ŞART: son haftada 40 soru, ondan önce 2 soru çözülmüşse
  /// "gelişiyorsun" demek, 2 soruluk gürültüyü referans almak olur.
  bool get isMeaningful =>
      recentAnswered >= kMinAnswersForWeakness && earlierAnswered >= kMinAnswersForWeakness;

  double get delta => recentAccuracy - earlierAccuracy;

  /// Anlamlı bir değişim mi (±5 puan). Altındaki fark ölçüm gürültüsüdür.
  bool get isImproving => isMeaningful && delta >= 0.05;
  bool get isDeclining => isMeaningful && delta <= -0.05;
}

/// Son [windowDays] gün ile ondan önceki aynı uzunluktaki dönemi karşılaştır.
ProgressTrend progressTrend(List<AnswerLog> answers, {required int nowMs, int windowDays = 7}) {
  final windowMs = windowDays * dayMs;
  final recentFrom = nowMs - windowMs;
  final earlierFrom = nowMs - 2 * windowMs;

  var rA = 0, rC = 0, eA = 0, eC = 0;
  for (final a in answers) {
    if (a.at >= recentFrom) {
      rA++;
      if (a.correct) rC++;
    } else if (a.at >= earlierFrom) {
      eA++;
      if (a.correct) eC++;
    }
  }
  return ProgressTrend(
    recentAccuracy: rA == 0 ? 0 : rC / rA,
    earlierAccuracy: eA == 0 ? 0 : eC / eA,
    recentAnswered: rA,
    earlierAnswered: eA,
  );
}

/// Yedi günlük planın tek bir günü.
@immutable
class StudyDay {
  const StudyDay({
    required this.dayIndex,
    required this.focus,
    required this.subject,
    required this.questionCount,
    required this.isReviewDay,
  });

  /// 0 = bugün.
  final int dayIndex;

  /// Ne çalışılacak (konu adı ya da "genel tekrar").
  final String focus;

  /// Hangi ders (genel tekrarda null).
  final Subject? subject;
  final int questionCount;

  /// Bu gün YENİ konu değil, tekrar günü mü.
  final bool isReviewDay;
}

/// Günlük soru hedefi.
///
/// Yirmi, on beş–yirmi dakikalık bir oturuma denk gelir. Daha büyük bir hedef ilk gün heyecanla
/// yapılır, ikinci gün yapılmaz ve plan terk edilir; asıl amaç SÜREKLİLİK.
const int kDailyQuestionTarget = 20;

/// Beta Faz 7 — yedi günlük UYARLANIR çalışma planı.
///
/// ## Neden uyarlanır
///
/// Sabit bir müfredat ("1. gün trafik, 2. gün ilk yardım…") herkese aynı şeyi söyler ve zaten
/// bildiği konuyu tekrar ettirir. Plan, kullanıcının KENDİ zayıf konularından kurulur.
///
/// ## Neden her gün yeni konu değil
///
/// Üçüncü ve yedinci günler TEKRAR günüdür. Aralıklı tekrar olmadan öğrenilen konu bir hafta
/// içinde unutulur; plan "yeni konu" ile "unutmama" arasında denge kurmalı. Zayıf konu sayısı
/// azsa plan onları döndürür — uydurma konu ÜRETMEZ.
List<StudyDay> sevenDayPlan({
  required List<WeakTopic> weak,
  required int dueCardCount,
}) {
  final plan = <StudyDay>[];
  for (var day = 0; day < 7; day++) {
    // 3. ve 7. gün (indeks 2 ve 6) tekrar.
    final isReview = day == 2 || day == 6;
    if (isReview) {
      plan.add(
        StudyDay(
          dayIndex: day,
          focus: dueCardCount > 0 ? 'Tekrar — vadesi gelen $dueCardCount kart' : 'Genel tekrar',
          subject: null,
          questionCount: dueCardCount > 0 ? dueCardCount.clamp(10, 30) : kDailyQuestionTarget,
          isReviewDay: true,
        ),
      );
      continue;
    }

    if (weak.isEmpty) {
      // Zayıf konu yoksa uydurma: dürüstçe genel çalışma.
      plan.add(
        StudyDay(
          dayIndex: day,
          focus: 'Karışık çalışma',
          subject: null,
          questionCount: kDailyQuestionTarget,
          isReviewDay: false,
        ),
      );
      continue;
    }

    // Zayıf konular sırayla döner (az sayıdaysa tekrar ederler — bu doğru: en zayıf konu
    // haftada birden çok kez çalışılmalı).
    final topic = weak[plan.where((d) => !d.isReviewDay).length % weak.length];
    plan.add(
      StudyDay(
        dayIndex: day,
        // Plan da insan okunur ad taşır; kart onu olduğu gibi çizer.
        focus: humanizeTopic(topic.topic),
        subject: topic.subject,
        questionCount: kDailyQuestionTarget,
        isReviewDay: false,
      ),
    );
  }
  return plan;
}

/// Sınav tahmininin GÜVENİLİRLİĞİ.
enum PredictionConfidence {
  /// Tahmin yapmaya yetecek veri yok.
  none,

  /// Az veri — yön gösterir, sayı ciddiye alınmamalı.
  low,

  /// Yeterli veri.
  medium,

  /// Bol veri ve istikrarlı.
  high,
}

/// Sınav tahmini.
@immutable
class ExamForecast {
  const ExamForecast({
    required this.confidence,
    required this.predictedCorrect,
    required this.passProbability,
    required this.basedOnAnswers,
  });

  final PredictionConfidence confidence;

  /// 50 soruluk sınavda beklenen doğru sayısı.
  final int predictedCorrect;
  final double passProbability;
  final int basedOnAnswers;

  /// Barajı (35) geçiyor mu.
  bool get predictsPass => predictedCorrect >= examPassCorrect;
}

/// Kaç cevaptan sonra tahmin YAPILIR.
const int kMinAnswersForForecast = 20;

/// Beta Faz 7 — gelecek sınav tahmini.
///
/// ## Neden "güven" alanı var
///
/// Tahmin, kullanıcının en çok inanacağı ve en çok inanmaması gereken çıktıdır. Yirmi soru çözmüş
/// birine "sınavdan 38 alırsın" demek, sayı doğru görünse bile YANLIŞTIR: örneklem küçük, konu
/// dağılımı çarpık, sınav koşulu yok. Sayıyı gizlemek yerine **ne kadar güvenilir olduğunu** söylemek
/// tek dürüst yol.
///
/// ## Neden ağırlıklı
///
/// Ham doğruluk, sınav dağılımını yok sayar. Kullanıcı 50 sorunun 23'ünün geldiği trafikte zayıf,
/// 6 sorunun geldiği adabda güçlüyse ham ortalama onu iyimser gösterir. `computeReadiness` bu
/// ağırlığı zaten uyguluyor — tahmin ondan türetilir, yeniden hesaplanmaz.
ExamForecast examForecast({required Readiness? readiness, required int answeredCount}) {
  if (readiness == null || answeredCount < kMinAnswersForForecast) {
    return ExamForecast(
      confidence: PredictionConfidence.none,
      predictedCorrect: 0,
      passProbability: 0,
      basedOnAnswers: answeredCount,
    );
  }

  final confidence = switch (answeredCount) {
    < 60 => PredictionConfidence.low,
    < 200 => PredictionConfidence.medium,
    _ => PredictionConfidence.high,
  };

  return ExamForecast(
    confidence: confidence,
    predictedCorrect: (readiness.overall / 100 * examTotalQuestions).round(),
    passProbability: readiness.predictedPassProbability,
    basedOnAnswers: answeredCount,
  );
}

/// Tahminin güvenilirliğini KULLANICI DİLİNDE söyle.
///
/// Bu metin, sayının yanında durmak zorunda: yalnız "38/50" gösterilirse kullanıcı onu bir söz
/// sanır. Sınavdan kalırsa suçlu uygulamadır.
String confidenceLabel(ExamForecast f) => switch (f.confidence) {
  PredictionConfidence.none =>
    'Tahmin için henüz yeterli veri yok — $kMinAnswersForForecast soru çözünce burada belirir.',
  PredictionConfidence.low =>
    'Az veriye dayanıyor (${f.basedOnAnswers} soru); yön gösterir, kesin sonuç değildir.',
  PredictionConfidence.medium => '${f.basedOnAnswers} soruya dayanıyor. Çözdükçe netleşir.',
  PredictionConfidence.high => '${f.basedOnAnswers} soruya dayanıyor — güvenilir bir tahmin.',
};

/// Konu ETİKETİNİ (slug) insanın okuyabileceği hâle getir.
///
/// ## Neden gerekliydi (cihazda görüldü)
///
/// Soru bankasındaki `topic` alanı bir SLUG'dır: `kavsaklarda-gecis-onceligi`, `abc-degerlendirme`,
/// `112-arama`. Zayıf konu kartı ve çalışma planı bunları ham hâlde gösteriyordu; kullanıcı
/// "abc-degerlendirme" diye bir şey okumaz ve ekran teknik bir dökümanmış gibi görünür.
///
/// ## Neden `toUpperCase()` yetmez — TÜRKÇE
///
/// Dart'ın `toUpperCase()` metodu `i` harfini `I` yapar. Türkçede doğrusu `İ`'dir: "ilk yardım" →
/// "İlk yardım", "Ilk yardım" DEĞİL. Aynı biçimde `ı` → `I`. Bu, Türkçe bir üründe göze en çok
/// batan hatalardan biridir ve düzeltmesi tek bir eşlemedir.
String humanizeTopic(String slug) {
  if (slug.isEmpty) return slug;
  final words = slug.split('-').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return slug;

  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    // Bilinen kısaltmalar büyük harf kalır: "abs" → "ABS". Küçük yazılırsa yazım hatası gibi durur.
    if (_knownAcronyms.contains(w)) {
      out.add(w.toUpperCase());
      continue;
    }
    // Sayı ile başlayan parça olduğu gibi kalır ("112").
    if (RegExp(r'^\d').hasMatch(w)) {
      out.add(w);
      continue;
    }
    // YALNIZ ilk kelime büyük harfle başlar; gerisi cümle gibi akar. Her kelimeyi büyütmek
    // ("Kavşaklarda Geçiş Önceliği") başlık gibi durur ve liste içinde gürültü yapar.
    out.add(i == 0 ? _capitalizeTr(w) : w);
  }
  return out.join(' ');
}

const _knownAcronyms = {'abs', 'esp', 'asr', 'ebd', 'led', 'gps', 'ttb', 'abc'};

/// Türkçe kurallarına uygun ilk-harf büyütme.
String _capitalizeTr(String word) {
  if (word.isEmpty) return word;
  final first = word[0];
  final upper = switch (first) {
    'i' => 'İ',
    'ı' => 'I',
    _ => first.toUpperCase(),
  };
  return upper + word.substring(1);
}
