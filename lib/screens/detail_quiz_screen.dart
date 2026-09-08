import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/entree_historique.dart';
import '../models/question.dart';
import '../widgets/bouton_relief.dart';
import 'quiz_screen.dart';
import 'stats_screen.dart';

/// Nom lisible d'une ligne d'historique : module, révision, examen ou cas.
String titreQuiz(AppState etat, EntreeHistorique entree) =>
    switch (entree.moduleId) {
      AppState.idRevision => 'Révision',
      AppState.idExamen => 'Examen blanc',
      // Ancien mode éclair (retiré) : les lignes déjà faites gardent un nom.
      'eclair' => 'Mode éclair',
      final id when id.startsWith(AppState.prefixeCas) =>
        'Cas pratique : ${etat.casParId(id.substring(AppState.prefixeCas.length))?.titre ?? id}',
      final id => etat.moduleParId(id)?.titre ?? id,
    };

/// Détail d'un quiz passé : son score et les questions ratées ce jour-là,
/// avec la bonne réponse, pour pouvoir les refaire.
class DetailQuizScreen extends StatelessWidget {
  const DetailQuizScreen({super.key, required this.entree});

  final EntreeHistorique entree;

  /// Ce qu'il fallait répondre, en une ligne.
  static String bonneReponse(Question q) => switch (q.type) {
        TypeQuestion.qcm ||
        TypeQuestion.image ||
        TypeQuestion.vraiFaux =>
          q.reponses[q.bonne],
        TypeQuestion.ordre => q.reponses.join(' → '),
      };

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratees = etat.rateesDe(entree);
    final sansFaute = entree.score == entree.total;

    return Scaffold(
      appBar: AppBar(title: Text(titreQuiz(etat, entree))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(sansFaute ? Icons.emoji_events : Icons.history,
                      color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entree.score} / ${entree.total}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Le ${StatsScreen.formaterDate(entree.date)} · '
                          '${AppState.xpPour(entree.score)} XP',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (sansFaute)
            const _Message(
              icone: Icons.check_circle,
              texte: 'Sans faute : rien à revoir dans ce quiz.',
            )
          else if (entree.ratees.isEmpty)
            const _Message(
              icone: Icons.help_outline,
              texte: 'Les questions ratées de ce quiz n\'ont pas été '
                  'enregistrées : il date d\'avant cette fonctionnalité.',
            )
          else if (ratees.isEmpty)
            const _Message(
              icone: Icons.help_outline,
              texte: 'Ces questions ont changé depuis : elles ne sont plus '
                  'dans le contenu de l\'appli.',
            )
          else ...[
            Text('Questions ratées (${ratees.length})',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final q in ratees)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.enonce,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.task_alt,
                              size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              bonneReponse(q),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(q.explication,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.outline)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            BoutonRelief(
              label: 'Refaire ces ${ratees.length} questions',
              icone: Icons.replay,
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => QuizScreen(
                    titre: titreQuiz(etat, entree),
                    questions: ratees,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Message explicatif quand il n'y a rien à revoir.
class _Message extends StatelessWidget {
  const _Message({required this.icone, required this.texte});

  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: scheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texte,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline)),
        ),
      ],
    );
  }
}
