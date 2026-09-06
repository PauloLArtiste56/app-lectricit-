import 'dart:io';

import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les cas pratiques sont valides et rattachés à des modules existants', () {
    final cas = ContentLoader.parserCasPratiques(
        File('assets/cas_pratiques.json').readAsStringSync());
    final modules = ContentLoader.parserModules(
        File('assets/content.json').readAsStringSync());
    final idsModules = modules.map((m) => m.id).toSet();

    expect(cas.length, greaterThanOrEqualTo(10));
    expect(cas.map((c) => c.id).toSet().length, cas.length, reason: 'ids uniques');
    for (final c in cas) {
      expect(c.titre, isNotEmpty);
      expect(c.contexte.length, greaterThan(40), reason: c.id);
      expect(idsModules, contains(c.moduleId), reason: c.id);
      expect(c.etapes.length, greaterThanOrEqualTo(3), reason: c.id);
      for (final e in c.etapes) {
        expect(e.type, TypeQuestion.qcm);
        expect(e.id, startsWith('cas_${c.id}_'));
        expect(e.reponses.length, inInclusiveRange(3, 4), reason: e.id);
        expect(e.bonne, inInclusiveRange(0, e.reponses.length - 1), reason: e.id);
        expect(e.explication, isNotEmpty, reason: e.id);
      }
    }
  });
}
