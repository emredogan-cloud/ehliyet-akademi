import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app shell: a persistent bottom navigation bar over 5 tab stacks.
/// Mirrors the web sidebar groups → mobile bottom tabs (MOBILE_UX_AUDIT.md §1).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = <_Tab>[
    _Tab('Ana Sayfa', Icons.home_outlined, Icons.home_rounded),
    _Tab('Öğren', Icons.menu_book_outlined, Icons.menu_book_rounded),
    _Tab('Pratik', Icons.track_changes_outlined, Icons.track_changes_rounded),
    _Tab('AI Koç', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
    _Tab('Profil', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  void _onTap(int index) {
    // Re-tapping the active tab pops to its root.
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
