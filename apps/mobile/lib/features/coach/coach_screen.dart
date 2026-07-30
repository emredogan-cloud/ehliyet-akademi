import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics.dart';
import '../../core/analytics/analytics_event.dart';
import '../../core/assets.dart';
import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../data/premium/quota_repository.dart';
import '../../design/brand.dart';
import '../../design/markdown_block.dart';
import '../../design/primitives.dart';
import '../../domain/coach/coach_controller.dart';
import '../../domain/coach/nudge.dart';
import '../../domain/premium/premium_prompt.dart';
import '../../domain/feedback/rating_prompt.dart';
import '../feedback/rating_dialog.dart';
import '../premium/premium_popups.dart';
import 'widgets/nudge_card.dart';

/// AI Koç — proaktif deterministik dürtme kartları + grounded sohbet (`/api/ai/ask`).
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'Kırmızı ışıkta sağa dönülür mü?',
    'İlk yardımda ABC nedir?',
    'Kavşakta geçiş önceliği kimindir?',
    'Takograf ne işe yarar?',
  ];

  /// Beta Faz 3 — AI Koç oturumunun başladığı an ve kaç tur konuşulduğu.
  ///
  /// NEDEN sekme kabuğunda ölçüm burada: AI Koç bir SEKME. Sekme değişimi rota İTMEZ
  /// (`StatefulShellRoute.indexedStack` yalnız gösterilen dalı değiştirir), dolayısıyla bir
  /// gezinme gözlemcisi bu ekranın açıldığını göremez. Ekranın kendi yaşam döngüsü tek güvenilir
  /// kaynaktır.
  ///
  /// Sekme kabuğu dalları CANLI TUTULUR: kullanıcı başka sekmeye geçip döndüğünde `initState`
  /// tekrar çalışmaz. Yani bu ölçüm "uygulama açılışından beri AI Koç'ta geçen süre"dir; her
  /// sekme ziyaretini ayrı oturum saymaz. Sayılsaydı sekmeye şöyle bir uğrayan kullanıcı da
  /// "oturum" üretirdi ve ortalama süre anlamsızlaşırdı.
  DateTime? _sessionStartedAt;
  int _turns = 0;

  /// Analitik örneği `initState`'te YAKALANIR — `dispose` içinde `ref` KULLANILAMAZ.
  ///
  /// Riverpod, sökülmekte olan bir widget'ta `ref.read` çağrısını açıkça yasaklar: `Ref`
  /// `BuildContext`'e dayanır ve o bağlam artık geçersizdir. İlk yazımda bu kural gözden kaçtı ve
  /// widget testleri **"Bad state: Using ref when a widget is about to or has been unmounted"**
  /// diye patladı — yani hata cihaza gitmeden yakalandı, ama gitseydi AI Koç ekranı her
  /// sökülüşünde istisna fırlatacaktı.
  late final Analytics _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsProvider);
    _sessionStartedAt = DateTime.now();
    _analytics.log(AnalyticsEvent.aiCoachStarted).ignore();
  }

  @override
  void dispose() {
    final startedAt = _sessionStartedAt;
    // Hiç soru sorulmadıysa oturum uzunluğu GÖNDERİLMEZ: ekrana bakıp çıkmak bir koçluk oturumu
    // değildir ve ortalamayı sıfıra çeker.
    if (startedAt != null && _turns > 0) {
      _analytics
          .log(
            AnalyticsEvent.aiCoachSessionLength(
              seconds: DateTime.now().difference(startedAt).inSeconds,
              turns: _turns,
            ),
          )
          .ignore();
    }
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final q = text.trim();
    if (q.length < 3) return;
    final owned = ref.read(entitlementsProvider);
    final quota = ref.read(quotaRepositoryProvider).value;
    if (quota != null && !quota.canAskAi(owned)) {
      // Ücretsiz AI kotası doldu → bağlamsal premium teşviki.
      showPremiumIncentive(context, trigger: PremiumTrigger.aiQuota);
      return;
    }
    _input.clear();
    _turns++;
    ref.read(coachChatProvider.notifier).send(q);
    quota?.consumeAi(owned);
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 240,
          duration: AppMotion.base,
          curve: AppMotion.easeOut,
        );
      }
      _maybeAskForRating();
    });
  }

  /// Faz 7 — UZUN sohbet, puanlama sormak için iyi bir andır: kullanıcı tek soru sorup çıkmamış,
  /// ürünü gerçekten kullanmıştır.
  ///
  /// Eşiğe TAM ULAŞILDIĞINDA tetiklenir (her mesajda değil); ayrıca `maybeShowRatingPrompt` kendi
  /// sıklık sınırlarını uygular. Yanıt beklenmez — pencere sohbetin akışını kesmemeli.
  void _maybeAskForRating() {
    final count = ref.read(coachChatProvider).messages.length;
    if (!ratingTriggeredByCoach(count)) return;
    if (!mounted) return;
    unawaited(
      maybeShowRatingPrompt(
        context,
        ref,
        RatingTrigger.coachConversation,
        nowMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  List<Nudge> _nudges() {
    final progress = ref.watch(progressRepositoryProvider).value;
    if (progress == null) return const [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final answers = progress.loadAnswers();
    final cards = progress.loadCards();
    final due = cards.values.where((c) => c.dueAt <= now).length;
    return computeNudges(
      readiness: answers.isNotEmpty ? progress.readiness() : null,
      streak: progress.loadStreak(),
      dueCount: due,
      answered: answers.length,
      nowMs: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chat = ref.watch(coachChatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Koç'),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: 'Sohbeti temizle',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => ref.read(coachChatProvider.notifier).clear(),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? _intro()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s4),
                      // Beta Faz 9: "Koç düşünüyor…" balonu yalnız HENÜZ İÇERİK YOKKEN durur.
                      // Akış başladıktan sonra büyüyen yanıtın kendisi zaten göstergedir; ikisi
                      // birden çizilirse kullanıcı iki ayrı yanıt bekliyormuş gibi görür.
                      itemCount: chat.messages.length + (_awaiting(chat) ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= chat.messages.length) return const _TypingBubble();
                        return _MessageBubble(message: chat.messages[i]);
                      },
                    ),
            ),
            if (chat.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 4),
                child: Text(chat.error!, style: TextStyle(color: p.red, fontSize: 12.5)),
              ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    final p = context.palette;
    final nudges = _nudges();
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s4),
      children: [
        // AI Koç tanıtım kartı — owl maskotu
        GlowCard(
          selected: true,
          padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, 0, AppSpacing.s4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(icon: Icons.auto_awesome_rounded, color: p.primary, size: 40),
                        const SizedBox(width: AppSpacing.s3),
                        Text('AI Koç', style: TextStyle(color: p.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      'İlerlemeni izleyen, sana özel öneren proaktif bir koç. Ehliyet ve trafik konularında da soru sorabilirsin.',
                      style: TextStyle(color: p.text2, height: 1.4, fontSize: 13),
                    ),
                  ],
                ),
              ),
              MascotImage(AppImages.owlWave, height: 128, semanticLabel: 'AI Koç'),
            ],
          ),
        ),
        if (nudges.isNotEmpty) ...[
          const SectionTitle('Senin için'),
          for (final n in nudges.take(3)) ...[
            NudgeCard(nudge: n, onTap: () => context.push(n.action)),
            const SizedBox(height: AppSpacing.s3),
          ],
        ],
        const SectionTitle('Bir şey sor'),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [for (final s in _suggestions) _SuggestionChip(text: s, onTap: () => _send(s))],
        ),
        const SizedBox(height: AppSpacing.s4),
        const AppCallout(
          tone: CalloutTone.info,
          title: 'Güvenilir bilgi',
          text: 'AI yanıtları platform içeriğine dayanır; kesin ve güncel kural için MEB/MTSK esastır.',
        ),
      ],
    );
  }

  Widget _inputBar() {
    final p = context.palette;
    final sending = ref.watch(coachChatProvider).sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s3, AppSpacing.s3),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              decoration: const InputDecoration(hintText: 'Ehliyet/trafik hakkında sor…'),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          _SendButton(sending: sending, onTap: sending ? null : () => _send(_input.text)),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onTap});
  final bool sending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Gönder',
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 30,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [p.primary, p.primaryBright]),
            boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: -2)],
          ),
          alignment: Alignment.center,
          child: sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _OwlAvatar extends StatelessWidget {
  const _OwlAvatar();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.primary.withValues(alpha: 0.14),
        border: Border.all(color: p.primary.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        maxWidth: 46,
        maxHeight: 46,
        child: Align(
          alignment: const Alignment(0, -0.55),
          child: MascotImage(AppImages.owlWave, height: 44, semanticLabel: ''),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isUser = message.role == 'user';
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: isUser ? p.primary : p.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadii.base),
          topRight: const Radius.circular(AppRadii.base),
          bottomLeft: Radius.circular(isUser ? AppRadii.base : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppRadii.base),
        ),
        border: isUser ? null : Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUser)
            Text(
              message.text,
              style: TextStyle(
                color: p.brightness == Brightness.dark ? const Color(0xFF04211F) : Colors.white,
                height: 1.4,
                fontSize: 14.5,
              ),
            )
          else
            MarkdownBlock(message.text, baseColor: p.text, baseSize: 14.5),
          if (!isUser && (message.grounded || message.sources.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.s2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(message.grounded ? Icons.verified_rounded : Icons.smart_toy_outlined,
                    size: 13, color: message.grounded ? p.green : p.text3),
                const SizedBox(width: 4),
                Text(message.grounded ? 'İçeriğe dayalı' : 'AI',
                    style: TextStyle(color: message.grounded ? p.green : p.text3, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[const _OwlAvatar(), const SizedBox(width: AppSpacing.s2)],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OwlAvatar(),
          const SizedBox(width: AppSpacing.s2),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadii.base),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.primary)),
                const SizedBox(width: AppSpacing.s2),
                Text('Koç düşünüyor…', style: TextStyle(color: p.text3, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Henüz tek bir parça bile gelmedi mi? (Akış başladıysa son mesaj artık AI'dır.)
bool _awaiting(CoachChatState chat) =>
    chat.sending && (chat.messages.isEmpty || chat.messages.last.role == 'user');

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          // Faz 12 — dokunma hedefi EN AZ 48 dp (Android erişilebilirlik yönergesi).
          //
          // Çip 35 dp yükseklikteydi; Play erişilebilirlik taraması bunu işaretler ve motor
          // becerisi kısıtlı kullanıcılar için isabet zorlaşır. Görsel yükseklik dolgu ile
          // korunuyor — çip aynı görünür, hedefi büyür.
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: p.border),
          ),
          child: Text(text, style: TextStyle(color: p.text2, fontSize: 12.5)),
        ),
      ),
    );
  }
}
