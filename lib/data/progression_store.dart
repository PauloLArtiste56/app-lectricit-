import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progression.dart';

/// Lit et écrit la progression sur l'appareil (via `shared_preferences`).
/// Tout est stocké sous une seule clé, en JSON.
class ProgressionStore {
  static const String _cle = 'progression';

  Future<Progression> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final texte = prefs.getString(_cle);
    if (texte == null) return Progression();
    try {
      return Progression.fromJson(jsonDecode(texte) as Map<String, dynamic>);
    } on FormatException {
      // Données illisibles (ancienne version, corruption) : on repart de zéro
      // plutôt que de bloquer l'appli.
      return Progression();
    }
  }

  Future<void> sauvegarder(Progression progression) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, jsonEncode(progression.toJson()));
  }

  Future<void> effacer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cle);
  }
}
