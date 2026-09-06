import 'dart:io';

import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/models/terme.dart';
import 'package:elecapp/widgets/texte_glossaire.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le glossaire est valide : termes uniques et définitions fournies', () {
    final termes = ContentLoader.parserGlossaire(
        File('assets/glossaire.json').readAsStringSync());
    expect(termes.length, greaterThanOrEqualTo(60));
    expect(termes.map((t) => t.terme.toLowerCase()).toSet().length, termes.length);
    for (final t in termes) {
      expect(t.terme.trim(), t.terme, reason: 'pas d\'espace autour de « ${t.terme} »');
      expect(t.definition.length, greaterThan(40), reason: t.terme);
    }
  });

  test('decouper marque la première occurrence de chaque terme, le plus long d\'abord', () {
    const termes = [
      Terme(terme: 'Terre', definition: 'a'),
      Terme(terme: 'Prise de terre', definition: 'b'),
      Terme(terme: 'Tension', definition: 'c'),
    ];
    final segments = TexteGlossaire.decouper(
      'La prise de terre évacue le courant vers la terre. Sans tension, pas de tension.',
      termes,
    );
    final marques = [for (final s in segments) if (s.terme != null) s.texte];
    // « prise de terre » gagne sur « terre » ; « terre » seule est marquée
    // à sa première occurrence libre ; « tension » une seule fois.
    expect(marques, ['prise de terre', 'terre', 'tension']);
    expect(segments.map((s) => s.texte).join(), startsWith('La prise de terre'));
    // Un mot qui contient le terme n'est pas marqué (« terrestre »).
    final autres = TexteGlossaire.decouper('Un terrestre sans Terre.', termes);
    expect([for (final s in autres) if (s.terme != null) s.texte], ['Terre']);
    // Sans terme, le texte est rendu tel quel.
    expect(TexteGlossaire.decouper('Bonjour', const []).single.texte, 'Bonjour');
  });
}
