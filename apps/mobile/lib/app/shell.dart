import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';

/// Uygulama kabuğu — altı sekmeli kalıcı gezinme çubuğu; her sekme kendi yığınını korur.
///
/// Faz 4: Topluluk altıncı sekme olarak eklendi. Material'ın hazır [NavigationBar]'ı bırakıldı;
/// neden estetik değil, ÖLÇÜM: 360 dp genişlikte altı hedefe düşen 60 dp'lik yuvada `NavigationBar`
/// etiketleri kırpıyor ve "Ana Sayfa" taşıyordu. Buradaki çubuk aynı erişilebilirlik sözleşmesini
/// (Semantics: seçili + düğme, geniş dokunma hedefi, sistem metin ölçeğine saygı) korur; farkı,
/// etiketi kalan genişliğe göre ölçeklemesi ve seçili göstergeyi kaydırarak taşımasıdır.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// Sekme sırası = günlük akış: öğren → çalış → sor → paylaş → kendine bak.
  /// **Router'daki dal sırasıyla BİREBİR aynı olmalıdır**; indeks eşlemesi buna dayanır.
  static const tabs = <NavTab>[
    NavTab('Ana Sayfa', Icons.home_outlined, Icons.home_rounded),
    NavTab('Öğren', Icons.menu_book_outlined, Icons.menu_book_rounded),
    NavTab('Pratik', Icons.track_changes_outlined, Icons.track_changes_rounded),
    NavTab('AI Koç', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
    NavTab('Topluluk', Icons.groups_outlined, Icons.groups_rounded),
    NavTab('Profil', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  void _onTap(int index) {
    // Etkin sekmeye yeniden dokunmak o sekmenin köküne döner — yerel uygulama davranışı.
    final sameTab = index == navigationShell.currentIndex;
    HapticFeedback.selectionClick();
    navigationShell.goBranch(index, initialLocation: sameTab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        tabs: tabs,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

/// Tek bir alt gezinme hedefi.
@immutable
class NavTab {
  const NavTab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Alt gezinme çubuğu — kayan seçim göstergesi, yaylanan simge, yuvaya sığan etiket.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Çubuğun içerik yüksekliği (sistem alt boşluğu HARİÇ).
  static const double barHeight = 62;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // E13 erişilebilirlik kuralı: "animasyonları azalt" açıkken hareket ÜRETİLMEZ. Gösterge yine
    // doğru yerdedir, yalnız oraya kaymadan gider.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            // Gölge rengi de token'dan: açık temada metin rengi (koyu lacivert) yumuşak bir
            // gölge verir; koyu temada saf siyah gerekir, çünkü yüzey zaten koyudur.
            color: p.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.45)
                : p.text.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / tabs.length;
              // Gösterge simgenin arkasındaki haptır; yuvadan dar tutulur ki komşuya değmesin.
              final pillWidth = (slot - AppSpacing.s2).clamp(36.0, 72.0);
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: reduceMotion ? Duration.zero : AppMotion.base,
                    curve: AppMotion.easeOut,
                    left: slot * currentIndex + (slot - pillWidth) / 2,
                    top: 8,
                    width: pillWidth,
                    height: 30,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            tab: tabs[i],
                            selected: i == currentIndex,
                            slotWidth: slot,
                            reduceMotion: reduceMotion,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.slotWidth,
    required this.reduceMotion,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final double slotWidth;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.primary : p.text3;

    // Etiket yuvaya SIĞACAK şekilde ölçeklenir. Sabit punto, altı sekmede "Ana Sayfa"yı kırpıyordu;
    // burada yuva genişliği ölçülür ve yazı gerekirse küçültülür (10,0 alt sınır — altı okunmuyor).
    // Kullanıcının sistem metin ölçeği bunun ÜSTÜNE uygulanır; ezilmez.
    final labelSize = slotWidth >= 68
        ? 11.5
        : slotWidth >= 60
        ? 10.8
        : 10.0;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      // Dokunma eylemi BURADA bildirilir: `excludeSemantics` alt ağacı sustururken `InkResponse`'un
      // ürettiği eylemi de siliyordu → ekran okuyucu düğmeyi "etkinleştirilemez" sanıyordu.
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: slotWidth * 0.5,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        child: SizedBox(
          height: AppBottomNav.barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Seçilince simge hafifçe büyür ve yerine oturur — dokunuşun görsel karşılığı.
              // Hareket azaltıldığında animasyon KURULMAZ (widget ağacına hiç girmez).
              if (reduceMotion)
                Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 23)
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: selected ? 1.12 : 1.0),
                  duration: AppMotion.base,
                  curve: AppMotion.easeOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 23),
                ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    height: 1.05,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
