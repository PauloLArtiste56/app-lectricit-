import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/chapitre.dart';
import '../models/module.dart';
import '../widgets/banniere_chapitre.dart';
import '../widgets/carte_entrainement.dart';
import '../widgets/couleurs_parcours.dart';
import '../widgets/noeud_module.dart';
import 'module_screen.dart';

/// Écran Parcours : la carte d'entraînement puis le chemin des modules,
/// chapitre après chapitre, façon Duolingo : boutons en relief, cadenas,
/// illustrations le long du chemin, mascotte « pile » sur le module en cours.
/// À l'ouverture, l'écran défile jusqu'au module en cours.
class ParcoursScreen extends StatefulWidget {
  const ParcoursScreen({super.key});

  @override
  State<ParcoursScreen> createState() => _ParcoursScreenState();
}

class _ParcoursScreenState extends State<ParcoursScreen> {
  /// Repère le nœud du module en cours pour pouvoir défiler jusqu'à lui.
  final _cleCourant = GlobalKey();
  bool _aDefile = false;

  void _allerAuCourant({bool anime = true}) {
    final ctx = _cleCourant.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.25,
      duration: anime ? const Duration(milliseconds: 500) : Duration.zero,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();

    // Premier affichage du chemin : on se place sur le module en cours,
    // une fois la page dessinée.
    if (etat.pret && !_aDefile) {
      _aDefile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _allerAuCourant(anime: false);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ElecApp')),
      floatingActionButton: etat.pret && etat.moduleCourant != null
          ? FloatingActionButton.small(
              tooltip: 'Aller au module en cours',
              onPressed: _allerAuCourant,
              child: const Icon(Icons.my_location),
            )
          : null,
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
                  _SectionChapitre(
                    numero: i + 1,
                    chapitre: chapitre,
                    cleCourant: _cleCourant,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
      },
    );
  }
}

/// Un chapitre : fond teinté, bannière, puis ses modules en serpentin avec
/// les illustrations et, s'il contient le module en cours, la mascotte.
class _SectionChapitre extends StatelessWidget {
  const _SectionChapitre({
    required this.numero,
    required this.chapitre,
    required this.cleCourant,
  });

  final int numero;
  final Chapitre chapitre;

  /// Posée sur le nœud du module en cours, s'il est dans ce chapitre.
  final GlobalKey cleCourant;

  /// Hauteur réservée à chaque module sur le chemin (bulle + rond + titre).
  static const double pas = 192;

  /// Décalage horizontal maximal des ronds par rapport au centre.
  static const double amplitude = 105;

  /// Largeur d'un nœud (le titre s'étale sous le rond).
  static const double largeurNoeud = 150;

  static const double tailleDecor = 96;
  static const double largeurPile = 64;
  static const double hauteurPile = 86;

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final sombre = theme.brightness == Brightness.dark;
    final couleur = couleurChapitre(chapitre);
    final modules = etat.modulesDuChapitre(chapitre);
    final reussis = modules.where(etat.moduleReussi).length;
    final courant = etat.moduleCourant;
    final indexCourant = courant == null ? -1 : modules.indexOf(courant);

    return ColoredBox(
      // Le fond du chapitre : sa couleur, très diluée.
      color: couleur.withValues(alpha: sombre ? 0.16 : 0.10),
      child: Column(
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
              // Centre du disque de chaque module.
              final centres = [
                for (var i = 0; i < modules.length; i++)
                  Offset(
                    largeur / 2 + amplitude * math.sin(i * math.pi / 3),
                    i * pas +
                        NoeudModule.hauteurBulle +
                        NoeudModule.diametre / 2 +
                        6,
                  ),
              ];
              return SizedBox(
                height: modules.length * pas + 30,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CheminPainter(
                          centres: centres,
                          couleur: couleur.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    ..._decors(centres, largeur, indexCourant),
                    for (final (i, module) in modules.indexed)
                      Positioned(
                        key: i == indexCourant ? cleCourant : null,
                        left: centres[i].dx - largeurNoeud / 2,
                        top: i * pas,
                        width: largeurNoeud,
                        child: _noeud(context, etat, module, couleur,
                            courant: i == indexCourant),
                      ),
                    if (indexCourant >= 0)
                      _mascotte(centres[indexCourant], largeur,
                          reussis / math.max(modules.length, 1)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Côté opposé au rond : à gauche si le rond est à droite, et inversement.
  static double _enFace(Offset centre, double largeur, double taille) {
    final aDroite = centre.dx >= largeur / 2;
    return aDroite
        ? centre.dx - amplitude * 1.55 - taille / 2
        : centre.dx + amplitude * 1.55 - taille / 2;
  }

  /// Une illustration tous les trois modules, en face du rond, sauf là où
  /// se trouve la mascotte.
  List<Widget> _decors(List<Offset> centres, double largeur, int indexCourant) {
    if (chapitre.decors.isEmpty) return const [];
    final decors = <Widget>[];
    var k = 0;
    for (var i = 1; i < centres.length; i += 3) {
      if (i == indexCourant) continue;
      final nom = chapitre.decors[k++ % chapitre.decors.length];
      decors.add(Positioned(
        left: _enFace(centres[i], largeur, tailleDecor).clamp(4.0, largeur - tailleDecor - 4),
        top: centres[i].dy - tailleDecor / 2,
        width: tailleDecor,
        height: tailleDecor,
        child: Image.asset('assets/images/decors/$nom.png',
            filterQuality: FilterQuality.medium),
      ));
    }
    return decors;
  }

  /// La pile mascotte, posée en face du module en cours. Sa charge suit
  /// l'avancement du chapitre. Elle glisse quand le module en cours change.
  Widget _mascotte(Offset centre, double largeur, double avancement) {
    final niveau = (avancement * 3).round().clamp(0, 3);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      left: _enFace(centre, largeur, largeurPile).clamp(4.0, largeur - largeurPile - 4),
      top: centre.dy - hauteurPile / 2,
      width: largeurPile,
      height: hauteurPile,
      child: Image.asset('assets/images/decors/pile_$niveau.png',
          filterQuality: FilterQuality.medium),
    );
  }

  Widget _noeud(BuildContext context, AppState etat, Module module,
      Color couleur, {required bool courant}) {
    final reussies = etat.questionsReussies(module);
    final deverrouille = etat.moduleDeverrouille(module);
    final etatNoeud = etat.moduleReussi(module)
        ? EtatNoeud.reussi
        : !deverrouille
            ? EtatNoeud.verrouille
            : reussies > 0
                ? EtatNoeud.enCours
                : EtatNoeud.aFaire;
    return NoeudModule(
      module: module,
      etat: etatNoeud,
      couleur: couleur,
      courant: courant,
      progression:
          module.nombreQuestions == 0 ? 0 : reussies / module.nombreQuestions,
      onTap: () {
        if (deverrouille) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => ModuleScreen(module: module)),
          );
          return;
        }
        final avant = etat.moduleAvant(module);
        final seuil = avant == null
            ? 0
            : (avant.nombreQuestions * AppState.seuilReussite).ceil();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(avant == null
                ? 'Module verrouillé.'
                : 'Réussis d\'abord « ${avant.titre} » ($seuil questions sur ${avant.nombreQuestions}).'),
          ));
      },
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
      for (var d = 0.0; d < metrique.length; d += 16) {
        final tangente = metrique.getTangentForOffset(d);
        if (tangente != null) canvas.drawCircle(tangente.position, 3.5, pinceau);
      }
    }
  }

  @override
  bool shouldRepaint(_CheminPainter ancien) =>
      ancien.centres != centres || ancien.couleur != couleur;
}
