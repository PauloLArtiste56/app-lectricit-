import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/module.dart';
import '../models/question.dart';
import '../widgets/bouton_relief.dart';
import '../widgets/couleurs_parcours.dart';
import '../widgets/couronnes.dart';
import '../widgets/module_icon.dart';
import 'cartes_screen.dart';
import 'fiche_screen.dart';
import 'quiz_screen.dart';

/// Écran Module : en-tête à la couleur du chapitre, les fiches présentées
/// comme des étapes (coche si déjà lues) et le bouton pour lancer le quiz.
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

  void _lancerCartes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartesScreen(titre: module.titre, questions: module.questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reussies = etat.questionsReussies(module);
    final total = module.nombreQuestions;
    final meilleur = etat.progressionDe(module).meilleurScore;
    final aRevoir = etat.questionsARevoir(module);
    // Module déjà commencé mais pas terminé : on propose les deux options.
    final commence = reussies > 0 && aRevoir.isNotEmpty;
    final chapitre = etat.chapitreDe(module);
    final couleur = chapitre == null ? scheme.primary : couleurChapitre(chapitre);
    final encre = texteSur(couleur);
    final reussi = etat.moduleReussi(module);
    final seuil = (total * AppState.seuilReussite).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text(module.titre),
        backgroundColor: couleur,
        foregroundColor: encre,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête coloré : icône, progression, meilleur score.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: total == 0 ? 0 : reussies / total,
                        strokeWidth: 6,
                        color: reussi ? vertReussi : encre,
                        backgroundColor: encre.withValues(alpha: 0.25),
                      ),
                      Center(
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: encre,
                          child: Icon(
                            reussi ? Icons.check : iconePourModule(module.id),
                            color: reussi ? vertReussi : couleur,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (chapitre != null)
                        Text(
                          chapitre.titre.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: encre.withValues(alpha: 0.85),
                            letterSpacing: 1,
                          ),
                        ),
                      Text(
                        '$reussies / $total questions réussies',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: encre,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reussi
                            ? 'Module réussi'
                            : 'Objectif : $seuil sur $total pour débloquer la suite',
                        style: theme.textTheme.bodySmall?.copyWith(color: encre),
                      ),
                      if (meilleur > 0)
                        Text(
                          'Meilleur score : $meilleur / $total',
                          style: theme.textTheme.bodySmall?.copyWith(color: encre),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Couronnes(
                            nombre: etat.couronnes(module),
                            taille: 18,
                            couleurVide: encre.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              etat.prochaineCouronne(module) ?? 'Module maîtrisé !',
                              style: theme.textTheme.bodySmall?.copyWith(color: encre),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Fiches de cours', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (module.fiches.isEmpty)
                  const Text('Pas encore de fiche pour ce module.'),
                for (var i = 0; i < module.fiches.length; i++)
                  _EtapeFiche(
                    numero: i + 1,
                    titre: module.fiches[i].titre,
                    lue: etat.ficheLue(module, module.fiches[i].id),
                    couleur: couleur,
                    derniere: i == module.fiches.length - 1,
                    onTap: () => _ouvrirFiche(context, i),
                  ),
                const SizedBox(height: 24),
                if (commence) ...[
                  BoutonRelief(
                    label: 'Refaire uniquement les ratées (${aRevoir.length})',
                    icone: Icons.replay,
                    couleur: couleur,
                    onPressed: () => _lancerQuiz(context, questions: aRevoir),
                  ),
                  const SizedBox(height: 10),
                  BoutonRelief(
                    label: 'Recommencer depuis le début ($total questions)',
                    icone: Icons.restart_alt,
                    couleur: couleur,
                    secondaire: true,
                    onPressed: () => _lancerQuiz(context),
                  ),
                ] else
                  BoutonRelief(
                    label: reussies == 0
                        ? 'Lancer le quiz ($total questions)'
                        : 'Refaire le quiz ($total questions)',
                    icone: Icons.quiz,
                    couleur: couleur,
                    onPressed: total == 0 ? null : () => _lancerQuiz(context),
                  ),
                if (total > 0) ...[
                  const SizedBox(height: 10),
                  BoutonRelief(
                    label: 'Réviser en cartes ($total cartes)',
                    icone: Icons.style,
                    couleur: couleur,
                    secondaire: true,
                    onPressed: () => _lancerCartes(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une fiche présentée comme une étape numérotée, reliée à la suivante.
class _EtapeFiche extends StatelessWidget {
  const _EtapeFiche({
    required this.numero,
    required this.titre,
    required this.lue,
    required this.couleur,
    required this.derniere,
    required this.onTap,
  });

  final int numero;
  final String titre;
  final bool lue;
  final Color couleur;
  final bool derniere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: lue ? vertReussi : couleur.withValues(alpha: 0.15),
                  child: lue
                      ? const Icon(Icons.check_circle, color: Colors.white, size: 22)
                      : Text('$numero',
                          style: TextStyle(color: couleur, fontWeight: FontWeight.w800)),
                ),
                if (!derniere)
                  Expanded(
                    child: Container(width: 3, color: scheme.outlineVariant),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    Icon(Icons.chevron_right, color: scheme.outline),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
