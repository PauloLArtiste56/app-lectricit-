import 'package:flutter/material.dart';

/// Apparence d'une réponse selon l'état du quiz.
enum EtatReponse {
  /// Pas encore répondu, ou réponse ni choisie ni correcte.
  neutre,

  /// C'est la bonne réponse (affichée en vert après avoir répondu).
  bonne,

  /// Réponse choisie par l'utilisateur et fausse (en rouge).
  mauvaise,
}

/// Carte d'une réponse de quiz, en léger relief, colorée en vert ou rouge
/// après réponse.
class ReponseButton extends StatelessWidget {
  const ReponseButton({
    super.key,
    required this.texte,
    required this.etat,
    this.onPressed,
  });

  final String texte;
  final EtatReponse etat;

  /// `null` désactive le bouton (une fois qu'on a répondu).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color? couleur, IconData? icone) = switch (etat) {
      EtatReponse.bonne => (Colors.green.shade600, Icons.check_circle),
      EtatReponse.mauvaise => (Colors.red.shade600, Icons.cancel),
      EtatReponse.neutre => (null, null),
    };
    final bord = couleur ?? scheme.outlineVariant;
    // Teinte opaque : sinon l'épaisseur (ombre pleine) transparaît.
    final fond = couleur == null
        ? scheme.surface
        : Color.alphaBlend(couleur.withValues(alpha: 0.14), scheme.surface);
    final encre = couleur ?? scheme.onSurface;
    // Une réponse ni choisie ni correcte s'efface une fois qu'on a répondu.
    final estompee = onPressed == null && etat == EtatReponse.neutre;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Opacity(
        opacity: estompee ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: fond,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bord, width: 2),
                // L'épaisseur sous la carte.
                boxShadow: [BoxShadow(color: bord, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      texte,
                      style: TextStyle(
                        color: encre,
                        fontSize: 16,
                        fontWeight: couleur == null ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                  ),
                  if (icone != null) ...[
                    const SizedBox(width: 8),
                    Icon(icone, color: couleur),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
