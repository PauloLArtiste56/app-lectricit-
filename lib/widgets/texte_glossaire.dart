import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/terme.dart';

/// Un morceau de texte : simple, ou terme du glossaire (cliquable).
class Segment {
  const Segment(this.texte, [this.terme]);

  final String texte;
  final Terme? terme;
}

/// Texte dans lequel les termes du glossaire sont soulignés et cliquables :
/// un appui ouvre la définition en bas de l'écran. Seule la première
/// occurrence de chaque terme est marquée, pour ne pas surcharger le texte.
class TexteGlossaire extends StatefulWidget {
  const TexteGlossaire({super.key, required this.texte, required this.termes, this.style});

  final String texte;
  final List<Terme> termes;
  final TextStyle? style;

  /// Découpe [texte] en segments, fonction pure pour les tests. Les termes
  /// les plus longs sont cherchés d'abord (« conducteur de protection »
  /// avant « conducteur »), en entier et sans tenir compte de la casse.
  static List<Segment> decouper(String texte, List<Terme> termes) {
    if (termes.isEmpty || texte.isEmpty) return [Segment(texte)];
    final tries = List.of(termes)
      ..sort((a, b) => b.terme.length.compareTo(a.terme.length));
    // Position → terme trouvé, sans chevauchement.
    final trouves = <int, Terme>{};
    final occupe = List<bool>.filled(texte.length, false);
    for (final t in tries) {
      final motif = RegExp(
        '(?<!\\p{L})${RegExp.escape(t.terme)}(?!\\p{L})',
        caseSensitive: false,
        unicode: true,
      );
      for (final m in motif.allMatches(texte)) {
        if (occupe.sublist(m.start, m.end).any((o) => o)) continue;
        for (var i = m.start; i < m.end; i++) {
          occupe[i] = true;
        }
        trouves[m.start] = t;
        break; // première occurrence seulement
      }
    }
    final positions = trouves.keys.toList()..sort();
    final segments = <Segment>[];
    var curseur = 0;
    for (final p in positions) {
      final t = trouves[p]!;
      if (p > curseur) segments.add(Segment(texte.substring(curseur, p)));
      segments.add(Segment(texte.substring(p, p + t.terme.length), t));
      curseur = p + t.terme.length;
    }
    if (curseur < texte.length) segments.add(Segment(texte.substring(curseur)));
    return segments;
  }

  @override
  State<TexteGlossaire> createState() => _TexteGlossaireState();
}

class _TexteGlossaireState extends State<TexteGlossaire> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _montrer(Terme terme) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (contexte) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: Theme.of(contexte).colorScheme.primary),
                const SizedBox(width: 8),
                Text(terme.terme, style: Theme.of(contexte).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            Text(terme.definition,
                style: Theme.of(contexte).textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final couleur = Theme.of(context).colorScheme.primary;
    final segments = TexteGlossaire.decouper(widget.texte, widget.termes);
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final s in segments)
            if (s.terme case final t?)
              TextSpan(
                text: s.texte,
                style: TextStyle(
                  color: couleur,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: couleur,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: () {
                  final r = TapGestureRecognizer()..onTap = () => _montrer(t);
                  _recognizers.add(r);
                  return r;
                }(),
              )
            else
              TextSpan(text: s.texte),
        ],
      ),
    );
  }
}
