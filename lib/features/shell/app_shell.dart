import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../guide/guide_screen.dart';
import '../home/home_screen.dart';
import '../stats/stats_screen.dart';

/// Top-level frame: an app bar that adapts to the selected tab and a bottom
/// navigation bar. Only the selected page is built, so the two pages never
/// fight over state or duplicate content.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = <String>[AppConstants.appName, 'Stats', 'How it works'];
  static const _icons = <IconData>[
    Icons.shield_rounded,
    Icons.insights_rounded,
    Icons.menu_book_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTheme.gutter,
        title: Row(
          children: [
            Icon(_icons[_index], color: scheme.primary),
            const SizedBox(width: 10),
            Text(_titles[_index]),
          ],
        ),
      ),
      body: switch (_index) {
        0 => const HomeScreen(),
        1 => const StatsScreen(),
        _ => const GuideScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Block',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'How it works',
          ),
        ],
      ),
    );
  }
}
