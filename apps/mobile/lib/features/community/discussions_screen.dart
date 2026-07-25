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
import '../../domain/onboarding/study_profile.dart';

/// Evolution Faz E9 — tartışma başlıkları (ehliyet sınıfına göre).
class DiscussionsScreen extends ConsumerStatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  ConsumerState<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends ConsumerState<DiscussionsScreen> {
  String? _licence;
  Future<List<DiscussionSummary>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _licence = ref.read(studyProfileProvider).category.wire;
      _reload();
    });
  }

  void _reload() {
    if (!mounted) return;
    final future = ref.read(socialApiProvider).fetchDiscussions(licence: _licence);
    unawaited(future.catchError((Object _) => <DiscussionSummary>[]));
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tartışmalar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createThread,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni başlık'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                AppSpacing.s2,
                AppSpacing.s4,
                AppSpacing.s2,
              ),
              child: Row(
                children: [
                  for (final entry in <(String?, String)>[
                    (null, 'Tümü'),
                    ('b', 'B'),
                    ('a', 'A'),
                    ('d', 'D'),
                  ]) ...[
                    _Chip(
                      label: entry.$2,
                      selected: _licence == entry.$1,
                      onTap: () {
                        _licence = entry.$1;
                        _reload();
                      },
                    ),
                    const SizedBox(width: AppSpacing.s2),
                  ],
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<DiscussionSummary>>(
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
                        title: 'Tartışmalar alınamadı',
                        subtitle: 'Topluluk internet gerektirir. Bağlantını kontrol et.',
                        action: FilledButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Tekrar dene'),
                        ),
                      ),
                    );
                  }
                  final threads = snap.data ?? const <DiscussionSummary>[];
                  if (threads.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.s4),
                      child: AppEmptyState(
                        emoji: '💡',
                        title: 'Henüz başlık yok',
                        subtitle: 'İlk başlığı sen aç — takıldığın bir soruyu paylaşabilirsin.',
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4,
                      AppSpacing.s2,
                      AppSpacing.s4,
                      AppSpacing.s12,
                    ),
                    itemCount: threads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
                    itemBuilder: (context, i) {
                      final t = threads[i];
                      return GlowCard(
                        onTap: () async {
                          await context.push('/profile/community/discussions/${t.id}');
                          _reload();
                        },
                        padding: const EdgeInsets.all(AppSpacing.s3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: MascotImage(
                                t.authorAvatar.asset,
                                height: 40,
                                semanticLabel: t.authorName,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '${t.authorName} · ${t.licence.toUpperCase()}',
                                        style: TextStyle(color: p.text3, fontSize: 12),
                                      ),
                                      if (t.questionRef != null) ...[
                                        const SizedBox(width: AppSpacing.s2),
                                        Icon(Icons.quiz_rounded, size: 13, color: p.blue),
                                        const SizedBox(width: 3),
                                        Text(
                                          'soru',
                                          style: TextStyle(color: p.blue, fontSize: 11.5),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s2),
                            Column(
                              children: [
                                Text(
                                  '${t.postCount}',
                                  style: TextStyle(
                                    color: p.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                Text('ileti', style: TextStyle(color: p.text3, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createThread() async {
    final licence = ref.read(studyProfileProvider).category.wire;
    final title = await showNewThreadSheet(context);
    if (title == null) return;
    try {
      await ref
          .read(socialApiProvider)
          .createDiscussion(title: title, licence: _licence ?? licence);
      _reload();
    } on CommunityException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Başlık açılamadı. Bağlantını kontrol et.')));
    }
  }
}

/// Yeni başlık için ad soran alt sayfa (paylaşımlı — soru paylaşımı akışı da kullanır).
Future<String?> showNewThreadSheet(BuildContext context, {String? questionRef}) {
  final controller = TextEditingController();
  String? error;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  questionRef == null ? 'Yeni başlık' : 'Soruyu tartışmaya aç',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (questionRef != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  const AppCallout(
                    tone: CalloutTone.info,
                    text:
                        'Sorunun **metni paylaşılmaz** — yalnız soru referansı eklenir. Herkes soruyu kendi uygulamasından görür.',
                  ),
                ],
                const SizedBox(height: AppSpacing.s3),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: kThreadTitleMax,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Neyi tartışmak istiyorsun?',
                    errorText: error,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                GradientPillButton(
                  label: 'Aç',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    final e = validateThreadTitle(controller.text);
                    if (e != null) {
                      setSheetState(() => error = e);
                      return;
                    }
                    Navigator.pop(ctx, controller.text.trim());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.primary050 : p.surface2,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: selected ? p.primary : p.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? p.primary : p.text2,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
