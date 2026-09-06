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

  /// Onglets déjà ouverts : les autres ne sont pas construits tant qu'on
  /// n'y est pas allé, pour alléger le démarrage sur téléphone.
  final _visites = {0};

  @override
  Widget build(BuildContext context) {
    const onglets = [ParcoursScreen(), AccueilScreen(), StatsScreen()];
    return Scaffold(
      // IndexedStack garde les onglets visités en mémoire : on ne perd pas
      // la position de défilement en passant de l'un à l'autre.
      body: IndexedStack(
        index: _onglet,
        children: [
          for (var i = 0; i < onglets.length; i++)
            _visites.contains(i) ? onglets[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() {
          _onglet = i;
          _visites.add(i);
        }),
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
