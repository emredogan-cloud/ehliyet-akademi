import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/practice/progress_repository.dart';
import '../../data/premium/entitlements_repository.dart';
import '../../data/premium/quota_repository.dart';
import '../../design/markdown_block.dart';
import '../../design/primitives.dart';
import '../../domain/coach/coach_controller.dart';
import '../../domain/coach/nudge.dart';
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

  @override
  void dispose() {
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
      _showQuotaDialog();
      return;
    }
    _input.clear();
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
    });
  }

  void _showQuotaDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günlük AI hakkın doldu'),
        content: const Text(
          'Bugünkü ücretsiz AI Koç sorularını kullandın. Sınırsız sormak için Komple B paketine geç.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/premium?product=komple-b');
            },
            child: const Text('Premium'),
          ),
        ],
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s4,
                        AppSpacing.s4,
                        AppSpacing.s4,
                        AppSpacing.s4,
                      ),
                      itemCount: chat.messages.length + (chat.sending ? 1 : 0),
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
    final nudges = _nudges();
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s4),
      children: [
        const AppPageHeader(
          title: 'AI Koç',
          emoji: '🤖',
          subtitle:
              'İlerlemeni izleyen, sana özel öneren proaktif bir koç. Ehliyet ve trafik konularında da soru sorabilirsin.',
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
          text:
              'AI yanıtları platform içeriğine dayanır; kesin ve güncel kural için MEB/MTSK esastır.',
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
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              onPressed: sending ? null : () => _send(_input.text),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              // a11y: icon-only button gets a label
              child: Semantics(
                label: 'Gönder',
                button: true,
                child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
            ),
          ),
        ],
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s3),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
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
                children: [
                  Icon(
                    message.grounded ? Icons.verified_rounded : Icons.smart_toy_outlined,
                    size: 13,
                    color: message.grounded ? p.green : p.text3,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    message.grounded ? 'İçeriğe dayalı' : 'AI',
                    style: TextStyle(
                      color: message.grounded ? p.green : p.text3,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s3),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
            ),
            const SizedBox(width: AppSpacing.s2),
            Text('Koç düşünüyor…', style: TextStyle(color: p.text3, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
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
