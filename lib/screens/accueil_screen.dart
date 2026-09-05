import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/question.dart';
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
              if (index == 0) return const _CarteEntrainement();
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

/// Carte d'entraînement en tête de l'accueil : séance du jour (révision
/// espacée), points faibles, série de jours.
class _CarteEntrainement extends StatelessWidget {
  const _CarteEntrainement();

  void _lancer(BuildContext context, String titre, List<Question> questions) {
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(titre: titre, questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dues = etat.nombreDues;
    final faibles = etat.nombreARevoir;
    final serie = etat.serieJours;
    final seance = etat.questionsDuJour();

    final String sousTitre;
    if (dues > 0) {
      sousTitre = '$dues question${dues > 1 ? 's' : ''} à revoir aujourd\'hui';
    } else if (seance.isNotEmpty) {
      sousTitre = 'Rien à revoir aujourd\'hui : on découvre de nouvelles questions';
    } else {
      sousTitre = 'Tout est à jour. Reviens demain !';
    }

    return Card(
      color: scheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 12, top: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    color: serie > 0 ? Colors.orange.shade700 : scheme.outline),
                const SizedBox(width: 6),
                Text(
                  serie > 0
                      ? 'Série : $serie jour${serie > 1 ? 's' : ''}'
                      : 'Pas de série en cours',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Ma séance du jour',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                )),
            const SizedBox(height: 4),
            Text(sousTitre,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                )),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: seance.isEmpty
                  ? null
                  : () => _lancer(context, 'Séance du jour', seance),
              icon: const Icon(Icons.play_arrow),
              label: Text('Lancer la séance (${seance.length} questions)'),
            ),
            if (faibles > 0) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _lancer(
                    context, 'Points faibles', etat.questionsPourRevision()),
                icon: const Icon(Icons.psychology),
                label: Text('Retravailler mes $faibles point${faibles > 1 ? 's' : ''} faible${faibles > 1 ? 's' : ''}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
