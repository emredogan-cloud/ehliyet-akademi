import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/enriched_bank.dart';
import '../../data/duel/duel_energy_repository.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../design/primitives.dart';
import '../../domain/duel/duel.dart';
import '../../domain/duel/duel_energy.dart';
import '../../domain/practice/question.dart';
import '../../domain/premium/products.dart';
import '../practice/widgets/question_media_view.dart';

/// Ürün Evrimi v1.1 · Faz 4 — Düello ekranı.
///
/// Akış: rakip aranıyor → rakip bulundu → soru soru düello → sonuç.
///
/// Arama animasyonu SAHTE DEĞİL: yerel rakip anında hazır olsa da 3 saniye bekleniyor, çünkü
/// bu süre "rakip bulundu" anını bir olaya dönüştürüyor. Ama ekranda "12.483 oyuncu aranıyor"
/// gibi uydurma bir sayı YAZMIYOR — bekleme dürüst, sayı uydurulmuyor.
enum _Phase { searching, found, playing, done }

class DuelScreen extends ConsumerStatefulWidget {
  const DuelScreen({super.key});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  static const _searchDuration = Duration(seconds: 3);

  _Phase _phase = _Phase.searching;
  late final DuelConfig _config;
  late final AiOpponent _opponent;
  List<Question> _questions = const [];
  final _playerAnswers = <DuelAnswer>[];
  final _opponentAnswers = <DuelAnswer>[];
  int _index = 0;
  int _msLeft = 0;
  Timer? _ticker;

  /// Arama gecikmesi. `Future.delayed` DEĞİL: sökülünce iptal edilemez ve testte "bekleyen
  /// zamanlayıcı" hatası bırakır — beta taşma taraması bunu yakaladı.
  Timer? _searchTimer;

  DuelResult? _result;

  @override
  void initState() {
    super.initState();
    // Tohum: bu oturuma özgü. Test edilebilirlik için sabit değil ama düello içinde sabit —
    // aynı düelloda rakip davranışı tutarlı kalır.
    final seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    _config = DuelConfig(seed: seed);
    _opponent = AiOpponent(level: 5, seed: seed);
    _searchTimer = Timer(_searchDuration, () {
      if (mounted) setState(() => _phase = _Phase.found);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _start(List<Question> bank) async {
    _questions = buildDuelQuestions(bank, _config);
    if (_questions.isEmpty) return;
    // ENERJİ BAŞLANGIÇTA harcanır: yarıda bırakarak bedava düello elde etmek mümkün olmasın.
    await ref.read(duelEnergyProvider.notifier).spend(DateTime.now());
    if (!mounted) return;
    setState(() {
      _phase = _Phase.playing;
      _index = 0;
    });
    _beginQuestion();
  }

  void _beginQuestion() {
    _ticker?.cancel();
    _msLeft = _config.millisPerQuestion;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _msLeft -= 100);
      // Süre dolduysa cevapsız sayılır — soru atlanmaz, puanı sıfır olur.
      if (_msLeft <= 0) _answer(null);
    });
  }

  Future<void> _answer(int? choice) async {
    _ticker?.cancel();
    final q = _questions[_index];
    _playerAnswers.add(
      DuelAnswer(choice: choice, elapsedMs: _config.millisPerQuestion - _msLeft.clamp(0, _config.millisPerQuestion)),
    );
    _opponentAnswers.add(await _opponent.answerFor(q, _index));
    if (!mounted) return;

    if (_index + 1 >= _questions.length) {
      // Bekleme sayacı BİTİŞTE başlar — art arda düello açıp kapatmayı engeller.
      await ref.read(duelEnergyProvider.notifier).finish(DateTime.now());
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _result = scoreDuel(
          questions: _questions,
          player: _playerAnswers,
          opponent: _opponentAnswers,
          config: _config,
        );
      });
      return;
    }
    setState(() => _index++);
    _beginQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final premium = isPremium(ref.watch(entitlementsProvider));
    final bank = ref.watch(enrichedBankProvider).value;
    final energy = ref.watch(duelEnergyProvider);
    final now = DateTime.now();
    final block = duelBlockReason(energy, now, premium: premium);
    final left = remainingDuels(energy, now, premium: premium);

    return Scaffold(
      appBar: AppBar(title: const Text('Düello')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: switch (_phase) {
            _Phase.searching => _Searching(palette: p),
            _Phase.found => _Found(
              opponent: _opponent,
              remaining: left,
              block: block,
              cooldown: cooldownLeft(energy, now),
              ready: bank != null,
              onStart: bank == null || block != null ? null : () => _start(bank.questions),
            ),
            _Phase.playing => _Playing(
              question: _questions[_index],
              index: _index,
              total: _questions.length,
              msLeft: _msLeft,
              totalMs: _config.millisPerQuestion,
              onAnswer: _answer,
            ),
            _Phase.done => _Done(result: _result!, opponent: _opponent),
          },
        ),
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.s5),
        const Text(
          'Rakip aranıyor…',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.s2),
        // Uydurma sayı YOK. "Çevrimiçi 12.483 kişi" yazmak, çevrimiçi eşleşme olmadığı hâlde
        // varmış gibi göstermek olurdu.
        Text(
          'Seviyene uygun bir rakip hazırlanıyor',
          style: TextStyle(color: palette.text3, fontSize: 13),
        ),
      ],
    ),
  );
}

