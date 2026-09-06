import 'package:flutter/material.dart';

import '../models/module.dart';
import 'couleurs_parcours.dart';
import 'module_icon.dart';

/// État d'un module sur le chemin du parcours.
enum EtatNoeud { verrouille, aFaire, enCours, reussi }

/// Un bouton « pièce » du parcours, en relief comme dans Duolingo : l'icône
/// du module, une ombre épaisse dessous, le titre en dessous, et une bulle
/// « Commencer » au-dessus du module en cours.
class NoeudModule extends StatefulWidget {
  const NoeudModule({
    super.key,
    required this.module,
    required this.etat,
    required this.progression,
    required this.couleur,
    this.courant = false,
    this.onTap,
  });

  final Module module;
  final EtatNoeud etat;

  /// Entre 0 et 1 : part des questions réussies.
  final double progression;

  /// Couleur du chapitre.
  final Color couleur;

  /// Le module à faire maintenant : bulle et anneau autour.
  final bool courant;
  final VoidCallback? onTap;

  /// Diamètre du disque, utilisé aussi pour tracer le chemin entre les ronds.
  static const double diametre = 72;

  /// Épaisseur visible sous le disque.
  static const double relief = 8;

  /// Hauteur réservée à la bulle au-dessus du disque (toujours réservée
  /// pour que les ronds restent alignés).
  static const double hauteurBulle = 54;

  @override
  State<NoeudModule> createState() => _NoeudModuleState();
}

class _NoeudModuleState extends State<NoeudModule>
    with SingleTickerProviderStateMixin {
  // Petit va-et-vient vertical de la bulle « Commencer », quelques
  // allers-retours puis repos (une animation sans fin empêcherait aussi
  // les tests de se stabiliser).
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true, count: 8);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final etat = widget.etat;

    final (Color dessus, Color dessous, Color encre, IconData icone) =
        switch (etat) {
      EtatNoeud.reussi => (vertReussi, vertReussiFonce, Colors.white, Icons.check),
      EtatNoeud.verrouille => (
          const Color(0xFFE5E5E5),
          const Color(0xFFB7B7B7),
          const Color(0xFFAFAFAF),
          Icons.lock
        ),
      _ => (
          widget.couleur,
          assombrir(widget.couleur),
          texteSur(widget.couleur),
          iconePourModule(widget.module.id)
        ),
    };

    final disque = SizedBox(
      width: NoeudModule.diametre + 12,
      height: NoeudModule.diametre + NoeudModule.relief + 12,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Anneau autour du module en cours.
          if (widget.courant)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: dessous.withValues(alpha: 0.35),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          // L'épaisseur, décalée vers le bas.
          Positioned(
            top: 6 + NoeudModule.relief,
            child: _Disque(couleur: dessous),
          ),
          Positioned(
            top: 6,
            child: _Disque(
              couleur: dessus,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (etat == EtatNoeud.enCours)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        value: widget.progression,
                        strokeWidth: 5,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  Icon(icone, color: encre, size: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: NoeudModule.hauteurBulle,
            // RepaintBoundary : l'animation de la bulle ne redessine
            // qu'elle-même, pas tout le parcours.
            child: widget.courant
                ? RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (_, enfant) => Transform.translate(
                        offset: Offset(0, -4 * _anim.value),
                        child: enfant,
                      ),
                      // Réduite si la police est plus grande que prévu.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _Bulle(couleur: widget.couleur),
                      ),
                    ),
                  )
                : null,
          ),
          disque,
          const SizedBox(height: 2),
          Text(
            widget.module.titre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: etat == EtatNoeud.verrouille
                  ? scheme.outline
                  : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Disque extends StatelessWidget {
  const _Disque({required this.couleur, this.child});

  final Color couleur;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: NoeudModule.diametre,
      height: NoeudModule.diametre,
      child: DecoratedBox(
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

/// Bulle « Commencer » avec sa petite pointe vers le bas.
class _Bulle extends StatelessWidget {
  const _Bulle({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: couleur, width: 2),
          ),
          child: Text(
            'COMMENCER',
            style: TextStyle(
              color: couleur,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(16, 8),
          painter: _PointePainter(couleur: couleur, fond: scheme.surface),
        ),
      ],
    );
  }
}

class _PointePainter extends CustomPainter {
  const _PointePainter({required this.couleur, required this.fond});

  final Color couleur;
  final Color fond;

  @override
  void paint(Canvas canvas, Size size) {
    final chemin = Path()
      ..moveTo(0, -2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -2)
      ..close();
    canvas.drawPath(chemin, Paint()..color = couleur);
    final interieur = Path()
      ..moveTo(3, -2)
      ..lineTo(size.width / 2, size.height - 3)
      ..lineTo(size.width - 3, -2)
      ..close();
    canvas.drawPath(interieur, Paint()..color = fond);
  }

  @override
  bool shouldRepaint(_PointePainter ancien) =>
      ancien.couleur != couleur || ancien.fond != fond;
}
