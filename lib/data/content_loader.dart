import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/cas_pratique.dart';
import '../models/chapitre.dart';
import '../models/module.dart';
import '../models/terme.dart';

/// Charge le contenu pédagogique embarqué dans `assets/content.json`.
class ContentLoader {
  /// [bundle] permet d'injecter un autre AssetBundle dans les tests.
  ContentLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String cheminContenu = 'assets/content.json';
  static const String cheminParcours = 'assets/parcours.json';
  static const String cheminCas = 'assets/cas_pratiques.json';
  static const String cheminGlossaire = 'assets/glossaire.json';

  Future<List<Module>> chargerModules() async {
    // On lit les octets et on décode nous-mêmes : `loadString` passe par un
    // isolate au-delà de 50 Ko et garde un cache, deux comportements qui
    // bloquent les tests quand l'appli est rechargée plusieurs fois.
    return parserModules(await _lireTexte(cheminContenu));
  }

  /// Charge le découpage en chapitres du parcours (`assets/parcours.json`).
  Future<List<Chapitre>> chargerParcours() async {
    return parserParcours(await _lireTexte(cheminParcours));
  }

  /// Charge les cas pratiques (`assets/cas_pratiques.json`).
  Future<List<CasPratique>> chargerCasPratiques() async {
    return parserCasPratiques(await _lireTexte(cheminCas));
  }

  /// Charge le glossaire (`assets/glossaire.json`).
  Future<List<Terme>> chargerGlossaire() async {
    return parserGlossaire(await _lireTexte(cheminGlossaire));
  }

  Future<String> _lireTexte(String chemin) async {
    final octets = await _bundle.load(chemin);
    return utf8.decode(octets.buffer.asUint8List(
      octets.offsetInBytes,
      octets.lengthInBytes,
    ));
  }

  /// Transforme le texte JSON en liste de modules triés par `ordre`.
  /// Fonction pure (sans Flutter) pour être testable facilement.
  static List<Module> parserModules(String jsonTexte) {
    final data = jsonDecode(jsonTexte) as Map<String, dynamic>;
    final modules = (data['modules'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Module.fromJson)
        .toList();
    modules.sort((a, b) => a.ordre.compareTo(b.ordre));
    return modules;
  }

  /// Transforme le JSON des cas pratiques en liste, dans l'ordre du fichier.
  static List<CasPratique> parserCasPratiques(String jsonTexte) {
    final data = jsonDecode(jsonTexte) as Map<String, dynamic>;
    return (data['cas'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(CasPratique.fromJson)
        .toList();
  }

  /// Transforme le JSON du glossaire en liste de termes.
  static List<Terme> parserGlossaire(String jsonTexte) {
    final data = jsonDecode(jsonTexte) as Map<String, dynamic>;
    return (data['termes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Terme.fromJson)
        .toList();
  }

  /// Transforme le JSON du parcours en liste de chapitres, dans l'ordre du
  /// fichier.
  static List<Chapitre> parserParcours(String jsonTexte) {
    final data = jsonDecode(jsonTexte) as Map<String, dynamic>;
    return (data['chapitres'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Chapitre.fromJson)
        .toList();
  }
}
