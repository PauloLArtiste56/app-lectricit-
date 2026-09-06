import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/entree_historique.dart';

/// Écran Stats : score global, modules terminés, historique des quiz.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  /// `2026-09-05` → `05/09/2026`.
  static String formaterDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Future<void> _confirmerReinitialisation(BuildContext context) async {
    final etat = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser la progression ?'),
        content: const Text(
          'Toutes les fiches lues, questions réussies et l\'historique '
          'seront effacés. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok == true) await etat.reinitialiser();
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);

    if (!etat.pret) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pourcentage = (etat.scoreGlobal * 100).round();
    // Historique du plus récent au plus ancien.
    final historique = etat.historique.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _Tuile(
                  titre: 'Score global',
                  valeur: '$pourcentage %',
                  detail: '${etat.totalReussies} / ${etat.totalQuestions} questions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tuile(
                  titre: 'Modules terminés',
                  valeur: '${etat.modulesTermines} / ${etat.modulesAvecContenu.length}',
                  detail: 'toutes les questions réussies',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Historique', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (historique.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucun quiz pour l\'instant. Lance-toi !'),
            ),
          for (final entree in historique) _LigneHistorique(entree: entree),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _confirmerReinitialisation(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Réinitialiser la progression'),
          ),
        ],
      ),
    );
  }
}

class _Tuile extends StatelessWidget {
  const _Tuile({required this.titre, required this.valeur, required this.detail});

  final String titre;
  final String valeur;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(detail, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LigneHistorique extends StatelessWidget {
  const _LigneHistorique({required this.entree});

  final EntreeHistorique entree;

  @override
  Widget build(BuildContext context) {
    final etat = context.read<AppState>();
    final titre = switch (entree.moduleId) {
      AppState.idRevision => 'Révision',
      AppState.idExamen => 'Examen blanc',
      final id => etat.moduleParId(id)?.titre ?? id,
    };
    final reussi = entree.score == entree.total;
    return Card(
      child: ListTile(
        leading: Icon(
          reussi ? Icons.emoji_events : Icons.history,
          color: reussi ? Colors.amber.shade700 : null,
        ),
        title: Text(titre),
        subtitle: Text(StatsScreen.formaterDate(entree.date)),
        trailing: Text(
          '${entree.score} / ${entree.total}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
