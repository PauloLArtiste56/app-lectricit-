import 'package:flutter/material.dart';

import 'accueil_screen.dart';
import 'parcours_screen.dart';
import 'stats_screen.dart';

/// Coque principale : la barre du bas Parcours / Modules / Stats.
/// Les écrans ouverts par-dessus (module, quiz…) recouvrent la barre.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _onglet = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack garde les onglets en mémoire : on ne perd pas
      // la position de défilement en passant de l'un à l'autre.
      body: IndexedStack(
        index: _onglet,
        children: const [ParcoursScreen(), AccueilScreen(), StatsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Parcours',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Modules',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
