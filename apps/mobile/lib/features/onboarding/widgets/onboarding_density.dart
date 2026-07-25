import 'package:flutter/material.dart';

/// Dikey bütçe sınıfı — onboarding düzeninin ne kadar sıkıştırılacağını belirler.
///
/// Yalnız piksel yüksekliğine değil, YAZI ÖLÇEĞİNE de bakar: 1,3× yazı ölçeğinde aynı piksel
/// yüksekliği çok daha az satır alır. Böylece "büyük yazı" kullanan kullanıcı da kaydırmasız
/// bir akış görür.
enum OnboardingDensity { roomy, tight, dense }

OnboardingDensity densityFor(BuildContext context, double availableHeight) {
  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
  final effective = availableHeight / scale;
  // Eşikler ÖLÇÜMLE belirlendi (bkz. faz raporu): 360×640 telefonda gövde ≈ 492 px'tir ve
  // ikincil açıklamalar düşmeden kaydırmasız sığmaz → o ölçü `dense` tarafındadır.
  if (effective < 520) return OnboardingDensity.dense;
  if (effective < 700) return OnboardingDensity.tight;
  return OnboardingDensity.roomy;
}

/// Adım gövdelerinin (seçenek kartları) yoğunluğu okuyabilmesi için taşıyıcı.
class OnboardingDensityScope extends InheritedWidget {
  const OnboardingDensityScope({
    super.key,
    required this.density,
    this.sideBySide = false,
    required super.child,
  });
  final OnboardingDensity density;

  /// Yatay düzen: seçenekler tek sütun yerine İKİ sütuna dizilir. Yatayda dikey bütçe yarıya
  /// iner ama yatay bütçe iki katına çıkar; 4 seçenekli adım ancak böyle kaydırmasız sığar.
  final bool sideBySide;

  static OnboardingDensityScope? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingDensityScope>();

  static OnboardingDensity of(BuildContext context) => _of(context)?.density ?? OnboardingDensity.roomy;

  static bool sideBySideOf(BuildContext context) => _of(context)?.sideBySide ?? false;

  @override
  bool updateShouldNotify(OnboardingDensityScope old) =>
      old.density != density || old.sideBySide != sideBySide;
}

/// Seçenek kartlarını dikey listeye veya (yatay düzende) iki sütuna dizer.
class OptionLayout extends StatelessWidget {
  const OptionLayout({super.key, required this.items, required this.gap});
  final List<Widget> items;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (!OnboardingDensityScope.sideBySideOf(context) || items.length < 4) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i != items.length - 1) SizedBox(height: gap),
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final second = i + 1 < items.length ? items[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: items[i]),
              SizedBox(width: gap),
              Expanded(child: second ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}
