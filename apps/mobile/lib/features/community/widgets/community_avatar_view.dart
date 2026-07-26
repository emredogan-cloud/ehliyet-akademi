import 'package:flutter/material.dart';

import '../../../core/config.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/community/community_models.dart';

/// Beta Faz 7 — topluluk avatarı: yüklenmiş fotoğraf varsa o, yoksa paketlenmiş maskot.
///
/// MASKOTA DÖNÜŞ YAPISALDIR: [avatarUrl] null ise ya da ağdan görsel gelmezse (hata/çevrimdışı)
/// maskot çizilir. Yani "kırık avatar" durumu OLUŞAMAZ — E8'in maskot temeli korunur.
class CommunityAvatarView extends StatelessWidget {
  const CommunityAvatarView({
    super.key,
    required this.avatarId,
    this.avatarUrl,
    this.size = 44,
    this.showRing = false,
  });

  final String avatarId;

  /// Sunucudan gelen göreli yol (`/api/media/...`) ya da null.
  final String? avatarUrl;
  final double size;

  /// İnce bir çerçeve — profil kartı gibi vurgulu yerlerde.
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mascot = CommunityAvatar.fromId(avatarId);

    Widget child = Image.asset(
      mascot.asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Büyük maskot varlıkları gösterim ölçüsüne indirilir (bellek).
      cacheWidth: (size * 3).round(),
    );

    final url = avatarUrl;
    if (url != null && url.isNotEmpty) {
      child = Image.network(
        url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        // Ağ/sunucu hatasında sessizce maskota dönülür — kırık görsel gösterilmez.
        errorBuilder: (_, _, _) => Image.asset(
          mascot.asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
        ),
        loadingBuilder: (context, widget, progress) =>
            progress == null ? widget : _Placeholder(size: size, color: p.surface2),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface2,
        border: showRing ? Border.all(color: p.primary.withValues(alpha: 0.5), width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: ColoredBox(color: color));
}
