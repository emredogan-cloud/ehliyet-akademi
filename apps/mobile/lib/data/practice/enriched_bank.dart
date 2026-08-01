import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/practice/exam.dart' show seededRng;
import '../../domain/practice/question_bank.dart';
import '../../domain/practice/visual_questions.dart';
import '../content/content_repository.dart';
import 'question_repository.dart';

/// QIP v3 — pratik/sınav yüzeylerinin gördüğü BANKA: yazılmış sorular + üretilmiş görsel sorular.
///
/// ## Neden ayrı bir sağlayıcı
///
/// `questionBankProvider` sunucudan gelen yükün ta kendisidir; ona dokunmak, önbellek sürümü ve
/// ETag mantığını görsel üretimle karıştırmak olurdu. Bu sağlayıcı iki kaynağı **birleştirir** ve
/// pratik yüzeylerinin tek girişi olur (`PracticeContentBuilder`).
///
/// ## İçerik yoksa ne olur
///
/// İçerik anlık görüntüsü (işaretler, parçalar) henüz inmemişse **yalnız** yazılmış banka +
/// pakete gömülü ikaz ışığı soruları döner. Yani görsel sorular kademeli gelir; hiçbir durumda
/// hata üretmez ve sınav başlatmayı ENGELLEMEZ — bu, bankanın "sınav başlatmanın önündeki kapı"
/// olmasından ötürü bilinçli.
final enrichedBankProvider = FutureProvider<QuestionBank>((ref) async {
  final bank = await ref.watch(questionBankProvider.future);
  final content = ref.watch(contentSnapshotProvider).value;
  final visual = buildVisualQuestions(
    signs: content?.signs ?? const [],
    parts: content?.vehicleParts ?? const [],
    rng: seededRng(kVisualSeed),
  );
  final merged = mergeVisualQuestions(bank.questions, visual);
  return bank.copyWith(questions: merged, count: merged.length);
});
