import '../../core/dash_assets.dart';
import '../../core/mech_assets.dart';
import '../content/content_enums.dart';
import '../content/dash_lights.dart';
import '../content/traffic_sign.dart';
import '../content/vehicle_part.dart';
import 'exam.dart' show Rng, shuffle;
import 'question.dart';

/// QIP v3 · Faz 2+4 — DOĞRULANMIŞ KATALOGLARDAN görsel soru üretimi.
///
/// ## Neden cihazda üretiliyor, sunucuda değil
///
/// Üç katalog da (121 trafik işareti · 60 ikaz ışığı · 101 mekanik parça) **uygulamanın kendi
/// varlıklarıdır** ve pakete gömülüdür. Sorular sunucuda üretilip banka yüküne eklenseydi:
///
/// · indirilen banka ~%36 büyürdü (564 soru), oysa görselleri zaten cihazda,
/// · varlık kimliği yalnız cihazda çözülebildiği için sunucu "bu görsel var mı" diye
///   bilemezdi ve kırık görselli soru gönderebilirdi,
/// · ilk eşitleme öncesi tek bir görsel soru bile görünmezdi.
///
/// Cihazda üretmek bu üçünü birden çözer ve uygulamanın kurulu deseniyle aynıdır: saf mantık
/// (SRS, `buildExam`, koleksiyonlar) zaten Dart'a taşınmış durumda.
///
/// ## Özgünlük
///
/// Üretilen her soru **bizim kataloglarımızdan** kurulur: işaret anlamları, ikaz açıklamaları ve
/// parça tanımları bu depoda yazılmış özgün metinlerdir. Hiçbir dış kaynaktan soru kopyalanmaz.
///
/// ## Belirlenimcilik
///
/// Aynı tohum → aynı sorular, aynı sırayla. Bu, sınavın tekrar oynatılabilmesi ve testlerin
/// kararlı olması için şart.

/// Üreteç kimliği + sürümü — üretilmiş sorularda kusur bulunursa hangi turdan çıktıkları
/// buradan bilinir.
const String kVisualGenerator = 'visual-catalog';
const int kVisualGeneratorVersion = 1;

/// Dört şıkta üç çeldirici gerekir; havuz bundan küçükse soru KURULMAZ.
const int _distractorCount = kOptionCount - 1;

/// Ortak kurucu: doğru cevap + benzersiz çeldiriciler → dört şık, karışık sıra.
///
/// [correct] doğru metin, [pool] aynı kategoriden gelen aday metinler, [fallback] kategori
/// yetmezse başvurulacak geniş havuz. Çeldiriciler **önce aynı kategoriden** seçilir: farklı
/// kategoriden çeldirici soruyu kolaylaştırır ve öğretmez.
({List<String> options, int answerIndex})? _buildOptions(
  String correct,
  List<String> pool,
  List<String> fallback,
  Rng rng,
) {
  final seen = <String>{correct};
  final distractors = <String>[];
  for (final candidate in [...shuffle(pool, rng), ...shuffle(fallback, rng)]) {
    if (distractors.length >= _distractorCount) break;
    if (seen.add(candidate)) distractors.add(candidate);
  }
  // Yeterli benzersiz çeldirici yoksa soru üretilmez — üç şıklı soru üretmektense hiç üretmemek.
  if (distractors.length < _distractorCount) return null;
  final options = shuffle([correct, ...distractors], rng);
  return (options: options, answerIndex: options.indexOf(correct));
}

Question? _question({
  required String id,
  required Subject subject,
  required String topic,
  required Difficulty difficulty,
  required String stem,
  required String correct,
  required List<String> pool,
  required List<String> fallback,
  required String explanation,
  required String objective,
  required QuestionKind kind,
  required String assetId,
  required String alt,
  required Rng rng,
}) {
  final built = _buildOptions(correct, pool, fallback, rng);
  if (built == null) return null;
  return Question(
    id: id,
    subject: subject,
    topic: topic,
    difficulty: difficulty,
    stem: stem,
    options: built.options,
    answerIndex: built.answerIndex,
    explanation: explanation,
    objective: objective,
    kind: kind,
    media: QuestionMedia(images: [QuestionImage(assetId: assetId, alt: alt)]),
  );
}

