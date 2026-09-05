import 'package:flutter/material.dart';

import '../data/quiz_session.dart';
import '../models/module.dart';
import '../widgets/reponse_button.dart';

/// Écran Quiz : une question à la fois, feedback immédiat, barre de progression.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.module});

  final Module module;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizSession _session = QuizSession(widget.module.questions);

  void _repondre(int index) => setState(() => _session.repondre(index));

  void _suivante() => setState(() => _session.suivante());

  EtatReponse _etatDe(int index) {
    if (!_session.aRepondu) return EtatReponse.neutre;
    if (_session.questionCourante.estBonne(index)) return EtatReponse.bonne;
    if (index == _session.choix) return EtatReponse.mauvaise;
    return EtatReponse.neutre;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.titre)),
      body: _session.estTerminee ? _buildFin(context) : _buildQuestion(context),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final question = _session.questionCourante;
    final theme = Theme.of(context);
    final aRepondu = _session.aRepondu;
    final bonneReponse = aRepondu && question.estBonne(_session.choix!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(value: _session.progression),
        const SizedBox(height: 8),
        Text(
          'Question ${_session.numero} / ${_session.total}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 24),
        Text(question.enonce, style: theme.textTheme.titleLarge),
        const SizedBox(height: 24),
        for (var i = 0; i < question.reponses.length; i++)
          ReponseButton(
            texte: question.reponses[i],
            etat: _etatDe(i),
            onPressed: aRepondu ? null : () => _repondre(i),
          ),
        if (aRepondu) ...[
          const SizedBox(height: 16),
          Card(
            color: bonneReponse ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bonneReponse ? 'Bonne réponse !' : 'Mauvaise réponse',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: bonneReponse ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(question.explication),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _suivante,
            child: Text(_session.estDerniere ? 'Terminer' : 'Question suivante'),
          ),
        ],
      ],
    );
  }

  /// Fin de quiz provisoire. L'écran Résultat complet arrive à l'étape 3.
  Widget _buildFin(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quiz terminé', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Score : ${_session.score} / ${_session.total}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      ),
    );
  }
}
