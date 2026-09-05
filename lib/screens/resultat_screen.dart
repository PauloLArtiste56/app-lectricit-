import 'package:flutter/material.dart';

import '../models/module.dart';
import '../models/question.dart';
import 'quiz_screen.dart';

/// Écran Résultat : score, questions ratées, bouton "Refaire les ratées".
class ResultatScreen extends StatelessWidget {
  const ResultatScreen({
    super.key,
    required this.titre,
    this.module,
    required this.score,
    required this.total,
    required this.questionsRatees,
  });

  final String titre;

  /// Module du quiz, `null` pour une révision multi-modules.
  final Module? module;
  final int score;
  final int total;
  final List<Question> questionsRatees;

  void _refaireLesRatees(BuildContext context) {
    // On remplace l'écran Résultat par un nouveau quiz limité aux ratées,
    // pour ne pas empiler les écrans à chaque tentative.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          titre: titre,
          module: module,
          questions: questionsRatees,
        ),
      ),
    );
  }

  void _retourAccueil(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Ce qu'il fallait répondre, en une ligne.
  String _bonneReponse(Question q) => switch (q.type) {
        TypeQuestion.qcm => 'Bonne réponse : ${q.reponses[q.bonne]}',
        TypeQuestion.ordre => 'Bon ordre : ${q.reponses.join(' → ')}',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sansFaute = questionsRatees.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
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
                  subtitle: Text(_bonneReponse(question)),
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
