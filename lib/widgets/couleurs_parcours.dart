import 'package:flutter/material.dart';

import '../models/chapitre.dart';

/// Couleur d'un chapitre, lue depuis son champ `couleur` (`#RRGGBB`).
Color couleurChapitre(Chapitre chapitre) {
  final hex = chapitre.couleur.replaceFirst('#', '');
  final valeur = int.tryParse(hex, radix: 16) ?? 0x1565C0;
  return Color(0xFF000000 | valeur);
}

/// Version plus sombre d'une couleur, pour l'« épaisseur » des boutons.
Color assombrir(Color c, [double facteur = 0.75]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * facteur).clamp(0.0, 1.0)).toColor();
}

/// Blanc ou gris foncé selon la clarté du fond, pour rester lisible.
Color texteSur(Color fond) =>
    fond.computeLuminance() > 0.5 ? const Color(0xFF3C3C3C) : Colors.white;

/// Vert « réussi » et son ombre, communs à tout le parcours.
const Color vertReussi = Color(0xFF58CC02);
const Color vertReussiFonce = Color(0xFF46A302);
