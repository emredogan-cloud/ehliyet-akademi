import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../data/community/social_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/social_models.dart';
import 'report_sheet.dart';

/// Evolution Faz E9 — konuşma listesi.
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  Future<List<MessageThread>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(socialApiProvider).fetchThreads();
    unawaited(future.catchError((Object _) => <MessageThread>[]));
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<MessageThread>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '📡',
                  title: 'Mesajlar alınamadı',
                  subtitle: 'Mesajlaşma internet gerektirir. Bağlantını kontrol et.',
                  action: FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tekrar dene'),
                  ),
                ),
              );
            }
            final threads = snap.data ?? const <MessageThread>[];
            if (threads.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '💬',
                  title: 'Henüz mesaj yok',
                  subtitle: 'Yalnız arkadaşlarınla mesajlaşabilirsin. Arkadaşlar sekmesinden başla.',
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s3,
                AppSpacing.s4,
                AppSpacing.s10,
              ),
              itemCount: threads.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
              itemBuilder: (context, i) {
                final t = threads[i];
                return GlowCard(
                  onTap: () async {
                    await context.push('/profile/community/chat/${t.userId}');
                    _reload();
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s3,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: MascotImage(t.avatar.asset, height: 44, semanticLabel: t.displayName),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                            ),
                            Text(
                              t.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.text3, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      if (t.unread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Evolution Faz E9 — birebir konuşma.
///
/// Sunucu YALNIZ arkadaşlar arasında mesajlaşmaya izin verir; engel her iki yönde uygulanır.
/// İstemci bu kuralları taklit etmez, sunucunun cevabını dürüstçe gösterir.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Future<List<ChatMessage>>? _future;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(socialApiProvider).fetchConversation(widget.userId);
    unawaited(future.catchError((Object _) => <ChatMessage>[]));
    setState(() {
      _future = future;
    });
  }

  Future<void> _send() async {
    final error = validateMessageBody(_input.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(socialApiProvider)
          .sendMessage(userId: widget.userId, body: _input.text.trim());
      _input.clear();
      _reload();
    } on CommunityException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Mesaj gönderilemedi. Bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Profili aç',
            onPressed: () => context.push('/profile/community/user/${widget.userId}'),
            icon: const Icon(Icons.person_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<ChatMessage>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      child: AppEmptyState(
                        emoji: '🔒',
                        title: 'Konuşma açılamadı',
                        subtitle:
                            'Bu kişiyle mesajlaşamıyor olabilirsin (arkadaş değilsiniz veya erişim kapalı).',
                        action: FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Tekrar dene'),
                        ),
                      ),
                    );
                  }
                  final messages = snap.data ?? const <ChatMessage>[];
                  if (messages.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.s4),
                      child: AppEmptyState(
                        emoji: '💬',
                        title: 'Sohbeti başlat',
                        subtitle: 'İlk mesajı sen yaz.',
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s3,
                      AppSpacing.s4,
                      AppSpacing.s3,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(
                      message: messages[i],
                      onReport: messages[i].mine
                          ? null
                          : () => _reportMessage(messages[i]),
                    ),
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s2),
                child: AppCallout(tone: CalloutTone.danger, text: _error!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: kMessageMaxLength,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Semantics(
                    label: 'Gönder',
                    button: true,
                    child: IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(backgroundColor: p.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportMessage(ChatMessage m) async {
    final reason = await pickReportReason(context);
    if (reason == null) return;
    try {
      await ref.read(socialApiProvider).reportContent(
        userId: m.senderId,
        reason: reason,
        targetType: 'message',
        targetRef: m.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bildirimin alındı. İnceleyeceğiz.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bildirim gönderilemedi.')));
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onReport});
  final ChatMessage message;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = message.mine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onReport,
        child: Semantics(
          label: mine ? 'Senin mesajın: ${message.body}' : 'Gelen mesaj: ${message.body}',
          excludeSemantics: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
            decoration: BoxDecoration(
              color: mine ? p.primary050 : p.surface2,
              borderRadius: BorderRadius.circular(AppRadii.base),
              border: Border.all(color: mine ? p.primary.withValues(alpha: 0.35) : p.border),
            ),
            child: Text(
              message.body,
              style: TextStyle(color: p.text, fontSize: 14, height: 1.35),
            ),
          ),
        ),
      ),
    );
  }
}
