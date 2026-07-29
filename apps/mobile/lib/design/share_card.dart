import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../domain/progress/gamification.dart';
import 'brand.dart';

/// Faz 10 — paylaşılabilir kartlar.
///
/// SABİT ÖLÇÜ, telefon genişliğine bağlı DEĞİL: paylaşılan görsel her cihazda aynı çıkmalı ve
/// sosyal uygulamaların beklediği orana oturmalı. 1080×1350 (4:5) seçildi — Instagram akışının
/// en çok yer kaplayan oranı; WhatsApp ve X'te de kırpılmadan görünüyor.
///
/// Kart, ekranın DIŞINDA çizilip fotoğraflanır (bkz. `badge_celebration_dialog.dart`), bu yüzden
/// düzeni görünür arayüzden bağımsızdır. Ölçüler doğrudan piksel; `AppSpacing` burada kullanılmaz
/// çünkü bu bir ekran değil, bir GÖRSELDİR.
const double _cardWidth = 1080;
const double _cardHeight = 1350;

/// Ortak zemin: marka rengi + köşe ışıması + altta marka satırı.
class _ShareCardShell extends StatelessWidget {
  const _ShareCardShell({required this.child, required this.accent});
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Kart HER İKİ TEMADA da koyudur: paylaşılan görsel bir uygulama yüzeyi değil, bir medya
    // parçasıdır. Açık temada beyaz bir kart sosyal akışta kaybolurdu.
    const bg = Color(0xFF050B16);
    const surface = Color(0xFF0B1523);

    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: const BoxDecoration(color: bg),
      child: Stack(
        children: [
          // Köşe ışımaları — markanın canlı zemininin sabit bir anı.
          Positioned(
            left: -160,
            top: -160,
            child: _Glow(color: accent, size: 620),
          ),
          Positioned(
            right: -200,
            bottom: -140,
            child: _Glow(color: p.primary, size: 560),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(84, 96, 84, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: child),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
                const SizedBox(height: 34),
                Row(
                  children: [
                    const BrandMark(size: 76),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ehliyet Akademi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sınava akıllı hazırlık',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Zemin rengi Stack'in altında kalmasın diye üstte hafif bir koyulaştırma yok:
          // ışımalar zaten düşük alfada. (Denendi; fazlası kartı çamurlaştırıyor.)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, surface.withValues(alpha: 0.35)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Rozet paylaşım kartı.
class BadgeShareCard extends StatelessWidget {
  const BadgeShareCard({super.key, required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _ShareCardShell(
      accent: p.accent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'YENİ ROZET',
            style: TextStyle(
              color: p.accent,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
            ),
          ),
          const SizedBox(height: 56),
          Container(
            width: 320,
            height: 320,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [p.accent.withValues(alpha: 0.30), p.accent.withValues(alpha: 0.04)],
              ),
              border: Border.all(color: p.accent, width: 6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(achievement.icon, maxLines: 1, style: const TextStyle(fontSize: 150)),
              ),
            ),
          ),
          const SizedBox(height: 56),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 62, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 30),
          ),
        ],
      ),
    );
  }
}

/// Sınav sonucu paylaşım kartı.
class ExamResultShareCard extends StatelessWidget {
  const ExamResultShareCard({
    super.key,
    required this.correct,
    required this.total,
    required this.passed,
    required this.durationLabel,
  });

  final int correct;
  final int total;
  final bool passed;

  /// Süre metni (ör. `32:14`) — biçimleme çağıranda, kart yalnız gösterir.
  final String durationLabel;

  int get percent => total == 0 ? 0 : (correct / total * 100).round();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = passed ? p.green : p.accent;

    // `Expanded` + `FittedBox`: üç istatistik kartın genişliğini PAYLAŞIR ve sığmayan değer
    // küçülür. Sabit punto ile "42/50" gibi uzun bir değer satırı taşırıyordu (testte yakalandı);
    // paylaşılan bir görselde taşma, kırmızı çizgili bir kare demektir.
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 62,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontSize: 26),
            ),
          ),
        ],
      ),
    );

    return _ShareCardShell(
      accent: accent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            passed ? 'DENEME SINAVINI GEÇTİM' : 'DENEME SINAVI SONUCUM',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            width: 400,
            height: 400,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 12),
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.02)],
              ),
            ),
            // Halkanın İÇİ de küçülebilir olmalı: üç haneli bir yüzde ya da geniş bir yazı tipi
            // sabit puntoda halkayı taşırıyor (testte yakalandı).
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%$percent',
                      maxLines: 1,
                      style: TextStyle(color: accent, fontSize: 128, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'başarı',
                      maxLines: 1,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 30),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 56),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              stat('$correct/$total', 'doğru'),
              stat(durationLabel, 'süre'),
              stat(passed ? 'GEÇTİ' : 'TEKRAR', 'sonuç'),
            ],
          ),
        ],
      ),
    );
  }
}