/// Trafik işareti soruları — her işaret için "anlamı nedir?".
///
/// `assetId` olarak işaretin KİMLİĞİ konur, dosya yolu değil: resmî vektörü olmayan 35 levha
/// parametrik çiziciyle çizilir ve o çizici kimlikle çalışır. Yol yazılsaydı bu 35 levha için
/// soru üretilemezdi.
List<Question> buildSignQuestions(List<TrafficSign> signs, Rng rng) {
  final out = <Question>[];
  final allMeanings = [for (final s in signs) s.meaning];
  for (final sign in signs) {
    final sameCategory = [
      for (final s in signs)
        if (s.category == sign.category && s.id != sign.id) s.meaning,
    ];
    final q = _question(
      id: 'vq-sign-${sign.id}',
      subject: Subject.trafik,
      topic: 'Trafik İşaretleri',
      difficulty: Difficulty.orta,
      stem: 'Aşağıdaki trafik işareti ne anlama gelir?',
      correct: sign.meaning,
      pool: sameCategory,
      fallback: allMeanings,
      explanation: '${sign.name}: ${sign.meaning} ${sign.memoryTip}',
      objective: 'Trafik işaretini görselinden tanır ve anlamını söyler.',
      kind: QuestionKind.sign,
      assetId: sign.id,
      alt: '${sign.name} trafik işareti',
      rng: rng,
    );
    if (q != null) out.add(q);

    // İKİNCİ AÇI — "hangi gruba girer?".
    //
    // Anlamı ezberlemekle grubunu okumak AYNI beceri değildir ve ikincisi daha güçlüdür:
    // grubu şekil ve renkten çıkarabilen aday, hiç görmediği bir levhayı bile
    // sınıflandırabilir. Ders içeriğindeki "önce grubunu tanı" öğüdünün sınav karşılığı budur.
    //
    // Çeldirici havuzu KATEGORİ ETİKETLERİ; sekiz kategori var, üç benzersiz çeldirici
    // her zaman bulunur.
    final group = _question(
      id: 'vq-sign-${sign.id}-grup',
      subject: Subject.trafik,
      topic: 'Trafik İşaretleri',
      difficulty: Difficulty.kolay,
      stem: 'Aşağıdaki trafik işareti hangi işaret grubuna girer?',
      correct: sign.category.label,
      pool: [
        for (final c in SignCategory.values)
          if (c != sign.category) c.label,
      ],
      fallback: const [],
      explanation:
          '${sign.name}, "${sign.category.label}" grubundandır. ${sign.memoryTip} '
          'İşaretin şekli ve rengi grubunu ele verir; grubu tanımak, tek tek ezberlemekten güçlüdür.',
      objective: 'Trafik işaretini şekil ve renginden yola çıkarak grubuna yerleştirir.',
      kind: QuestionKind.sign,
      assetId: sign.id,
      alt: '${sign.name} trafik işareti',
      rng: rng,
    );
    if (group != null) out.add(group);
  }
  return out;
}

/// Gösterge paneli ikaz ışığı soruları — anlam + sürücünün yapması gereken.
///
/// İki açı üretilir çünkü ikisi FARKLI şeyler ölçer: ışığı tanımak ile o ışıkta ne yapılacağını
/// bilmek aynı bilgi değildir (kırmızı ikazda sürüşe devam etmek, ışığı doğru tanıyan biri için
/// de yapılabilecek bir hatadır).
List<Question> buildDashQuestions(List<DashLight> lights, Rng rng) {
  final out = <Question>[];
  final allMeanings = [for (final l in lights) l.meaning];
  for (final light in lights) {
    // Varlığı olmayan ikaz için soru üretilmez (kırık görselli soru yerine hiç soru).
    if (dashAsset(light.id) == null) continue;

    final sameSeverity = [
      for (final l in lights)
        if (l.severity == light.severity && l.id != light.id) l.meaning,
    ];
    final meaning = _question(
      id: 'vq-dash-${light.id}',
      subject: Subject.motor,
      topic: 'Gösterge Paneli',
      difficulty: Difficulty.orta,
      stem: 'Gösterge panelinde yanan bu ikaz ışığı ne anlama gelir?',
      correct: light.meaning,
      pool: sameSeverity,
      fallback: allMeanings,
      explanation: '${light.name}: ${light.meaning} ${light.tip}',
      objective: 'Gösterge panelindeki ikaz ışığını tanır ve anlamını açıklar.',
      kind: QuestionKind.dashboard,
      assetId: light.id,
      alt: '${light.name} ikaz ışığı',
      rng: rng,
    );
    if (meaning != null) out.add(meaning);

    // Eylem sorusu — şıklar üç önem düzeyinin etiketleri arasından; doğru cevap ışığın düzeyidir.
    final action = _question(
      id: 'vq-dash-${light.id}-eylem',
      subject: Subject.motor,
      topic: 'Gösterge Paneli',
      difficulty: Difficulty.zor,
      stem: 'Bu ikaz ışığı yandığında sürücünün yapması gereken nedir?',
      correct: light.severity.label,
      pool: [
        for (final s in DashSeverity.values)
          if (s != light.severity) s.label,
      ],
      fallback: const ['Bir sonraki bakımda kontrol ettir'],
      explanation: '${light.name} — ${light.severity.label}. ${light.tip}',
      objective: 'İkaz ışığının gerektirdiği eylem düzeyini belirler.',
      kind: QuestionKind.dashboard,
      assetId: light.id,
      alt: '${light.name} ikaz ışığı',
      rng: rng,
    );
    if (action != null) out.add(action);
  }
  return out;
}

