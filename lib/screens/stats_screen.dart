import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/insignes.dart';
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
          const SizedBox(height: 12),
          _Tuile(
            titre: 'Couronnes',
            valeur: '${etat.couronnesTotal} / ${etat.couronnesMax}',
            detail: 'réussi, sans faute, confirmé en révision : 3 par module',
          ),
          const SizedBox(height: 12),
          _Tuile(
            titre: 'Niveau ${etat.niveau}',
            valeur: '${etat.xpTotal} XP',
            detail: 'encore ${etat.xpManquants} XP pour le niveau ${etat.niveau + 1} '
                '(${AppState.xpParBonneReponse} XP par bonne réponse)',
          ),
          const SizedBox(height: 24),
          Text('Cette semaine', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const _RecapSemaine(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Badges', style: theme.textTheme.titleMedium)),
              Text(
                '${etat.badgesObtenus.length}/${Insigne.tous.length}',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _GrilleBadges(),
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

/// Récap des 7 derniers jours : trois chiffres et un petit graphique des XP
/// par jour, dessiné avec de simples colonnes.
class _RecapSemaine extends StatelessWidget {
  const _RecapSemaine();

  static const _initiales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jours = etat.semaine;
    final maxXp = jours.fold(0, (m, j) => j.xp > m ? j.xp : m);

    Widget chiffre(String valeur, String legende) => Expanded(
          child: Column(
            children: [
              Text(valeur,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
              Text(legende, style: theme.textTheme.bodySmall),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                chiffre('+${etat.xpSemaine} XP', 'gagnés'),
                chiffre('${etat.quizSemaine}', 'quiz'),
                chiffre('${etat.joursActifsSemaine} / 7', 'jours actifs'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, jour) in jours.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: '${jour.xp} XP, ${jour.quiz} quiz',
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: maxXp == 0 ? 4 : 4 + 64 * jour.xp / maxXp,
                              decoration: BoxDecoration(
                                color: jour.quiz > 0
                                    ? Colors.amber.shade700
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _initiales[jour.date.weekday - 1],
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: i == 6 ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
      // Ancien mode éclair (retiré) : les lignes déjà enregistrées gardent un nom.
      'eclair' => 'Mode éclair',
      final id when id.startsWith(AppState.prefixeCas) =>
        'Cas pratique : ${etat.casParId(id.substring(AppState.prefixeCas.length))?.titre ?? id}',
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

/// Grille des badges : ceux obtenus en couleur avec leur date, les autres
/// en gris. Un appui long (ou le survol) montre la condition.
class _GrilleBadges extends StatelessWidget {
  const _GrilleBadges();

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final obtenus = etat.badgesObtenus;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: [
        for (final b in Insigne.tous)
          () {
            final date = obtenus[b.id];
            final gagne = date != null;
            final couleur = gagne ? Colors.purple.shade400 : scheme.outlineVariant;
            return Tooltip(
              message: gagne
                  ? '${b.description}\nObtenu le ${StatsScreen.formaterDate(date)}'
                  : b.description,
              triggerMode: TooltipTriggerMode.tap,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: couleur.withValues(alpha: gagne ? 0.18 : 0.25),
                      border: Border.all(color: couleur, width: 2),
                    ),
                    child: Icon(b.icone, color: gagne ? couleur : scheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.titre,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: gagne ? null : scheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }(),
      ],
    );
  }
}