class _Found extends StatelessWidget {
  const _Found({
    required this.opponent,
    required this.remaining,
    required this.block,
    required this.cooldown,
    required this.ready,
    required this.onStart,
  });

  final AiOpponent opponent;
  final int remaining;
  final DuelBlock? block;
  final Duration cooldown;
  final bool ready;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_kabaddi_rounded, size: 64, color: p.primary),
          const SizedBox(height: AppSpacing.s4),
          const Text(
            'Rakip bulundu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '${opponent.name} · Seviye ${opponent.level}',
            style: TextStyle(color: p.text2, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Bugün kalan düello: $remaining',
            style: TextStyle(color: p.text3, fontSize: 12.5),
          ),
          const SizedBox(height: AppSpacing.s5),
          if (block == DuelBlock.dailyLimit)
            AppCallout(
              tone: CalloutTone.info,
              title: 'Bugünlük bu kadar',
              text:
                  'Günlük düello hakkın doldu. Yarın yenilenir; premium ile günlük hak '
                  'daha yüksektir.',
            )
          else if (block == DuelBlock.cooldown)
            AppCallout(
              tone: CalloutTone.info,
              title: 'Kısa bir mola',
              text:
                  'Yeni düello için ${cooldown.inSeconds + 1} saniye. Art arda düello açmayı '
                  'engelleyen kısa bir bekleme.',
            )
          else
            FilledButton(
              onPressed: ready ? onStart : null,
              child: Text(ready ? 'Başla' : 'Sorular hazırlanıyor…'),
            ),
        ],
      ),
    );
  }
}

class _Playing extends StatelessWidget {
  const _Playing({
    required this.question,
    required this.index,
    required this.total,
    required this.msLeft,
    required this.totalMs,
    required this.onAnswer,
  });

  final Question question;
  final int index;
  final int total;
  final int msLeft;
  final int totalMs;
  final ValueChanged<int?> onAnswer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = (msLeft / totalMs).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${index + 1} / $total', style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              '${(msLeft / 1000).ceil().clamp(0, 99)} sn',
              style: TextStyle(
                // Son beş saniyede renk uyarıya döner.
                color: ratio < 0.25 ? p.red : p.text2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            color: ratio < 0.25 ? p.red : p.primary,
            backgroundColor: p.surface3,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (question.media != null) ...[
                  QuestionMediaView(question: question),
                  const SizedBox(height: AppSpacing.s3),
                ],
                Text(
                  question.stem,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.s4),
                for (var i = 0; i < question.options.length; i++) ...[
                  OutlinedButton(
                    onPressed: () => onAnswer(i),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(question.options[i]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.result, required this.opponent});
  final DuelResult result;
  final AiOpponent opponent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = result.won ? p.green : (result.drew ? p.text2 : p.red);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            result.label,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '${result.playerScore}  —  ${result.opponentScore}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Sen ${result.playerCorrect}/${result.total} · '
            '${opponent.name} ${result.opponentCorrect}/${result.total}',
            style: TextStyle(color: p.text3, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppCallout(
            tone: CalloutTone.info,
            title: '+${result.xp} XP',
            text: result.won
                ? 'Doğrularının XP\'si ve galibiyet bonusu eklendi.'
                : 'Kaybetsen de doğruların XP kazandırır — çalışmanın karşılığı verilir.',
          ),
          const SizedBox(height: AppSpacing.s5),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }
}
