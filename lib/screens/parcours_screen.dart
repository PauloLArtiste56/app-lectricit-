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
import 'parametres_screen.dart';

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
  final _controleur = ScrollController();

  /// Mesure la carte d'entraînement (sa hauteur dépend du texte) pour
  /// calculer la position des modules en dessous.
  final _cleCarte = GlobalKey();
  double _hauteurCarte = 0;
  bool _aDefile = false;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  /// Position de défilement qui place le module en cours au quart de
  /// l'écran. Les chapitres ont des hauteurs connues (bannière fixe, un
  /// « pas » par module) : pas besoin que le nœud soit construit.
  double? _offsetDuCourant(AppState etat) {
    final courant = etat.moduleCourant;
    if (courant == null) return null;
    var y = _hauteurCarte;
    for (final chapitre in etat.chapitres) {
      final modules = etat.modulesDuChapitre(chapitre);
      final i = modules.indexOf(courant);
      if (i >= 0) {
        y += BanniereChapitre.hauteurTotale + i * _SectionChapitre.pas;
        break;
      }
      y += _SectionChapitre.hauteurPour(modules.length);
    }
    if (!_controleur.hasClients) return null;
    final position = _controleur.position;
    final cible = y - position.viewportDimension * 0.25;
    return cible.clamp(0.0, position.maxScrollExtent);
  }

  void _allerAuCourant({bool anime = true}) {
    final boite = _cleCarte.currentContext?.findRenderObject() as RenderBox?;
    if (boite != null) _hauteurCarte = boite.size.height;
    final cible = _offsetDuCourant(context.read<AppState>());
    if (cible == null) return;
    if (anime) {
      _controleur.animateTo(cible,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      _controleur.jumpTo(cible);
    }
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
      appBar: AppBar(
        title: const Text('ElecApp'),
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ParametresScreen()),
            ),
          ),
        ],
      ),
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
        // ListView.builder : seuls les chapitres visibles sont construits
        // et dessinés, au lieu des 100 modules d'un coup.
        _ => ListView.builder(
            controller: _controleur,
            itemCount: etat.chapitres.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  key: _cleCarte,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const CarteEntrainement(),
                );
              }
              if (index == etat.chapitres.length + 1) {
                return const SizedBox(height: 24);
              }
              return _SectionChapitre(
                numero: index,
                chapitre: etat.chapitres[index - 1],
              );
            },
          ),
      },
    );
  }
}

/// Un chapitre : fond teinté, bannière, puis ses modules en serpentin avec
/// les illustrations et, s'il contient le module en cours, la mascotte.
class _SectionChapitre extends StatelessWidget {
  const _SectionChapitre({required this.numero, required this.chapitre});

  final int numero;
  final Chapitre chapitre;

  /// Hauteur totale d'un chapitre de [nbModules] modules.
  static double hauteurPour(int nbModules) =>
      BanniereChapitre.hauteurTotale + nbModules * pas + 30;

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

    // RepaintBoundary : pendant le défilement, le chapitre déjà dessiné est
    // réutilisé tel quel au lieu d'être repeint à chaque image.
    return RepaintBoundary(
        child: ColoredBox(
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
                        isComplex: true,
                        willChange: false,
                        painter: _CheminPainter(
                          centres: centres,
                          couleur: couleur.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    ..._decors(centres, largeur, indexCourant),
                    for (final (i, module) in modules.indexed)
                      Positioned(
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
    ));
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
