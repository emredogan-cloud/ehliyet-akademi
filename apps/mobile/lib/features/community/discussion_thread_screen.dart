import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../data/community/social_repository.dart';
import '../../data/practice/question_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/social_models.dart';
import '../../domain/practice/question.dart';
import '../../domain/practice/question_bank.dart';
import 'report_sheet.dart';

/// Evolution Faz E9 — bir tartışma başlığı ve iletileri.
///
/// SORU PAYLAŞIMI (referansla) BURADA KANITLANIR: sunucu yalnız `questionRef` (ör. `trafik-101`)
/// gönderir. Soru metni, seçenekleri ve doğru cevabı **istemcinin kendi yerel bankasından** çözülür.
/// Yani banka bir tartışma akışına kopyalanmaz; referans çözülemezse soru kutusu hiç çizilmez.
class DiscussionThreadScreen extends ConsumerStatefulWidget {
  const DiscussionThreadScreen({super.key, required this.threadId});
  final String threadId;

  @override
  ConsumerState<DiscussionThreadScreen> createState() => _DiscussionThreadScreenState();
}

class _DiscussionThreadScreenState extends ConsumerState<DiscussionThreadScreen> {
  final _input = TextEditingController();
  Future<DiscussionDetail?>? _future;
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
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(socialApiProvider).fetchDiscussion(widget.threadId);
    unawaited(future.catchError((Object _) => null));
    setState(() {
      _future = future;
    });
  }

  /// Referansı YEREL bankadan çözer. Sunucudan soru metni GELMEZ.
  ///
  /// Banka `watch` ile alınır (read DEĞİL): `FutureProvider` ancak dinlendiğinde yüklenir ve
  /// yüklendiğinde ekran kendini yeniden çizer — aksi hâlde soru hep "hazır değil" görünürdü.
  Question? _resolveQuestion(String? reference, QuestionBank? bank) {
    if (reference == null || bank == null) return null;
    for (final q in bank.questions) {
      if (q.id == reference) return q;
    }
    return null;
  }

  Future<void> _post() async {
    final error = validatePostBody(_input.text);
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
          .addPost(threadId: widget.threadId, body: _input.text.trim());
      _input.clear();
      _reload();
    } on CommunityException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'İleti gönderilemedi. Bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bank = ref.watch(questionBankProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartışma'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<DiscussionDetail?>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final detail = snap.data;
            if (detail == null) {
              // 404 = yok / engelli — ayrım SIZDIRILMAZ.
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s4),
                child: AppEmptyState(
                  emoji: '🔒',
                  title: 'Başlık görüntülenemiyor',
                  subtitle: 'Bu başlık kaldırılmış veya erişilebilir değil.',
                ),
              );
            }
            final question = _resolveQuestion(detail.thread.questionRef, bank);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s3,
                      AppSpacing.s4,
                      AppSpacing.s3,
                    ),
                    children: [
                      Text(
                        detail.thread.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        '${detail.thread.authorName} · ${detail.thread.licence.toUpperCase()} sınıfı',
                        style: TextStyle(color: p.text3, fontSize: 12.5),
                      ),
                      if (detail.thread.questionRef != null) ...[
                        const SizedBox(height: AppSpacing.s3),
                        _SharedQuestion(reference: detail.thread.questionRef!, question: question),
                      ],
                      const SizedBox(height: AppSpacing.s4),
                      if (detail.posts.isEmpty)
                        const AppEmptyState(
                          emoji: '💬',
                          title: 'Henüz ileti yok',
                          subtitle: 'İlk yorumu sen yaz.',
                        )
                      else
                        for (final post in detail.posts) ...[
                          _PostCard(post: post, onReport: post.mine ? null : () => _report(post)),
                          const SizedBox(height: AppSpacing.s2),
                        ],
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      0,
                      AppSpacing.s4,
                      AppSpacing.s2,
                    ),
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
                          maxLength: kPostMaxLength,
                          maxLines: 4,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Görüşünü yaz…',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Semantics(
                        label: 'İleti gönder',
                        button: true,
                        child: IconButton.filled(
                          onPressed: _sending ? null : _post,
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _report(DiscussionPost post) async {
    final reason = await pickReportReason(context);
    if (reason == null) return;
    try {
      await ref.read(socialApiProvider).reportContent(
        userId: post.authorId,
        reason: reason,
        targetType: 'post',
        targetRef: post.id,
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

/// Paylaşılan soru — METİN SUNUCUDAN GELMEZ, yerel bankadan çözülür.
class _SharedQuestion extends StatelessWidget {
  const _SharedQuestion({required this.reference, required this.question});
  final String reference;
  final Question? question;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (question == null) {
      // Referans yerelde çözülemedi (banka indirilmemiş olabilir) — dürüst durum.
      return AppCallout(
        tone: CalloutTone.info,
        title: 'Paylaşılan soru',
        text:
            'Bu başlıkta bir soru paylaşılmış (`$reference`) ama soru bankası henüz cihazında hazır değil. Pratik bölümünü bir kez açtıktan sonra burada görünecek.',
      );
    }
    final q = question!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, size: 16, color: p.blue),
              const SizedBox(width: 6),
              Text(
                'Paylaşılan soru',
                style: TextStyle(color: p.blue, fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(q.stem, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.35)),
          const SizedBox(height: AppSpacing.s2),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${String.fromCharCode(65 + i)}) ${q.options[i]}',
                style: TextStyle(color: p.text2, fontSize: 13, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onReport});
  final DiscussionPost post;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlowCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: MascotImage(post.authorAvatar.asset, height: 36, semanticLabel: post.authorName),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.text2),
                ),
                const SizedBox(height: 3),
                Text(post.body, style: const TextStyle(fontSize: 13.5, height: 1.35)),
              ],
            ),
          ),
          if (onReport != null)
            IconButton(
              tooltip: 'Bildir',
              onPressed: onReport,
              icon: Icon(Icons.flag_outlined, size: 18, color: p.text3),
            ),
        ],
      ),
    );
  }
}
