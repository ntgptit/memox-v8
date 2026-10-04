import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/l10n/l10n_context.dart';

/// SP2 (S10): the four tabs of docs/NAVIGATION.md over the branch stacks.
/// Re-tapping the current tab returns its branch to its root.
class PlaceholderShell extends StatelessWidget {
  const PlaceholderShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == current),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.collections_bookmark_outlined),
            label: l10n.navLibrary,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            label: l10n.navStudy,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            label: l10n.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
