import 'package:flutter/material.dart';

import '../../../core/dash_assets.dart';
import '../../../core/mech_assets.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/content/traffic_sign.dart';
import '../../../domain/practice/question.dart';
import '../../learn/widgets/traffic_sign_view.dart';

/// QIP v3 · Faz 4 — sorunun GÖRSELİ.
///
/// ## Neden tür başına ayrı çizim yolu
///
/// Üç görsel ailesinin kaynağı farklıdır ve tek bir `Image.asset` hepsini çizemez:
///
/// · **Levha** — resmî vektörü olan 86 levha SVG'den, kalan 35'i PARAMETRİK çiziciden gelir
///   ([TrafficSignView]). Yol yazmak, o 35 levhayı görselsiz bırakırdı.
/// · **İkaz ışığı** — `assets/dash/<id>.webp`, koyu zeminde okunması için hafif bir kart içinde.
/// · **Mekanik parça** — `assets/mech/<id>.webp`, gerçek fotoğraf; en geniş çizim alanı bunun.
///
/// ## Görsel çizilemezse
///
/// Soru CEVAPLANAMAZ hâle gelmemeli. Varlık bulunamazsa görselin yerine `alt` metni okunur —
/// bu yüzden `alt` şemada zorunlu. Sessizce boş bir kutu bırakmak, kullanıcıyı cevaplayamayacağı
/// bir soruda tutmak olurdu.
class QuestionMediaView extends StatelessWidget {
  const QuestionMediaView({super.key, required this.question, this.signs = const []});

  final Question question;

  /// Levha soruları için katalog — kimlikten [TrafficSign] bulunur.
  final List<TrafficSign> signs;

  @override
  Widget build(BuildContext context) {
    final media = question.media;
    if (media == null || media.images.isEmpty) return const SizedBox.shrink();

    final images = media.images;
    // Tek görsel en sık hâl; ızgara yalnız çoklu görselde kurulur (gereksiz Wrap maliyeti yok).
    if (images.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s4),
        child: Center(child: _one(context, images.first)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.s3,
        runSpacing: AppSpacing.s3,
        children: [for (final img in images) _one(context, img)],
      ),
    );
  }

  Widget _one(BuildContext context, QuestionImage img) {
    final child = switch (question.kind) {
      QuestionKind.sign => _sign(img),
      QuestionKind.dashboard => _asset(context, dashAsset(img.assetId), img, height: 120),
      QuestionKind.mechanic => _asset(context, mechAsset(img.assetId), img, height: 190),
      _ => _asset(context, null, img, height: 170),
    };
    // Ekran okuyucu için tek etiket: görselin kendisi değil, ne anlattığı okunur.
    return Semantics(label: img.alt, image: true, child: child);
  }

  Widget _sign(QuestionImage img) {
    final sign = signs.where((s) => s.id == img.assetId).firstOrNull;
    if (sign == null) return _fallback(img);
    return TrafficSignView(sign: sign, size: 132);
  }

  Widget _asset(BuildContext context, String? path, QuestionImage img, {required double height}) {
    if (path == null) return _fallback(img);
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
      ),
      child: Image.asset(
        path,
        height: height,
        fit: BoxFit.contain,
        // Varlık pakette bozuksa da soru cevaplanabilir kalmalı.
        errorBuilder: (_, _, _) => _fallback(img),
      ),
    );
  }

  /// Görselin yerine geçen DÜRÜST metin. Boş kutu değil: kullanıcı neyi göremediğini bilir ve
  /// soruyu yine de cevaplayabilir.
  Widget _fallback(QuestionImage img) => Builder(
    builder: (context) {
      final p = context.palette;
      return Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 18, color: p.text3),
            const SizedBox(width: AppSpacing.s2),
            Flexible(
              child: Text(
                img.alt,
                style: TextStyle(color: p.text2, fontSize: 13, height: 1.3),
              ),
            ),
          ],
        ),
      );
    },
  );
}
