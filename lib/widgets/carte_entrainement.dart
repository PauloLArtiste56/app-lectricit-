import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/question.dart';
import '../screens/quiz_screen.dart';

/// Carte d'entraînement en tête du parcours : séance du jour (révision
/// espacée), points faibles, série de jours.
class CarteEntrainement extends StatelessWidget {
  const CarteEntrainement({super.key});

  void _lancer(BuildContext context, String titre, List<Question> questions) {
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(titre: titre, questions: questions),
      ),
    );
  }

  void _lancerExamen(BuildContext context, AppState etat) {
    final questions = etat.questionsExamen();
    if (questions.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          titre: 'Examen blanc',
          questions: questions,
          examen: true,
          duree: AppState.dureeExamen,
        ),
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
                Expanded(
                  child: Text(
                    serie > 0
                        ? 'Série : $serie jour${serie > 1 ? 's' : ''}'
                        : 'Pas de série en cours',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Icon(Icons.stars, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  'Niveau ${etat.niveau} · ${etat.xpTotal} XP',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Avancement vers le niveau suivant.
            Tooltip(
              message: 'Encore ${etat.xpManquants} XP pour le niveau ${etat.niveau + 1}',
              child: LinearProgressIndicator(
                value: etat.progressionNiveau,
                minHeight: 6,
                color: Colors.amber.shade700,
                backgroundColor: scheme.surface.withValues(alpha: 0.6),
              ),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _lancerExamen(context, etat),
              icon: const Icon(Icons.timer_outlined),
              label: Text(
                'Examen blanc : ${AppState.tailleExamen} questions '
                'en ${AppState.dureeExamen.inMinutes} min',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
