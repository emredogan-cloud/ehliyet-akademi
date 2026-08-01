import 'exam.dart' show BuiltExam, seedFromDate;
import 'exam_v2.dart';
import 'question.dart';
import 'srs.dart' show examDistribution, examTotalQuestions;
import '../content/content_enums.dart';

/// Ürün Evrimi v1.1 · Faz 2 — SINAV KÜTÜPHANESİ.
///
/// Kullanıcı yalnız **kategori ve tarih** görür. Arkada her sınav, o tarihin tohumundan
/// `buildExamV2` ile ÜRETİLİR — elle yazılmış sınav yoktur, kopyalanmış kâğıt hiç yoktur.
///
/// TASARIM KARARI — takvim YUVARLANIR.
///
/// Önceki `historical.dart` 18 sabit tarih tutuyordu (2015–2018) ve zamanla bayatlıyordu:
/// 2026'da açılan uygulama kullanıcıya sekiz yıl önceki tarihleri gösteriyordu. Burada tarihler
/// "bugünden geriye günlük" olarak TÜRETİLİR; liste hiç güncellenmeden hep taze kalır.
///
/// TASARIM KARARI — ders başına sınav uzunluğu MEB payına eşit.
///
/// Referans uygulamanın kataloğunda İlk Yardım sınavları 12, Trafik 23, Motor 9, Adab 6 soruluk.
/// Bu keyfi değil: her dersin 50 soruluk sınavdaki payı. Aynı sayıyı kullanmak, ders sınavını
/// gerçek sınavın o dersten sorulacak bölümünün provası hâline getiriyor.

/// Kütüphanedeki bir kategori.
enum ExamCategory {
  /// Tam MEB dağılımı — 50 soru.
  genel,
  trafik,
  ilkyardim,
  motor,
  adab,

  /// Yalnız görselli sorular. Referanstaki "Animasyonlu Sorular"ın dürüst karşılığı:
  /// elimizde animasyon YOK, görsel var. Olmayan bir şeyi vaat etmiyoruz.
  gorsel;

  String get label => switch (this) {
    ExamCategory.genel => 'Genel Sınav',
    ExamCategory.trafik => 'Trafik ve Çevre Bilgisi',
    ExamCategory.ilkyardim => 'İlk Yardım Bilgisi',
    ExamCategory.motor => 'Motor ve Araç Tekniği',
    ExamCategory.adab => 'Trafik Adabı',
    ExamCategory.gorsel => 'Görsel Sorular',
  };

  /// Tek derse bağlı kategorilerin dersi; genel ve görsel için null.
  Subject? get subject => switch (this) {
    ExamCategory.trafik => Subject.trafik,
    ExamCategory.ilkyardim => Subject.ilkyardim,
    ExamCategory.motor => Subject.motor,
    ExamCategory.adab => Subject.adab,
    ExamCategory.genel || ExamCategory.gorsel => null,
  };

  /// Bu kategorideki bir sınavın soru sayısı.
  int get questionCount => switch (this) {
    ExamCategory.genel => examTotalQuestions,
    ExamCategory.gorsel => 10,
    _ => examDistribution[subject!.name] ?? 10,
  };

  /// Kısa açıklama — katalog kartında görünür.
  String get blurb => switch (this) {
    ExamCategory.genel => 'Gerçek e-Sınav düzeni: $questionCount soru, dört dersten',
    ExamCategory.gorsel => 'Levha, ikaz ışığı ve araç parçası soruları',
    _ => '$questionCount soru — bu dersin e-Sınavdaki payı kadar',
  };
}

/// Kütüphanedeki tek bir sınav — kullanıcıya yalnız tarihiyle görünür.
class LibraryExam {
  const LibraryExam({
    required this.category,
    required this.date,
    required this.label,
    required this.index,
  });

  final ExamCategory category;

  /// `YYYY-MM-DD`.
  final String date;

  /// Ekranda görünen ad, ör. "1 Ağustos 2026 Sınav Soruları".
  final String label;

  /// Listedeki sıra — 0 en yeni. Ücretsiz/premium sınırı buna bakar.
  final int index;

  /// Kimlik: kategori + tarih. Tohum da bundan türer, dolayısıyla aynı kimlik hep aynı sınav.
  String get id => '${category.name}-$date';
}

const List<String> _monthLabels = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Kategori başına gösterilecek sınav sayısı. Referans uygulama ~31–34 tutuyor; bir aylık
/// günlük takvim hem tanıdık hem de listeyi sonsuza uzatmıyor.
const int kLibraryExamsPerCategory = 30;

/// İlk kaç sınav ücretsiz.
///
/// Sınır KATEGORİ BAŞINA DEĞİL, katalog genelinde uygulanır — altı kategoride üçer ücretsiz
/// sınav, 18 ücretsiz sınav demekti ve premium'un anlamı kalmazdı. Bkz. [isExamFree].
const int kFreeExamCount = 3;

