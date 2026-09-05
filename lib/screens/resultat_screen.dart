import 'package:flutter/material.dart';

import '../models/module.dart';
import '../models/question.dart';
import 'quiz_screen.dart';

/// Écran Résultat : score, questions ratées, bouton "Refaire les ratées".
class ResultatScreen extends StatelessWidget {
  const ResultatScreen({
    super.key,
    required this.module,
    required this.score,
    required this.total,
    required this.questionsRatees,
  });

  final Module module;
  final int score;
  final int total;
  final List<Question> questionsRatees;

  void _refaireLesRatees(BuildContext context) {
    // On remplace l'écran Résultat par un nouveau quiz limité aux ratées,
    // pour ne pas empiler les écrans à chaque tentative.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(module: module, questions: questionsRatees),
      ),
    );
  }

  void _retourAccueil(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sansFaute = questionsRatees.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(module.titre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Text(
            sansFaute ? 'Sans faute !' : 'Quiz terminé',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$score / $total',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              color: sansFaute ? Colors.green.shade700 : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (!sansFaute) ...[
            Text('À revoir', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final question in questionsRatees)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: Text(question.enonce),
                  subtitle: Text(
                    'Bonne réponse : ${question.reponses[question.bonne]}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _refaireLesRatees(context),
              icon: const Icon(Icons.replay),
              label: Text('Refaire les ratées (${questionsRatees.length})'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => _retourAccueil(context),
            child: const Text("Retour à l'accueil"),
          ),
        ],
      ),
    );
  }
}
