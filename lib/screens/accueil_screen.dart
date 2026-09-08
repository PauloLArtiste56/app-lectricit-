import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/module.dart';
import '../widgets/couleurs_parcours.dart';
import '../widgets/module_card.dart';
import 'glossaire_screen.dart';
import 'module_screen.dart';
import 'outils_screen.dart';

/// Onglet Modules : tous les modules par thème, avec leur progression et un
/// champ de recherche. Pratique pour aller droit sur un sujet, sans suivre
/// le parcours.
class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  String _recherche = '';

  /// Minuscules sans accents, pour que « eclairage » trouve « Éclairage ».
  static String normaliser(String s) {
    const accents = 'àâäéèêëîïôöùûüç';
    const sans = 'aaaeeeeiioouuuc';
    final b = StringBuffer();
    for (final c in s.toLowerCase().characters) {
      final i = accents.indexOf(c);
      b.write(i < 0 ? c : sans[i]);
    }
    return b.toString();
  }

  List<Module> _filtrer(List<Module> modules) {
    final q = normaliser(_recherche.trim());
    if (q.isEmpty) return modules;
    return [
      for (final m in modules)
        if (normaliser(m.titre).contains(q) || normaliser(m.theme).contains(q)) m,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // `watch` : l'écran se redessine dès que la progression change.
    final etat = context.watch<AppState>();
    final modules = etat.pret ? _filtrer(etat.modules) : const <Module>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les modules'),
        actions: [
          IconButton(
            tooltip: 'Boîte à outils',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const OutilsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Glossaire',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GlossaireScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _recherche = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un module…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _recherche.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _recherche = ''),
                      ),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: switch (etat) {
        AppState(erreur: final e?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Impossible de charger le contenu :\n$e'),
            ),
          ),
        AppState(pret: false) =>
          const Center(child: CircularProgressIndicator()),
        _ when modules.isEmpty => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Aucun module ne correspond à « $_recherche ».'),
            ),
          ),
        _ => ListView.builder(
            padding: const EdgeInsets.all(12),
            // Un titre de section à chaque changement de thème.
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final precedent = index >= 1 ? modules[index - 1] : null;
              final nouveauTheme =
                  module.theme.isNotEmpty && module.theme != precedent?.theme;
              final chapitre = etat.chapitreDe(module);
              final carte = ModuleCard(
                module: module,
                questionsReussies: etat.questionsReussies(module),
                couleur: chapitre == null ? null : couleurChapitre(chapitre),
                couronnes: etat.couronnes(module),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModuleScreen(module: module),
                  ),
                ),
              );
              if (!nouveauTheme) return carte;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                    child: Text(
                      module.theme,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  carte,
                ],
              );
            },
          ),
      },
    );
  }
}
