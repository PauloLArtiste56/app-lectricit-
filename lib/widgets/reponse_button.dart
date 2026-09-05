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

/// Bouton d'une réponse de quiz, coloré en vert ou rouge après réponse.
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
    final (couleur, icone) = switch (etat) {
      EtatReponse.bonne => (Colors.green, Icons.check_circle),
      EtatReponse.mauvaise => (Colors.red, Icons.cancel),
      EtatReponse.neutre => (null, null),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // On garde les couleurs lisibles même quand le bouton est désactivé.
          foregroundColor: couleur,
          disabledForegroundColor: couleur ?? Theme.of(context).colorScheme.onSurface,
          backgroundColor: couleur?.withValues(alpha: 0.12),
          side: couleur == null ? null : BorderSide(color: couleur, width: 2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(texte)),
            if (icone != null) Icon(icone, color: couleur),
          ],
        ),
      ),
    );
  }
}
