import 'exam.dart';
import 'question.dart';

/// Otomatik sınav koleksiyonları — web `qip/collections.ts`'in mobil (analiz-katmansız) uyarlaması.
/// Deterministik: gün/hafta tohumundan → gün içinde sabit, günden güne farklı. Temalı setler bankadan
/// tohumlu seçilir (analiz katmanı yerine doğrudan alan filtreleri; pratik seti için yeterli).

class CollectionSpec {
  const CollectionSpec({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
    required this.questionIds,
  });
  final String id;
  final String label;
  final String description;
  final String emoji;
  final List<String> questionIds;

  int get count => questionIds.length;
}

List<String> _pick(List<Question> pool, Rng rng, int n) =>
    shuffle(pool, rng).take(n).map((q) => q.id).toList();

/// Koleksiyonları üret (gerçek sayılar). [daySeed]/[weekSeed] tarih tohumlarıdır.
List<CollectionSpec> examCollections(List<Question> bank, {required int daySeed, required int weekSeed}) {
  final out = <CollectionSpec>[];
  void add(String id, String label, String description, String emoji, List<String> ids) {
    out.add(
      CollectionSpec(id: id, label: label, description: description, emoji: emoji, questionIds: ids),
    );
  }

  // Günün / Haftanın Sınavı — MEB dağılımına uygun dengeli 50 soru (tohumlu buildExam).
  add(
    'gunun-sinavi',
    'Günün Sınavı',
    'Her gün yenilenen, MEB dağılımına uygun dengeli 50 soruluk sınav.',
    '📅',
    buildExam(bank, rng: seededRng(daySeed)).questions.map((q) => q.id).toList(),
  );
  add(
    'haftanin-sinavi',
    'Haftanın Sınavı',
    'Haftalık, MEB dağılımına uygun 50 soruluk sınav.',
    '🗓️',
    buildExam(bank, rng: seededRng(weekSeed)).questions.map((q) => q.id).toList(),
  );

  add(
    'baslangic',
    'Başlangıç',
    'Yeni başlayanlar için kolay sorular.',
    '🌱',
    _pick(bank.where((q) => q.difficulty == Difficulty.kolay).toList(), seededRng(daySeed + 11), 40),
  );
  add(
    'zor-sorular',
    'Zor Sorular',
    'Kendini sına: yalnızca zor sorular.',
    '🔥',
    _pick(bank.where((q) => q.difficulty == Difficulty.zor).toList(), seededRng(daySeed + 22), 40),
  );
  add(
    'sadece-isaretler',
    'Yalnız Trafik İşaretleri',
    'Trafik işaretleri temalı sorular.',
    '🚦',
    _pick(bank.where((q) => q.topic.contains('isaret')).toList(), seededRng(daySeed + 33), 40),
  );
  add(
    'sadece-motor',
    'Yalnız Araç Tekniği',
    'Motor ve araç tekniği soruları.',
    '🔧',
    _pick(bank.where((q) => q.subject.name == 'motor').toList(), seededRng(daySeed + 44), 40),
  );
  add(
    'sadece-ilkyardim',
    'Yalnız İlk Yardım',
    'İlk yardım bilgisi soruları.',
    '🚑',
    _pick(bank.where((q) => q.subject.name == 'ilkyardim').toList(), seededRng(daySeed + 55), 40),
  );
  add(
    'en-cok-yanilan',
    'En Çok Yanılan',
    'En zorlayıcı sorular (zorluğa göre).',
    '⚠️',
    _pick(
      bank.where((q) => q.difficulty != Difficulty.kolay).toList(),
      seededRng(daySeed + 88),
      40,
    ),
  );
  add(
    'rastgele-50',
    'Rastgele 50',
    'Bankadan rastgele 50 soru.',
    '🎲',
    _pick(bank, seededRng(daySeed + 66), 50),
  );

  // Boş kalanları (banka bir temada yetersizse) at.
  return out.where((c) => c.questionIds.isNotEmpty).toList();
}

CollectionSpec? collectionById(
  List<Question> bank,
  String id, {
  required int daySeed,
  required int weekSeed,
}) {
  for (final c in examCollections(bank, daySeed: daySeed, weekSeed: weekSeed)) {
    if (c.id == id) return c;
  }
  return null;
}
