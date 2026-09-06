import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Les petits sons de l'appli, un fichier WAV chacun dans `assets/sons/`
/// (générés par `tools/sons/generer_sons.py`).
enum Son { bonne, mauvaise, combo, fin }

/// Joue les sons via le plugin `audioplayers`. Un seul lecteur : un nouveau
/// son coupe le précédent, ce qui convient à des effets très courts.
class Sons {
  Sons({bool? actif}) : actif = actif ?? _lecteurDisponible;

  /// Sous `flutter test`, il n'y a pas de lecteur audio : on ne joue rien.
  static bool get _lecteurDisponible =>
      kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

  final bool actif;
  AudioPlayer? _lecteur;

  /// Sons demandés, dans l'ordre : sert aux tests.
  final List<Son> joues = [];

  Future<void> jouer(Son son) async {
    joues.add(son);
    if (!actif) return;
    try {
      _lecteur ??= AudioPlayer();
      await _lecteur!.play(AssetSource('sons/${son.name}.wav'), volume: 0.8);
    } catch (_) {
      // Pas de son possible (navigateur sans interaction, plugin absent) :
      // l'appli continue sans.
    }
  }
}
