import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/fiche.dart';
import '../models/module.dart';
import '../widgets/bouton_relief.dart';
import '../widgets/couleurs_parcours.dart';
import '../widgets/texte_glossaire.dart';
import 'quiz_screen.dart';

/// Écran Fiche : titre, texte, image optionnelle, et "Passer au quiz".
/// Ouvrir la fiche la marque comme lue.
class FicheScreen extends StatefulWidget {
  const FicheScreen({
    super.key,
    required this.module,
    required this.index,
    this.depuisQuiz = false,
  });

  final Module module;

  /// Position de la fiche dans `module.fiches`.
  final int index;

  /// Ouverte depuis une question ratée : on propose "Retour au quiz"
  /// au lieu de "Passer au quiz".
  final bool depuisQuiz;

  @override
  State<FicheScreen> createState() => _FicheScreenState();
}

class _FicheScreenState extends State<FicheScreen> {
  @override
  void initState() {
    super.initState();
    // On attend la fin du premier dessin pour ne pas modifier l'état
    // pendant la construction de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().marquerFicheLue(widget.module, _fiche.id);
    });
  }

  Fiche get _fiche => widget.module.fiches[widget.index];
  bool get _estDerniere => widget.index == widget.module.fiches.length - 1;

  void _ficheSuivante() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            FicheScreen(module: widget.module, index: widget.index + 1),
      ),
    );
  }

  void _passerAuQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(module: widget.module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fiche = _fiche;
    final etat = context.read<AppState>();
    final chapitre = etat.chapitreDe(widget.module);
    final couleur = chapitre == null ? scheme.primary : couleurChapitre(chapitre);
    final nombre = widget.module.fiches.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche ${widget.index + 1} / $nombre'),
        // Un petit stepper sous le titre : une barre par fiche.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (var i = 0; i < nombre; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= widget.index ? couleur : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            fiche.titre,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: couleur,
            ),
          ),
          const SizedBox(height: 16),
          if (fiche.image != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/images/${fiche.image}'),
            ),
            const SizedBox(height: 20),
          ],
          // Les termes du glossaire sont soulignés : un appui ouvre la définition.
          TexteGlossaire(
            texte: fiche.contenu,
            termes: etat.glossaire,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 32),
          if (widget.depuisQuiz)
            BoutonRelief(
              label: 'Retour au quiz',
              icone: Icons.arrow_back,
              couleur: couleur,
              onPressed: () => Navigator.of(context).pop(),
            )
          else ...[
            if (!_estDerniere) ...[
              BoutonRelief(
                label: 'Fiche suivante',
                icone: Icons.arrow_forward,
                couleur: couleur,
                onPressed: _ficheSuivante,
              ),
              const SizedBox(height: 10),
              BoutonRelief(
                label: 'Passer au quiz',
                icone: Icons.quiz,
                couleur: couleur,
                secondaire: true,
                onPressed: _passerAuQuiz,
              ),
            ] else
              BoutonRelief(
                label: 'Passer au quiz',
                icone: Icons.quiz,
                couleur: couleur,
                onPressed: _passerAuQuiz,
              ),
          ],
        ],
      ),
    );
  }
}
