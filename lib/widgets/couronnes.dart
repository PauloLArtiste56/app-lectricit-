import 'package:flutter/material.dart';

/// Rangée de trois couronnes de maîtrise : dorées pour celles gagnées,
/// grises pour les autres.
class Couronnes extends StatelessWidget {
  const Couronnes({super.key, required this.nombre, this.taille = 16, this.couleurVide});

  /// Couronnes gagnées, de 0 à 3.
  final int nombre;
  final double taille;

  /// Couleur des couronnes non gagnées (gris clair par défaut).
  final Color? couleurVide;

  static const int maximum = 3;
  static const Color or = Color(0xFFFFC800);

  @override
  Widget build(BuildContext context) {
    final vide = couleurVide ?? Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < maximum; i++)
          Padding(
            padding: EdgeInsets.only(right: i < maximum - 1 ? 2 : 0),
            child: Couronne(taille: taille, couleur: i < nombre ? or : vide),
          ),
      ],
    );
  }
}

/// Une couronne dessinée à la main (Material n'en propose pas).
class Couronne extends StatelessWidget {
  const Couronne({super.key, required this.taille, required this.couleur});

  final double taille;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(taille, taille * 0.85),
      painter: _PeintreCouronne(couleur),
    );
  }
}

class _PeintreCouronne extends CustomPainter {
  const _PeintreCouronne(this.couleur);

  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final peinture = Paint()..color = couleur;
    // Trois pointes puis la base.
    final chemin = Path()
      ..moveTo(0, h * 0.95)
      ..lineTo(0, h * 0.3)
      ..lineTo(w * 0.27, h * 0.58)
      ..lineTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.73, h * 0.58)
      ..lineTo(w, h * 0.3)
      ..lineTo(w, h * 0.95)
      ..close();
    canvas.drawPath(chemin, peinture);
    // Un liseré plus foncé pour la base.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.78, w, h * 0.17),
      Paint()..color = Color.alphaBlend(Colors.black.withValues(alpha: 0.18), couleur),
    );
  }

  @override
  bool shouldRepaint(_PeintreCouronne ancien) => ancien.couleur != couleur;
}
