import '../onboarding/study_profile.dart';
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

/// Evolution Faz E5 — sınıfa özgü odak seti için kavram örüntüleri.
///
/// ÖNEMLİ: bu setlerin soruları BANKADAN gelir; hiçbir soru uydurulmaz veya sınıfa göre yeniden
/// yazılmaz. e-Sınav teori bankası tüm sınıflarda ORTAKTIR; burada yapılan tek şey, o sınıfın
/// aracını/mesleğini doğrudan konu alan gerçek soruları bir araya getirmektir.
final RegExp _motoPattern = RegExp(
  r'motosiklet|motorlu bisiklet|kask(?!o)|skuter',
  caseSensitive: false,
);
final RegExp _busPattern = RegExp(
  r'otobüs|minibüs|yolcu taşı|yolcu indir|yolcu bindir|ticari araç|kamyon|çekici|römork|taşıt katarı|okul taşıt|servis araç',
  caseSensitive: false,
);

/// Sorunun tüm metni (kök + şıklar + açıklama + konu) — eşleşme bunun üzerinde yapılır.
String _haystack(Question q) => [q.stem, ...q.options, q.explanation, q.topic].join(' ');

/// Bu sınıfın aracını doğrudan konu alan bankadaki gerçek sorular.
List<Question> licenceFocusQuestions(List<Question> bank, LicenceCategory licence) {
  final pattern = switch (licence) {
    LicenceCategory.a => _motoPattern,
    LicenceCategory.d => _busPattern,
    // B sınıfı bankanın varsayılan odağıdır; yapay bir alt küme üretmek yanıltıcı olur.
    LicenceCategory.b => null,
  };
  if (pattern == null) return const [];
  return bank.where((q) => pattern.hasMatch(_haystack(q))).toList();
}

/// Koleksiyonları üret (gerçek sayılar). [daySeed]/[weekSeed] tarih tohumlarıdır.
/// [licence] verilirse sınıfa özgü odak seti listenin BAŞINA eklenir (Faz E5).
List<CollectionSpec> examCollections(
  List<Question> bank, {
  required int daySeed,
  required int weekSeed,
  LicenceCategory? licence,
}) {
  final out = <CollectionSpec>[];
  void add(String id, String label, String description, String emoji, List<String> ids) {
    out.add(
      CollectionSpec(id: id, label: label, description: description, emoji: emoji, questionIds: ids),
    );
  }

  if (licence != null) {
    final focus = licenceFocusQuestions(bank, licence);
    if (focus.isNotEmpty) {
      // Tümü alınır (kırpılmaz) → kartta görünen sayı gerçek sayıdır; sıra günlük tohumla karışır.
      final ids = shuffle(focus, seededRng(daySeed + 77)).map((q) => q.id).toList();
      switch (licence) {
        case LicenceCategory.a:
          add(
            'motosiklet-odakli',
            'Motosiklet Odaklı',
            'Bankadaki motosiklet, kask ve iki tekerlek konulu gerçek sorular.',
            '🏍️',
            ids,
          );
        case LicenceCategory.d:
          add(
            'otobus-odakli',
            'Otobüs ve Yolcu Taşımacılığı',
            'Bankadaki otobüs, yolcu taşımacılığı ve ağır araç konulu gerçek sorular.',
            '🚌',
            ids,
          );
        case LicenceCategory.b:
          break;
      }
    }
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
  LicenceCategory? licence,
}) {
  for (final c in examCollections(
    bank,
    daySeed: daySeed,
    weekSeed: weekSeed,
    licence: licence,
  )) {
    if (c.id == id) return c;
  }
  return null;
}
