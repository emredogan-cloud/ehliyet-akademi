import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../../design/brand.dart';
import '../../design/primitives.dart';
import '../../domain/community/community_models.dart';
import 'avatar_editor_screen.dart';
import 'widgets/community_avatar_view.dart';
import '../../domain/onboarding/study_profile.dart';

/// Evolution Faz E8 — topluluğa katılma / profili düzenleme.
///
/// GİZLİLİK TASARIMI (bu ekranın varlık sebebi):
/// - Katılım **açık rızaya** bağlıdır; hiçbir veri kullanıcı bu ekranı onaylamadan paylaşılmaz.
/// - Görünen ad gerçek ad OLMAK ZORUNDA DEĞİLDİR ve e-posta girilemez.
/// - Avatar, uygulamayla gelen maskotlardan seçilir — **fotoğraf yükleme yoktur**.
/// - "Sıralamada görün" kapalıyken profil kimseye görünmez; istediğin an topluluktan ayrılıp
///   verini silebilirsin.
class JoinCommunityScreen extends ConsumerStatefulWidget {
  const JoinCommunityScreen({super.key});

  @override
  ConsumerState<JoinCommunityScreen> createState() => _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends ConsumerState<JoinCommunityScreen> {
  final _name = TextEditingController();
  CommunityAvatar _avatar = CommunityAvatar.owlWave;
  /// Beta Faz 7 — yüklenmiş fotoğrafın URL'si. null → maskot kullanılır.
  String? _avatarUrl;
  bool _public = true;
  bool _seeded = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Beta Faz 7 — fotoğraf düzenleyiciyi aç.
  ///
  /// Dönüş: yeni URL (yüklendi) · `''` (kaldırıldı → maskota dönüldü) · `null` (vazgeçildi).
  Future<void> _editPhoto() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AvatarEditorScreen(hasPhoto: _avatarUrl != null),
      ),
    );
    if (!mounted || result == null) return; // vazgeçme hata değildir
    setState(() => _avatarUrl = result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final community = ref.watch(communityProvider);
    final licence = ref.watch(studyProfileProvider).category;

    // Mevcut profil varsa alanları bir kez doldur (düzenleme kipi).
    if (!_seeded && community.profile != null) {
      _seeded = true;
      _name.text = community.profile!.displayName;
      _avatar = community.profile!.avatar;
      // Beta Faz 7 — yüklenmiş fotoğraf varsa önizlemede o gösterilir.
      _avatarUrl = community.profile!.avatarUrl;
      _public = community.profile!.isPublic;
    }

    final editing = community.joined;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Topluluk profilim' : 'Topluluğa katıl')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s10,
          ),
          children: [
            const AppCallout(
              tone: CalloutTone.info,
              title: 'Katılım tamamen sana bağlı',
              text:
                  'Topluluk **isteğe bağlıdır**. Katılmazsan hiçbir bilgin paylaşılmaz. Paylaşılan tek şey **seçtiğin görünen ad, avatar ve çalışma istatistiklerindir** — e-posta ve gerçek adın **asla** görünmez.',
            ),
            const SizedBox(height: AppSpacing.s5),

            const SectionTitle('Görünen ad'),
            TextField(
              controller: _name,
              maxLength: kDisplayNameMax,
              decoration: InputDecoration(
                hintText: 'Toplulukta görünecek ad',
                errorText: _nameError,
                counterText: '',
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            Text(
              'Gerçek adın olmak zorunda değil. E-posta giremezsin.',
              style: TextStyle(color: p.text3, fontSize: 12.5),
            ),

            const SectionTitle('Avatar'),
            Text(
              'İstersen fotoğraf yükle, istersen maskotlardan birini seç. Fotoğraf yüklemek '
              'zorunlu değildir.',
              style: TextStyle(color: p.text3, fontSize: 12.5),
            ),
            const SizedBox(height: AppSpacing.s3),
            // Beta Faz 7 — fotoğraf yükleme. Fotoğraf varsa önizlemesi, yoksa seçili maskot.
            Row(
              children: [
                CommunityAvatarView(
                  avatarId: _avatar.id,
                  avatarUrl: _avatarUrl,
                  size: 64,
                  showRing: true,
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editPhoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(_avatarUrl == null ? 'Fotoğraf yükle' : 'Fotoğrafı değiştir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              _avatarUrl == null
                  ? 'Maskotunu seç:'
                  : 'Fotoğrafını kaldırırsan aşağıdaki maskota dönülür:',
              style: TextStyle(color: p.text3, fontSize: 12.5),
            ),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s3,
              children: [
                for (final a in CommunityAvatar.values)
                  Semantics(
                    label: a.label,
                    selected: _avatar == a,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      onTap: () => setState(() => _avatar = a),
                      child: Container(
                        width: 78,
                        height: 78,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(
                            color: _avatar == a ? p.primary : p.border,
                            width: _avatar == a ? 2 : 1,
                          ),
                        ),
                        child: MascotImage(a.asset, semanticLabel: a.label),
                      ),
                    ),
                  ),
              ],
            ),

            const SectionTitle('Görünürlük'),
            SwitchListTile.adaptive(
              value: _public,
              onChanged: (v) => setState(() => _public = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Sıralamada görün'),
              subtitle: Text(
                _public
                    ? 'Adın ve XP\'in sıralamada görünür.'
                    : 'Profilin gizli kalır; kimse seni göremez.',
                style: TextStyle(color: p.text3, fontSize: 12.5),
              ),
            ),

            if (community.error != null) ...[
              const SizedBox(height: AppSpacing.s3),
              AppCallout(tone: CalloutTone.danger, text: community.error!),
            ],

            const SizedBox(height: AppSpacing.s5),
            GradientPillButton(
              label: editing ? 'Kaydet' : 'Topluluğa katıl',
              trailingIcon: Icons.check_rounded,
              onPressed: community.loading ? null : () => _save(licence.wire),
            ),

            if (editing) ...[
              const SectionTitle('Güvenlik'),
              OutlinedButton.icon(
                onPressed: () => context.push('/profile/community/blocked'),
                icon: const Icon(Icons.block_rounded, size: 18),
                label: const Text('Engellediklerim'),
              ),
              const SizedBox(height: AppSpacing.s5),
              const SectionTitle('Topluluktan ayrıl'),
              Text(
                'Ayrıldığında topluluk profilin ve istatistiklerin sunucudan silinir. '
                'Çalışma ilerlemen cihazında kalır.',
                style: TextStyle(color: p.text3, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.s3),
              OutlinedButton.icon(
                onPressed: _confirmLeave,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Topluluktan ayrıl'),
                style: OutlinedButton.styleFrom(foregroundColor: p.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(String licence) async {
    final error = validateDisplayName(_name.text);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    await ref
        .read(communityProvider.notifier)
        .join(
          displayName: _name.text.trim(),
          avatarId: _avatar.id,
          licence: licence,
          public: _public,
        );
    if (!mounted) return;
    final state = ref.read(communityProvider);
    if (state.joined && state.error == null && context.mounted) context.pop();
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Topluluktan ayrıl'),
        content: const Text(
          'Topluluk profilin ve istatistiklerin silinecek. Çalışma ilerlemen cihazında kalır.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ayrıl')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(communityProvider.notifier).leave();
    if (mounted && context.mounted) context.pop();
  }
}
