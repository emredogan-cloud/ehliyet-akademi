import 'lesson.dart';

/// Sesli anlatım — Premium Kalite Programı · Faz 5.
///
/// ## Bu katmanın sınırı
///
/// Ses SENTEZİ bir dış servistir ve bu oturumda bağlanmıyor. Bağlanmayan bir şeyin etrafına
/// yazılabilecek iki tür kod var:
///
/// 1. **Bugün çalışan kısım** — metnin nereden geleceği, nasıl bölümleneceği, oynatıcının
///    hangi durumları taşıyacağı, ses YOKKEN arayüzün ne yapacağı.
/// 2. **Bugün çalışmayan kısım** — sentezin kendisi.
///
/// Burada yalnız (1) var ve (1) gerçekten çalışıyor: metin bugün üretiliyor, testleniyor ve
/// ekranda gösterilebiliyor. (2) için tek bir arayüz (`NarrationSource`) bırakıldı.
///
/// ## Metin neden ÜRETİLİYOR, yazılmıyor
///
/// Sesli özet için ayrı bir metin yazmak, aynı bilgiyi ikinci kez ve senkron kalması gereken
/// bir yerde tutmak demekti: ders güncellenince ses metni bayatlar ve kimse fark etmez.
/// Anlatım metni dersin KENDİSİNDEN türetiliyor — özet, hedefler ve bölüm başlıkları.
/// Böylece ders değişince anlatım da değişir.

/// Anlatımın tek bir parçası — bir başlık ve okunacak metin.
///
/// Parçalara bölünmesi şart: kullanıcı "şu bölümü tekrar dinle" diyebilmeli ve sentez
/// bağlandığında her parça ayrı ayrı önbelleğe alınabilmeli. Tek bir uzun metin bunların
/// ikisini de imkânsız kılardı.
class NarrationSegment {
  const NarrationSegment({required this.id, required this.title, required this.text});

  /// Ders içinde benzersiz — önbellek anahtarının parçası olur.
  final String id;
  final String title;
  final String text;

  /// Kabaca kaç saniye sürer.
  ///
  /// Türkçe için dakikada ~150 sözcük varsayıldı (sakin, öğretici tempo). Kesin değil ve
  /// öyle olduğu iddia edilmiyor; amacı kullanıcıya "bu ne kadar sürer" sorusunun yanıtını
  /// ses gelmeden önce verebilmek. Gerçek süre geldiğinde bu tahmin onunla değiştirilir.
  int get estimatedSeconds {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 150 * 60).ceil().clamp(1, 3600);
  }
}

/// Bir dersin tam anlatımı.
class LessonNarration {
  const LessonNarration({required this.lessonId, required this.title, required this.segments});

  final String lessonId;
  final String title;
  final List<NarrationSegment> segments;

  int get estimatedSeconds =>
      segments.fold(0, (sum, s) => sum + s.estimatedSeconds);

  bool get isEmpty => segments.isEmpty;
}

/// Markdown süslerini sesli okuma için temizler.
///
/// `**kalın**`, `*eğik*` ve `` `kod` `` işaretleri ekranda biçim taşır ama seslendirmede
/// okunacak birer yıldız olur. Bağlantı metinleri korunur, hedefleri atılır.
String stripMarkdownForSpeech(String input) {
  var out = input;
  out = out.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1] ?? '');
  out = out.replaceAll(RegExp(r'[*_`~]'), '');
  out = out.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  out = out.replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '');
  return out.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

/// Dersten anlatım metni türet.
///
/// SIRA öğretim sırasıdır, dosya sırası değil: önce dersin ne olduğu (özet), sonra ne
/// kazandıracağı (hedefler), sonra bölümler, en sonda akılda kalması istenenler.
/// Sesli dinleyen kişi ekrana bakmadığı için bu çerçeve daha da önemli.
LessonNarration buildLessonNarration(Lesson lesson) {
  final segments = <NarrationSegment>[];

  final summary = stripMarkdownForSpeech(lesson.summary);
  if (summary.isNotEmpty) {
    segments.add(
      NarrationSegment(id: 'ozet', title: 'Özet', text: '${lesson.title}. $summary'),
    );
  }

  if (lesson.objectives.isNotEmpty) {
    // Hedefler madde madde okunur; aralarına nokta konur ki sentez duraklasın.
    final text = lesson.objectives.map(stripMarkdownForSpeech).where((t) => t.isNotEmpty).join('. ');
    if (text.isNotEmpty) {
      segments.add(
        NarrationSegment(id: 'hedefler', title: 'Bu derste', text: 'Bu derste şunları öğreneceksiniz. $text.'),
      );
    }
  }

  for (var i = 0; i < lesson.sections.length; i++) {
    final s = lesson.sections[i];
    final body = stripMarkdownForSpeech(s.body);
    if (body.isEmpty) continue;
    segments.add(
      NarrationSegment(
        id: 'bolum-$i',
        title: stripMarkdownForSpeech(s.heading),
        text: '${stripMarkdownForSpeech(s.heading)}. $body',
      ),
    );
  }

  if (lesson.keyTakeaways.isNotEmpty) {
    final text = lesson.keyTakeaways
        .map(stripMarkdownForSpeech)
        .where((t) => t.isNotEmpty)
        .join('. ');
    if (text.isNotEmpty) {
      segments.add(
        NarrationSegment(id: 'ozet-kapanis', title: 'Akılda kalsın', text: 'Akılda kalması gerekenler. $text.'),
      );
    }
  }

  return LessonNarration(lessonId: lesson.id, title: lesson.title, segments: segments);
}

/// Oynatma hızı seçenekleri.
///
/// 0,75× yavaş anlatım (yeni konu), 1,0× normal, 1,25× ve 1,5× tekrar dinleme içindir.
/// 2× bilinçli olarak YOK: eğitim içeriğinde anlamayı bozduğu için sunulmuyor.
enum NarrationSpeed {
  slow(0.75, '0,75×'),
  normal(1.0, '1×'),
  fast(1.25, '1,25×'),
  faster(1.5, '1,5×');

  const NarrationSpeed(this.rate, this.label);
  final double rate;
  final String label;

  NarrationSpeed get next => switch (this) {
    NarrationSpeed.slow => NarrationSpeed.normal,
    NarrationSpeed.normal => NarrationSpeed.fast,
    NarrationSpeed.fast => NarrationSpeed.faster,
    NarrationSpeed.faster => NarrationSpeed.slow,
  };
}
