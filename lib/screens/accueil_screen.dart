import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../widgets/module_card.dart';
import 'module_screen.dart';
import 'quiz_screen.dart';

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
            // Première ligne : la carte de révision ; ensuite les modules.
            itemCount: etat.modules.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const _CarteRevision();
              final module = etat.modules[index - 1];
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

/// Carte "Réviser mes points faibles" en tête de l'accueil.
class _CarteRevision extends StatelessWidget {
  const _CarteRevision();

  void _lancer(BuildContext context, AppState etat) {
    final questions = etat.questionsPourRevision();
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(titre: 'Révision', questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final aRevoir = etat.nombreARevoir;
    final toutReussi = etat.totalReussies == etat.totalQuestions && aRevoir == 0;

    final String texte;
    if (toutReussi) {
      texte = 'Tout est réussi. Une séance pour entretenir ?';
    } else if (aRevoir == 0) {
      texte = 'Un mélange de questions pas encore faites.';
    } else {
      texte = '$aRevoir question${aRevoir > 1 ? 's' : ''} ratée${aRevoir > 1 ? 's' : ''} à retravailler.';
    }

    return Card(
      color: scheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12, top: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: toutReussi ? null : () => _lancer(context, etat),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.psychology, size: 40, color: scheme.onPrimaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réviser mes points faibles',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            )),
                    const SizedBox(height: 4),
                    Text(texte,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                            )),
                  ],
                ),
              ),
              if (!toutReussi)
                Icon(Icons.play_circle, size: 32, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