/// [category] için bugünden geriye günlük sınav listesi.
///
/// [today] dışarıdan verilir: `DateTime.now()` çağırmak bu fonksiyonu test edilemez ve gece
/// yarısı davranışı belirsiz hâle getirirdi.
List<LibraryExam> libraryExams(ExamCategory category, DateTime today) {
  final out = <LibraryExam>[];
  for (var i = 0; i < kLibraryExamsPerCategory; i++) {
    final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
    final date = '${d.year}-${_two(d.month)}-${_two(d.day)}';
    out.add(
      LibraryExam(
        category: category,
        date: date,
        label: '${d.day} ${_monthLabels[d.month - 1]} ${d.year} Sınav Soruları',
        index: i,
      ),
    );
  }
  return out;
}

/// Bu sınav ücretsiz mi?
///
/// KURAL: her kategorinin ilk [kFreeExamCount] sınavı DEĞİL — **kataloğun tamamında** ilk üç.
/// Kullanıcı hangi kategoriden başlarsa başlasın üç sınav dener; dördüncüde premium çıkar.
/// Bunu "hangi kategori" bilgisinden bağımsız kılmak için ölçüt sınavın sıra numarasıdır ve
/// yalnız GENEL kategoride ücretsiz sınav bulunur.
///
/// Neden genel: yeni kullanıcının ilk denemesi gerçek sınav provası olmalı; tek derslik bir
/// sınavla "bu uygulama beni sınava hazırlıyor mu?" sorusu yanıtlanamaz.
bool isExamFree(LibraryExam exam) =>
    exam.category == ExamCategory.genel && exam.index < kFreeExamCount;

/// Kullanıcı bu sınavı açabilir mi?
bool canOpenExam(LibraryExam exam, {required bool premium}) => premium || isExamFree(exam);

/// Bir kütüphane sınavının üreteç ayarı.
///
/// Tohum `kategori-tarih`ten türer: aynı tarih + aynı kategori → HEP aynı sınav. Kullanıcı
/// yarım bıraktığı sınava döndüğünde aynı soruları bulur; iki kullanıcı aynı sınavı konuşabilir.
ExamConfig examConfigFor(LibraryExam exam) {
  final seed = seedFromDate('${exam.category.name}:${exam.date}');
  final subject = exam.category.subject;

  return switch (exam.category) {
    // Genel: tam MEB dağılımı, üreteç kendi paylaştırsın.
    ExamCategory.genel => ExamConfig.forMode(
      ExamMode.historical,
      seed: seed,
    ).copyWithVisualRatio(0.2),

    // Görsel: dağılım gözetilmez. `visualRatio` KULLANILMAZ — o, kurulmuş bir sınava görsel
    // SERPİŞTİRİR; buradaysa sınavın tamamı görsel olmalı. Doğru yol havuzu süzmek
    // (bkz. [buildLibraryExam]): "görsel sınavı" = görsel havuzdan kurulmuş sınav.
    ExamCategory.gorsel => ExamConfig(
      mode: ExamMode.historical,
      count: exam.category.questionCount,
      subjects: const {},
      seed: seed,
    ),

    // Tek ders: yalnız o dersten, o dersin e-Sınav payı kadar.
    _ => ExamConfig(
      mode: ExamMode.historical,
      count: exam.category.questionCount,
      subjects: {subject!: exam.category.questionCount},
      visualRatio: 0.2,
      seed: seed,
    ),
  };
}

/// Kütüphane sınavını kur.
///
/// Görsel kategoride HAVUZ SÜZÜLÜR: sınav yalnız görselli sorulardan kurulur. Diğer
/// kategorilerde havuz olduğu gibi verilir, üreteç dağılımı kendisi kurar.
BuiltExam buildLibraryExam(List<Question> bank, LibraryExam exam) {
  final pool = exam.category == ExamCategory.gorsel
      ? bank.where((q) => q.kind.needsMedia).toList()
      : bank;
  return buildExamV2(pool, examConfigFor(exam)).exam;
}

/// Kimlikten sınavı çöz (derin bağlantı / kaydedilmiş oturum için).
///
/// [today] gerekli çünkü `index` — dolayısıyla ücretsizlik — takvimdeki yere bağlı.
LibraryExam? libraryExamById(String id, DateTime today) {
  for (final c in ExamCategory.values) {
    for (final e in libraryExams(c, today)) {
      if (e.id == id) return e;
    }
  }
  return null;
}

/// Kütüphanenin dürüst etiketi — her sınav listesinin başında görünür.
const String libraryDisclaimer =
    'Her sınav, o tarihin soru dağılımına göre bankamızdan ÖZGÜN olarak üretilir. '
    'Telifli sınav kâğıdı sunulmaz.';

/// Kategorinin bankadaki soru havuzu — katalog kartında "kaç soru" yazmak için.
int poolSizeFor(ExamCategory category, List<Question> bank) => switch (category) {
  ExamCategory.genel => bank.length,
  ExamCategory.gorsel => bank.where((q) => q.kind.needsMedia).length,
  _ => bank.where((q) => q.subject == category.subject).length,
};

/// Ad → kategori. Yönlendirici yol parçasını çözerken kullanır; tanınmayan ad null döner
/// (uydurma bir kategori üretmek yerine katalog ekranına dönülür).
ExamCategory? examCategoryByName(String? name) {
  for (final c in ExamCategory.values) {
    if (c.name == name) return c;
  }
  return null;
}