/// Mekanik / kabin parçası soruları — "bu parça nedir?" + "görevi nedir?".
List<Question> buildPartQuestions(List<VehiclePart> parts, Rng rng) {
  final out = <Question>[];
  final allNames = [for (final p in parts) p.name];
  final allDescs = [for (final p in parts) p.desc];
  for (final part in parts) {
    if (mechAsset(part.id) == null) continue;

    final sameSystemNames = [
      for (final p in parts)
        if (p.system == part.system && p.id != part.id) p.name,
    ];
    final naming = _question(
      id: 'vq-part-${part.id}',
      subject: Subject.motor,
      topic: 'Araç Tekniği',
      difficulty: Difficulty.kolay,
      stem: 'Görseldeki parçanın adı nedir?',
      correct: part.name,
      pool: sameSystemNames,
      fallback: allNames,
      explanation: '${part.name}: ${part.desc}',
      objective: 'Araç parçasını görselinden tanır.',
      kind: QuestionKind.mechanic,
      assetId: part.id,
      alt: '${part.name} görseli',
      rng: rng,
    );
    if (naming != null) out.add(naming);

    final sameSystemDescs = [
      for (final p in parts)
        if (p.system == part.system && p.id != part.id) p.desc,
    ];
    final purpose = _question(
      id: 'vq-part-${part.id}-gorev',
      subject: Subject.motor,
      topic: 'Araç Tekniği',
      difficulty: Difficulty.orta,
      stem: 'Görseldeki parçanın görevi nedir?',
      correct: part.desc,
      pool: sameSystemDescs,
      fallback: allDescs,
      explanation: '${part.name}: ${part.desc} ${part.tip}',
      objective: 'Araç parçasının işlevini açıklar.',
      kind: QuestionKind.mechanic,
      assetId: part.id,
      alt: '${part.name} görseli',
      rng: rng,
    );
    if (purpose != null) out.add(purpose);

    // ÜÇÜNCÜ AÇI — "hangi sistemde bulunur?".
    //
    // Parçayı tanımak ile aracın neresinde arayacağını bilmek farklı şeylerdir. Sınavda
    // "kaput altında ne var" tipi sorular bu ayrımı ölçer; uygulamada da Öğren ▸ Araç
    // bölümü parçaları bu sistemlere göre gruplayarak gösteriyor.
    final system = _question(
      id: 'vq-part-${part.id}-sistem',
      subject: Subject.motor,
      topic: 'Araç Tekniği',
      difficulty: Difficulty.kolay,
      stem: 'Görseldeki parça aracın hangi bölümünde bulunur?',
      correct: part.system.label,
      pool: [
        for (final s in VehicleSystem.values)
          if (s != part.system) s.label,
      ],
      fallback: const [],
      explanation:
          '${part.name}, "${part.system.label}" bölümünde bulunur. ${part.tip}',
      objective: 'Araç parçasının hangi sistemde/bölümde bulunduğunu belirler.',
      kind: QuestionKind.mechanic,
      assetId: part.id,
      alt: '${part.name} görseli',
      rng: rng,
    );
    if (system != null) out.add(system);
  }
  return out;
}

/// Bütün görsel soruları tek çağrıda üret.
///
/// Kimlik çakışması OLAMAZ: her kimlik `vq-<tür>-<katalog kimliği>` biçiminde ve kataloglar
/// kendi içinde tekil. Yine de banka ile birleştirirken çakışma denetimi yapılır
/// (`mergeVisualQuestions`).
List<Question> buildVisualQuestions({
  List<TrafficSign> signs = const [],
  List<DashLight> lights = kDashLights,
  List<VehiclePart> parts = const [],
  required Rng rng,
}) => [
  ...buildSignQuestions(signs, rng),
  ...buildDashQuestions(lights, rng),
  ...buildPartQuestions(parts, rng),
];

/// Yazılmış banka + üretilmiş görsel sorular.
///
/// Yazılmış soru HER ZAMAN kazanır: aynı kimlikte bir üretim varsa atılır. Üreteç insan
/// yazımının üstüne yazmamalı.
List<Question> mergeVisualQuestions(List<Question> authored, List<Question> visual) {
  final ids = {for (final q in authored) q.id};
  return [
    ...authored,
    ...visual.where((q) => ids.add(q.id)),
  ];
}

/// Görsel üretimin sabit tohumu.
///
/// Sabit olması ŞART: kullanıcı bir sınavı yarıda bırakıp döndüğünde ya da uygulamayı yeniden
/// açtığında aynı soru aynı şıklarla gelmeli. Rastgele tohum, aynı sorunun her açılışta farklı
/// şık sırasıyla çıkması demekti — ilerleme kaydı (`questionId`) ile tutarsız olurdu.
const int kVisualSeed = 20260801;
