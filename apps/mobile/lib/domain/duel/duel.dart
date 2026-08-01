import '../practice/exam.dart' show Rng, seededRng;
import '../practice/exam_v2.dart';
import '../practice/question.dart';

/// Ürün Evrimi v1.1 · Faz 4 — **DÜELLO** (istenen adıyla "Race Mode").
///
/// AD KARARI: "Yarış" hız çağrıştırıyor ve bu modda hız TEK BAŞINA kazandırmıyor — doğruluk
/// ağır basıyor (bkz. [DuelScoring]). "Düello" karşılıklı ve eşit koşullu bir sınamayı anlatıyor,
/// sınav bağlamına da yabancı değil.
///
/// ## Çevrimiçi eşleşme için hazır
///
/// Rakip [DuelOpponent] ARAYÜZÜ ile soyutlandı. Bugün tek uygulaması [AiOpponent]; yarın gelecek
/// `RemoteOpponent` aynı arayüzü uygular ve **ekran kodu değişmez**. Bu yüzden `answerFor`
/// asenkron: yerel yapay zekâ hemen döner, ağ üzerinden gelen rakip beklenir.
///
/// ## Sahte oyuncu YOK
///
/// Rakibe uydurma bir kullanıcı adı verilmiyor. Yapay zekâ rakip açıkça "Rakip" olarak
/// adlandırılıyor ve seviyesi gösteriliyor. Sahte isim üretmek, çevrimiçi olmayan bir özelliği
/// çevrimiçiymiş gibi göstermek olurdu.

/// Bir düello sorusuna verilen yanıt.
class DuelAnswer {
  const DuelAnswer({required this.choice, required this.elapsedMs});

  /// Seçilen şık; süre dolduysa null (cevapsız).
  final int? choice;

  /// Cevaba kadar geçen süre. Süre dolduysa soru süresine eşittir.
  final int elapsedMs;

  bool isCorrectFor(Question q) => choice == q.answerIndex;
}

/// Rakip sözleşmesi. Yerel yapay zekâ da uzaktaki oyuncu da bunu uygular.
abstract class DuelOpponent {
  /// Ekranda görünen ad.
  String get name;

  /// Seviye rozeti.
  int get level;

  /// [question] için rakibin yanıtı.
  ///
  /// Asenkron ÇÜNKÜ çevrimiçi rakip beklenecek. Yerel yapay zekâ hemen döner.
  Future<DuelAnswer> answerFor(Question question, int index);
}

/// Belirlenimci yapay zekâ rakip.
///
/// Rakibin gücü tek bir sayıyla ayarlanır: [accuracy]. Bu, oyuncunun seviyesinden türetilir —
/// böylece yeni kullanıcı ezilmez, iyi kullanıcı sıkılmaz.
///
/// BELİRLENİMCİ: aynı tohum + aynı sorular → aynı rakip davranışı. Bu, hem testi mümkün kılıyor
/// hem de "rakip hile yapıyor" hissini engelliyor (sonuç tekrar oynatılabilir).
class AiOpponent implements DuelOpponent {
  AiOpponent({
    required this.level,
    required int seed,
    this.name = 'Rakip',
    double? accuracy,
  }) : _rng = seededRng(seed),
       accuracy = accuracy ?? accuracyForLevel(level);

  @override
  final String name;

  @override
  final int level;

  /// Rakibin doğru cevaplama olasılığı (0..1).
  final double accuracy;

  final Rng _rng;

  /// Seviyeye göre rakip doğruluğu.
  ///
  /// 1. seviyede %55, 20. seviyede %85'te doyuyor. Tavan KASITLI olarak %85: %100 doğru bir
  /// rakip, oyuncunun kusursuz oynamadıkça kazanamayacağı demektir ve bu modu cezalandırıcı
  /// yapar. Taban %55: rastgeleden (%25) belirgin yüksek, yoksa rakip komik görünür.
  static double accuracyForLevel(int level) {
    final t = ((level - 1) / 19).clamp(0.0, 1.0);
    return 0.55 + 0.30 * t;
  }

  /// Rakibin düşünme süresi (ms) — insanı taklit eder, sabit değildir.
  ///
  /// Sabit gecikme "bot" hissi verir. 2,5–9 sn arası dağılım, gerçek bir insanın 20 saniyelik
  /// soruda harcadığı süreye yakın.
  static const int minThinkMs = 2500;
  static const int maxThinkMs = 9000;

