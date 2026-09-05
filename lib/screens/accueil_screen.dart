import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../widgets/module_card.dart';
import 'module_screen.dart';

/// Écran d'accueil : la liste des modules avec leur progression.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `watch` : l'écran se redessine dès que la progression change.
    final etat = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('ElecApp')),
      body: switch (etat) {
        AppState(erreur: final e?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Impossible de charger le contenu :\n$e'),
            ),
          ),
        AppState(pret: false) =>
          const Center(child: CircularProgressIndicator()),
        _ => ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: etat.modules.length,
            itemBuilder: (context, index) {
              final module = etat.modules[index];
              return ModuleCard(
                module: module,
                questionsReussies: etat.questionsReussies(module),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModuleScreen(module: module),
                  ),
                ),
              );
            },
          ),
      },
    );
  }
}
