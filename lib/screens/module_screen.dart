import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/module.dart';
import '../models/question.dart';
import 'fiche_screen.dart';
import 'quiz_screen.dart';

/// Écran Module : les fiches à lire (avec coche si déjà lues) et le
/// bouton pour lancer le quiz.
class ModuleScreen extends StatelessWidget {
  const ModuleScreen({super.key, required this.module});

  final Module module;

  void _ouvrirFiche(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FicheScreen(module: module, index: index),
      ),
    );
  }

  /// [questions] limite le quiz à une sous-liste (les ratées) ; sinon tout.
  void _lancerQuiz(BuildContext context, {List<Question>? questions}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(module: module, questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final reussies = etat.questionsReussies(module);
    final meilleur = etat.progressionDe(module).meilleurScore;
    final aRevoir = etat.questionsARevoir(module);
    // Module déjà commencé mais pas terminé : on propose les deux options.
    final commence = reussies > 0 && aRevoir.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(module.titre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$reussies / ${module.nombreQuestions} questions réussies',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: module.nombreQuestions == 0
                        ? 0
                        : reussies / module.nombreQuestions,
                  ),
                  if (meilleur > 0) ...[
                    const SizedBox(height: 8),
                    Text('Meilleur score : $meilleur / ${module.nombreQuestions}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Fiches de cours', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (module.fiches.isEmpty)
            const Text('Pas encore de fiche pour ce module.'),
          for (var i = 0; i < module.fiches.length; i++)
            Card(
              child: ListTile(
                leading: Icon(
                  etat.ficheLue(module, module.fiches[i].id)
                      ? Icons.check_circle
                      : Icons.article_outlined,
                  color: etat.ficheLue(module, module.fiches[i].id)
                      ? Colors.green
                      : null,
                ),
                title: Text(module.fiches[i].titre),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _ouvrirFiche(context, i),
              ),
            ),
          const SizedBox(height: 24),
          if (commence) ...[
            FilledButton.icon(
              onPressed: () => _lancerQuiz(context, questions: aRevoir),
              icon: const Icon(Icons.replay),
              label: Text('Refaire uniquement les ratées (${aRevoir.length})'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _lancerQuiz(context),
              icon: const Icon(Icons.restart_alt),
              label: Text(
                'Recommencer depuis le début (${module.nombreQuestions} questions)',
              ),
            ),
          ] else
            FilledButton.icon(
              onPressed: () => _lancerQuiz(context),
              icon: const Icon(Icons.quiz),
              label: Text(
                reussies == 0
                    ? 'Lancer le quiz (${module.nombreQuestions} questions)'
                    : 'Refaire le quiz (${module.nombreQuestions} questions)',
              ),
            ),
        ],
      ),
    );
  }
}
