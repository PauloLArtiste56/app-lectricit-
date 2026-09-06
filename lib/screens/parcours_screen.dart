import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/chapitre.dart';
import '../models/module.dart';
import '../widgets/banniere_chapitre.dart';
import '../widgets/carte_entrainement.dart';
import '../widgets/noeud_module.dart';
import 'module_screen.dart';

/// Écran Parcours : la carte d'entraînement puis le chemin des modules,
/// chapitre après chapitre, façon Duolingo.
class ParcoursScreen extends StatelessWidget {
  const ParcoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('ElecApp')),
      body: switch (etat) {
        AppState(erreur: final e?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Impossible de charger le contenu :\n$e'),
            ),
          ),
        AppState(pret: false) =>
          const Center(child: CircularProgressIndicator()),
        _ => SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CarteEntrainement(),
                ),
                for (final (i, chapitre) in etat.chapitres.indexed)
                  _SectionChapitre(numero: i + 1, chapitre: chapitre),
                const SizedBox(height: 24),
              ],
            ),
          ),
      },
    );
  }
}

/// Un chapitre : sa bannière puis ses modules disposés en serpentin.
class _SectionChapitre extends StatelessWidget {
  const _SectionChapitre({required this.numero, required this.chapitre});

  final int numero;
  final Chapitre chapitre;

  /// Hauteur réservée à chaque module sur le chemin (rond + titre).
  static const double pas = 116;

  /// Décalage horizontal maximal des ronds par rapport au centre.
  static const double amplitude = 120;

  /// Largeur d'un nœud (le titre s'étale sous le rond).
  static const double largeurNoeud = 160;

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final modules = etat.modulesDuChapitre(chapitre);
    final reussis = modules.where(etat.moduleReussi).length;

    return Column(
      children: [
        BanniereChapitre(
          numero: numero,
          chapitre: chapitre,
          reussis: reussis,
          total: modules.length,
        ),
        LayoutBuilder(
          builder: (context, contraintes) {
            final largeur = contraintes.maxWidth;
            final centres = [
              for (var i = 0; i < modules.length; i++)
                Offset(
                  largeur / 2 + amplitude * math.sin(i * math.pi / 3),
                  i * pas + NoeudModule.diametre / 2 + 8,
                ),
            ];
            return SizedBox(
              height: modules.length * pas + 16,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CheminPainter(
                        centres: centres,
                        couleur: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  for (final (i, module) in modules.indexed)
                    Positioned(
                      left: centres[i].dx - largeurNoeud / 2,
                      top: centres[i].dy - NoeudModule.diametre / 2 - 4,
                      width: largeurNoeud,
                      child: _noeud(context, etat, module),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _noeud(BuildContext context, AppState etat, Module module) {
    final reussies = etat.questionsReussies(module);
    final etatNoeud = etat.moduleReussi(module)
        ? EtatNoeud.reussi
        : reussies > 0
            ? EtatNoeud.enCours
            : EtatNoeud.aFaire;
    return NoeudModule(
      module: module,
      etat: etatNoeud,
      progression:
          module.nombreQuestions == 0 ? 0 : reussies / module.nombreQuestions,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ModuleScreen(module: module)),
      ),
    );
  }
}

/// Trace le chemin en pointillés qui relie les ronds d'un chapitre.
class _CheminPainter extends CustomPainter {
  const _CheminPainter({required this.centres, required this.couleur});

  final List<Offset> centres;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    if (centres.length < 2) return;
    final chemin = Path()..moveTo(centres.first.dx, centres.first.dy);
    for (var i = 1; i < centres.length; i++) {
      final a = centres[i - 1];
      final b = centres[i];
      // Une courbe en S entre deux ronds : plus doux qu'une ligne droite.
      final milieu = (a.dy + b.dy) / 2;
      chemin.cubicTo(a.dx, milieu, b.dx, milieu, b.dx, b.dy);
    }
    final pinceau = Paint()..color = couleur;
    // Des points réguliers le long de la courbe.
    for (final metrique in chemin.computeMetrics()) {
      for (var d = 0.0; d < metrique.length; d += 14) {
        final tangente = metrique.getTangentForOffset(d);
        if (tangente != null) canvas.drawCircle(tangente.position, 3, pinceau);
      }
    }
  }

  @override
  bool shouldRepaint(_CheminPainter ancien) =>
      ancien.centres != centres || ancien.couleur != couleur;
}
