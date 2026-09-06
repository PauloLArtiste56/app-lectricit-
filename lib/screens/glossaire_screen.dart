import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/terme.dart';

/// Glossaire : tous les termes du lexique, avec un champ de recherche.
class GlossaireScreen extends StatefulWidget {
  const GlossaireScreen({super.key});

  @override
  State<GlossaireScreen> createState() => _GlossaireScreenState();
}

class _GlossaireScreenState extends State<GlossaireScreen> {
  String _recherche = '';

  /// Minuscules sans accents, pour une recherche tolérante.
  static String normaliser(String s) {
    const avec = 'àâäéèêëîïôöùûüç';
    const sans = 'aaaeeeeiioouuuc';
    final b = StringBuffer();
    for (final c in s.toLowerCase().characters) {
      final i = avec.indexOf(c);
      b.write(i >= 0 ? sans[i] : c);
    }
    return b.toString();
  }

  List<Terme> _filtrer(List<Terme> termes) {
    final q = normaliser(_recherche.trim());
    final tries = List.of(termes)
      ..sort((a, b) => normaliser(a.terme).compareTo(normaliser(b.terme)));
    if (q.isEmpty) return tries;
    return [
      for (final t in tries)
        if (normaliser(t.terme).contains(q) || normaliser(t.definition).contains(q)) t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final termes = _filtrer(etat.glossaire);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glossaire'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _recherche = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un terme…',
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
      body: termes.isEmpty
          ? Center(child: Text('Aucun terme ne correspond à « $_recherche ».'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: termes.length,
              itemBuilder: (_, i) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(termes[i].terme,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(termes[i].definition,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