  @override
  Future<DuelAnswer> answerFor(Question question, int index) async {
    final correct = _rng() < accuracy;
    final think = minThinkMs + (_rng() * (maxThinkMs - minThinkMs)).round();

    if (correct) return DuelAnswer(choice: question.answerIndex, elapsedMs: think);

    // Yanlış cevap RASTGELE değil, doğru şık DIŞINDAN seçilir — yoksa "yanlış" dediğimiz
    // durumda bazen doğruyu tutturur ve doğruluk oranı bozulur.
    final wrong = [
      for (var i = 0; i < question.options.length; i++)
        if (i != question.answerIndex) i,
    ];
    final pick = wrong[(_rng() * wrong.length).floor().clamp(0, wrong.length - 1)];
    return DuelAnswer(choice: pick, elapsedMs: think);
  }
}

/// Düello ayarları.
class DuelConfig {
  const DuelConfig({
    this.questionCount = 10,
    this.secondsPerQuestion = 20,
    this.seed,
  });

  final int questionCount;
  final int secondsPerQuestion;
  final int? seed;

  int get millisPerQuestion => secondsPerQuestion * 1000;
}

/// Puanlama.
///
/// TASARIM KARARI — hız TEK BAŞINA kazandırmaz.
///
/// Yalnız hıza puan verilseydi en iyi strateji "oku bile, rastgele bas" olurdu. Doğru cevap
/// [correctPoints] getirir; hız bonusu en fazla [maxSpeedBonus] ekler, yani bir doğru cevap
/// hiçbir zaman hızlı bir yanlıştan az etmez. Yanlış cevap puan GÖTÜRMEZ — ceza, tahmin etmeyi
/// değil cevaplamayı caydırır.
class DuelScoring {
  const DuelScoring._();

  static const int correctPoints = 100;
  static const int maxSpeedBonus = 50;

  /// Bir cevabın puanı.
  static int pointsFor(DuelAnswer a, Question q, DuelConfig config) {
    if (!a.isCorrectFor(q)) return 0;
    final limit = config.millisPerQuestion;
    final left = (limit - a.elapsedMs).clamp(0, limit);
    return correctPoints + (maxSpeedBonus * left / limit).round();
  }
}

/// Düello sonucu.
class DuelResult {
  const DuelResult({
    required this.playerScore,
    required this.opponentScore,
    required this.playerCorrect,
    required this.opponentCorrect,
    required this.total,
  });

  final int playerScore;
  final int opponentScore;
  final int playerCorrect;
  final int opponentCorrect;
  final int total;

  bool get won => playerScore > opponentScore;
  bool get drew => playerScore == opponentScore;
  bool get lost => playerScore < opponentScore;

  /// Kazanılan XP.
  ///
  /// KAYBEDEN DE XP ALIR. Sıfır veren bir sistem, kaybetmeyi cezalandırır ve oyuncu zayıf
  /// olduğu konudan kaçar — tam olarak çalışması gereken konudan. Doğru sayısı her hâlükârda
  /// ödüllendirilir; galibiyet üstüne bonus koyar.
  int get xp => playerCorrect * xpPerCorrect + (won ? xpWinBonus : 0) + (drew ? xpDrawBonus : 0);

  static const int xpPerCorrect = 10;
  static const int xpWinBonus = 50;
  static const int xpDrawBonus = 20;

  String get label => won ? 'Kazandın' : (drew ? 'Berabere' : 'Kaybettin');
}

/// Bir düellonun sorularını kur.
///
/// Üreteç V2 kullanılır: zorluk dengeli, aynı görsel tekrarlanmaz, şıklar karışır. Tohum
/// verilirse düello tekrar oynatılabilir (uyuşmazlık incelemesi ve test için).
List<Question> buildDuelQuestions(List<Question> bank, DuelConfig config) => buildExamV2(
  bank,
  ExamConfig(
    mode: ExamMode.quick,
    count: config.questionCount,
    subjects: const {},
    seed: config.seed,
    visualRatio: 0.2,
  ),
).exam.questions;

/// Oyuncu ve rakip cevaplarından sonucu hesapla.
DuelResult scoreDuel({
  required List<Question> questions,
  required List<DuelAnswer> player,
  required List<DuelAnswer> opponent,
  required DuelConfig config,
}) {
  var ps = 0;
  var os = 0;
  var pc = 0;
  var oc = 0;
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    if (i < player.length) {
      ps += DuelScoring.pointsFor(player[i], q, config);
      if (player[i].isCorrectFor(q)) pc++;
    }
    if (i < opponent.length) {
      os += DuelScoring.pointsFor(opponent[i], q, config);
      if (opponent[i].isCorrectFor(q)) oc++;
    }
  }
  return DuelResult(
    playerScore: ps,
    opponentScore: os,
    playerCorrect: pc,
    opponentCorrect: oc,
    total: questions.length,
  );
}
