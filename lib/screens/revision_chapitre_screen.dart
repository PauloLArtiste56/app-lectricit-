import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/chapitre.dart';
import '../models/module.dart';
import '../widgets/couleurs_parcours.dart';
import '../widgets/couronnes.dart';
import '../widgets/module_icon.dart';
import '../widgets/texte_glossaire.dart';
import 'module_screen.dart';

/// Fiche de révision d'un chapitre : toutes les fiches de ses modules
/// réunies sur un seul écran, à relire d'un coup avant un contrôle.
/// Lecture seule : parcourir cet écran ne marque aucune fiche comme lue.
class RevisionChapitreScreen extends StatelessWidget {
  const RevisionChapitreScreen({super.key, required this.chapitre});

  final Chapitre chapitre;

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final couleur = couleurChapitre(chapitre);
    final encre = texteSur(couleur);
    final modules = etat.modulesDuChapitre(chapitre);
    final fiches = modules.fold(0, (s, m) => s + m.fiches.length);
    final pourcentage = (etat.scoreChapitre(chapitre) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche de révision'),
        backgroundColor: couleur,
        foregroundColor: encre,
      ),
      // Un module par élément : les fiches ne sont construites qu'à
      // l'approche de l'écran, même sur un chapitre de onze modules.
      body: ListView.builder(
        itemCount: modules.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              decoration: BoxDecoration(
                color: couleur,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapitre.titre,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: encre, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$fiches fiches de ${modules.length} modules · '
                    '$pourcentage % des questions réussies',
                    style: theme.textTheme.bodyMedium?.copyWith(color: encre),
                  ),
                ],
              ),
            );
          }
          return _BlocModule(module: modules[index - 1], couleur: couleur);
        },
      ),
    );
  }
}

/// Un module dans la fiche de révision : son titre, puis ses fiches.
class _BlocModule extends StatelessWidget {
  const _BlocModule({required this.module, required this.couleur});

  final Module module;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le titre ouvre le module, pour enchaîner sur son quiz.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ModuleScreen(module: module)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: couleur.withValues(alpha: 0.15),
                    foregroundColor: couleur,
                    child: Icon(iconePourModule(module.id), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      module.titre,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Couronnes(nombre: etat.couronnes(module), taille: 13),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
          ),
          for (final fiche in module.fiches)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fiche.titre,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: couleur, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  TexteGlossaire(
                    texte: fiche.contenu,
                    termes: etat.glossaire,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: scheme.outlineVariant),
        ],
      ),
    );
  }
}
