import 'package:flutter/material.dart';

import '../data/content_loader.dart';
import '../models/module.dart';
import '../widgets/module_card.dart';

/// Écran d'accueil : la liste des modules avec leur progression.
class AccueilScreen extends StatefulWidget {
  /// [loader] permet d'injecter un chargeur de contenu dans les tests.
  const AccueilScreen({super.key, this.loader});

  final ContentLoader? loader;

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  // Le Future est créé une seule fois (dans initState) pour ne pas
  // recharger le JSON à chaque reconstruction du widget.
  late final Future<List<Module>> _modules;

  @override
  void initState() {
    super.initState();
    _modules = (widget.loader ?? ContentLoader()).chargerModules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ElecApp')),
      body: FutureBuilder<List<Module>>(
        future: _modules,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Impossible de charger le contenu :\n${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final modules = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return ModuleCard(
                module: module,
                // La progression réelle arrivera à l'étape 4 (sauvegarde locale).
                questionsReussies: 0,
                onTap: () {
                  // Étape 2 : ouvrir le module (fiches puis quiz).
                },
              );
            },
          );
        },
      ),
    );
  }
}
