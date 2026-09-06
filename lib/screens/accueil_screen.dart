import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../widgets/module_card.dart';
import 'module_screen.dart';

/// Onglet Modules : tous les modules par thème, avec leur progression.
/// Pratique pour aller directement sur un sujet, sans suivre le parcours.
class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `watch` : l'écran se redessine dès que la progression change.
    final etat = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tous les modules')),
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
            // Un titre de section à chaque changement de thème.
            itemCount: etat.modules.length,
            itemBuilder: (context, index) {
              final module = etat.modules[index];
              final precedent = index >= 1 ? etat.modules[index - 1] : null;
              final nouveauTheme =
                  module.theme.isNotEmpty && module.theme != precedent?.theme;
              final carte = ModuleCard(
                module: module,
                questionsReussies: etat.questionsReussies(module),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModuleScreen(module: module),
                  ),
                ),
              );
              if (!nouveauTheme) return carte;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                    child: Text(
                      module.theme,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  carte,
                ],
              );
            },
          ),
      },
    );
  }
}
