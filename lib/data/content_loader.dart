import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/module.dart';

/// Charge le contenu pédagogique embarqué dans `assets/content.json`.
class ContentLoader {
  /// [bundle] permet d'injecter un autre AssetBundle dans les tests.
  ContentLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String cheminContenu = 'assets/content.json';

  Future<List<Module>> chargerModules() async {
    final texte = await _bundle.loadString(cheminContenu);
    return parserModules(texte);
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
}
