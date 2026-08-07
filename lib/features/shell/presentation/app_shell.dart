import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// The app frame: a body driven by the current nav branch plus a 5-tab
/// bottom NavigationBar. Tab state persists across switches (indexed stack).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.fitness_center),
            label: loc.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: loc.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: loc.navProgress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt),
            label: loc.navPrograms,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: loc.navSettings,
          ),
        ],
      ),
    );
  }
}
