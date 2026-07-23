import 'dart:math' as math;

import '../practice/srs.dart';

/// Oyunlaştırma — XP, seviye, rozetler, çalışma ısı haritası. Saf, yerel sinyallerden hesaplanır
/// (cevaplar/seri/sayaçlar), çevrimdışı + deterministik. Sunucu gerekmez.

/// XP: doğru = 10, yanlış (katılım) = 3.
int xpFromAnswers(List<AnswerLog> answers) {
  var xp = 0;
  for (final a in answers) {
    xp += a.correct ? 10 : 3;
  }
  return xp;
}

/// Seviye modeli — her seviye artan XP gerektirir (kare-kök eğrisi).
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.xp,
    required this.levelStartXp,
    required this.nextLevelXp,
  });
  final int level;
  final int xp;
  final int levelStartXp;
  final int nextLevelXp;

  /// Bu seviye içindeki ilerleme (0..1).
  double get progress {
    final span = nextLevelXp - levelStartXp;
    if (span <= 0) return 1;
    return ((xp - levelStartXp) / span).clamp(0.0, 1.0);
  }

  int get xpToNext => math.max(0, nextLevelXp - xp);
}

/// Seviye eşiği: level L, `50 * L * (L-1)` toplam XP'de başlar (0,100,300,600,1000,…).
int _levelStartXp(int level) => 50 * level * (level - 1);

LevelInfo levelForXp(int xp) {
  var level = 1;
  while (xp >= _levelStartXp(level + 1)) {
    level++;
  }
  return LevelInfo(
    level: level,
    xp: xp,
    levelStartXp: _levelStartXp(level),
    nextLevelXp: _levelStartXp(level + 1),
  );
}

/// Başarı rozeti.
class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
  });
  final String id;
  final String icon;
  final String title;
  final String description;
  final bool unlocked;
}

/// Deterministik rozetler — cevap/seri/sınav sinyallerinden kilitli/açık.
List<Achievement> computeAchievements({
  required List<AnswerLog> answers,
  required StreakState streak,
  required int examsFinished,
}) {
  final answered = answers.length;
  final correct = answers.where((a) => a.correct).length;
  return [
    Achievement(
      id: 'first-steps',
      icon: '👣',
      title: 'İlk Adım',
      description: 'İlk soruyu çöz',
      unlocked: answered >= 1,
    ),
    Achievement(
      id: 'century',
      icon: '💯',
      title: 'Yüzler Kulübü',
      description: '100 soru çöz',
      unlocked: answered >= 100,
    ),
    Achievement(
      id: 'sharp',
      icon: '🎯',
      title: 'Keskin Nişancı',
      description: '50 doğru cevap',
      unlocked: correct >= 50,
    ),
    Achievement(
      id: 'streak-3',
      icon: '🔥',
      title: '3 Gün Seri',
      description: '3 gün üst üste çalış',
      unlocked: streak.best >= 3,
    ),
    Achievement(
      id: 'streak-7',
      icon: '🗓️',
      title: 'Haftalık İstikrar',
      description: '7 gün üst üste çalış',
      unlocked: streak.best >= 7,
    ),
    Achievement(
      id: 'first-exam',
      icon: '📝',
      title: 'İlk Deneme',
      description: 'Bir deneme sınavı bitir',
      unlocked: examsFinished >= 1,
    ),
    Achievement(
      id: 'exam-veteran',
      icon: '🏅',
      title: 'Deneme Ustası',
      description: '10 deneme sınavı bitir',
      unlocked: examsFinished >= 10,
    ),
  ];
}

/// Gün anahtarı (yerel) → o gün cevaplanan soru sayısı (ısı haritası için).
Map<String, int> answersPerDay(List<AnswerLog> answers) {
  final map = <String, int>{};
  for (final a in answers) {
    final d = DateTime.fromMillisecondsSinceEpoch(a.at);
    String p(int n) => n.toString().padLeft(2, '0');
    final key = '${d.year}-${p(d.month)}-${p(d.day)}';
    map[key] = (map[key] ?? 0) + 1;
  }
  return map;
}
