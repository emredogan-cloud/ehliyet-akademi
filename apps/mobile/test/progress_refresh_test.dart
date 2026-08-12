import 'package:ehliyet_akademi/data/practice/progress_repository.dart';
import 'package:ehliyet_akademi/domain/content/content_enums.dart';
import 'package:ehliyet_akademi/domain/practice/srs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ana Sayfa'nın ilerleme tazeleme sinyali — cihaz denetiminde bulunan kusurun kilidi.
///
/// ## Bulunan kusur (11 Ağustos 2026, Redmi Note 8 üzerinde)
///
/// 90 soru çözüldükten sonra Ana Sayfa hâlâ **%0 hazırlık · 0 soru · Lv 1** gösteriyordu.
/// İlerleme ekranı ise AYNI ANDA doğru değerleri gösteriyordu: 90 soru · %71 · Seviye 4.
/// Yani veri kaydedilmişti; görünmüyordu.
///
/// Sebep iki parçalıydı ve ikisi de tek başına zararsızdı:
///  1. `progressRepositoryProvider` bir `FutureProvider`'dır: bir kez çözülür, hep aynı örneği
///     döndürür. Deponun İÇİNDEKİ veri değişse de sağlayıcı yeni değer yaymaz.
///  2. Gezinme `StatefulShellRoute.indexedStack` kullanır: Pratik sekmesinde çalışılırken
///     Ana Sayfa dalı canlı kalır ve yeniden inşa EDİLMEZ.
///
/// Birleşince ekran açıldığı andaki sayılarda donuyordu; yalnız uygulama yeniden başlatılınca
/// düzeliyordu. Kullanıcı için bu "çalışmam kaydedilmedi" demektir.
///
/// Bu testler sinyalin var olduğunu ve HER yazma yolunda tetiklendiğini kilitler. Sinyal
/// sessizce kaldırılırsa hiçbir derleme hatası olmaz, hiçbir başka test kırılmaz — kusur
/// aynen geri gelir. Bu yüzden koruma burada duruyor.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProgressRepository> repo() async =>
      ProgressRepository(await SharedPreferences.getInstance(), null);

  test('cevap eklemek revizyonu artırır', () async {
    final r = await repo();
    final before = r.revision.value;
    await r.appendAnswers([
      AnswerLog(
        questionId: 'trafik-001',
        subject: Subject.trafik,
        topic: 'hiz',
        correct: true,
        at: 1,
      ),
    ]);
    expect(r.revision.value, greaterThan(before));
  });

  test('kart yazmak revizyonu artırır', () async {
    final r = await repo();
    final before = r.revision.value;
    await r.saveCards({
      'trafik-001': const SrsCard(
        questionId: 'trafik-001',
        ease: 2.5,
        intervalDays: 1,
        repetitions: 0,
        dueAt: 0,
        reviews: 0,
        lapses: 0,
      ),
    });
    expect(r.revision.value, greaterThan(before));
  });

  test('deneme sayacı revizyonu artırır', () async {
    final r = await repo();
    final before = r.revision.value;
    await r.incrementExamsFinished();
    expect(r.revision.value, greaterThan(before));
  });

  test('seri güncellemesi revizyonu artırır', () async {
    final r = await repo();
    final before = r.revision.value;
    await r.touchStreak(DateTime(2026, 8, 11).millisecondsSinceEpoch);
    expect(r.revision.value, greaterThan(before));
  });

  /// Dinleyici, ekranın gerçekten uyandığını temsil eder.
  test('dinleyici yazma sonrası uyanır', () async {
    final r = await repo();
    var woke = 0;
    r.revision.addListener(() => woke++);
    await r.appendAnswers([
      AnswerLog(
        questionId: 'motor-001',
        subject: Subject.motor,
        topic: 'fren',
        correct: false,
        at: 2,
      ),
    ]);
    await r.incrementExamsFinished();
    expect(woke, greaterThanOrEqualTo(2));
  });

  /// OKUMA yolu sinyal üretmemeli: aksi hâlde her çizimde kendini tetikleyen bir döngü kurulur.
  test('okuma revizyonu DEĞİŞTİRMEZ', () async {
    final r = await repo();
    await r.appendAnswers([
      AnswerLog(
        questionId: 'adab-001',
        subject: Subject.adab,
        topic: 'sabir',
        correct: true,
        at: 3,
      ),
    ]);
    final after = r.revision.value;
    r.loadAnswers();
    r.loadCards();
    r.loadStreak();
    r.examsFinished();
    r.readiness();
    expect(r.revision.value, after);
  });
}
