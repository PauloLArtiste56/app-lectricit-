import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/parametres.dart';
import '../models/progression.dart';

/// Lit et écrit la progression et les paramètres sur l'appareil (via
/// `shared_preferences`). Chacun est stocké sous une clé, en JSON.
class ProgressionStore {
  static const String _cle = 'progression';
  static const String _cleParametres = 'parametres';

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

  Future<Parametres> chargerParametres() async {
    final prefs = await SharedPreferences.getInstance();
    final texte = prefs.getString(_cleParametres);
    if (texte == null) return const Parametres();
    try {
      return Parametres.fromJson(jsonDecode(texte) as Map<String, dynamic>);
    } on FormatException {
      return const Parametres();
    }
  }

  Future<void> sauvegarderParametres(Parametres parametres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleParametres, jsonEncode(parametres.toJson()));
  }
}
