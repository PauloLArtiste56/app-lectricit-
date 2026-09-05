import 'package:flutter/material.dart';

import 'accueil_screen.dart';
import 'stats_screen.dart';

/// Coque principale : la barre du bas Accueil / Stats.
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
      // IndexedStack garde les deux onglets en mémoire : on ne perd pas
      // la position de défilement en passant de l'un à l'autre.
      body: IndexedStack(
        index: _onglet,
        children: const [AccueilScreen(), StatsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
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
