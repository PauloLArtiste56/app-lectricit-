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
    // On lit les octets et on décode nous-mêmes : `loadString` passe par un
    // isolate au-delà de 50 Ko et garde un cache, deux comportements qui
    // bloquent les tests quand l'appli est rechargée plusieurs fois.
    final octets = await _bundle.load(cheminContenu);
    final texte = utf8.decode(octets.buffer.asUint8List(
      octets.offsetInBytes,
      octets.lengthInBytes,
    ));
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
