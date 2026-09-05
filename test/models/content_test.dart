import 'dart:io';

import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que `assets/content.json` est bien formé et cohérent.
/// Ce test tourne sur le vrai fichier : il sert de garde-fou quand on
/// ajoute du contenu à la main.
void main() {
  final modules = ContentLoader.parserModules(
    File('assets/content.json').readAsStringSync(),
  );

  test('les modules sont présents, avec un thème', () {
    expect(modules.length, 39);
    expect(modules.every((m) => m.theme.isNotEmpty), isTrue);
    expect(modules.first.titre, "Grandeurs électriques et loi d'Ohm");
  });

  test('chaque module a des fiches et 20 questions', () {
    for (final module in modules) {
      expect(module.fiches, isNotEmpty, reason: '${module.id} sans fiche');
      expect(module.nombreQuestions, 20, reason: module.id);
    }
  });

  test('chaque question est cohérente', () {
    final idsVus = <String>{};
    for (final module in modules) {
      final idsFiches = module.fiches.map((f) => f.id).toSet();
      for (final q in module.questions) {
        expect(idsVus.add(q.id), isTrue, reason: 'id en double : ${q.id}');
        expect(idsFiches, contains(q.ficheId),
            reason: '${q.id} pointe vers une fiche inconnue : ${q.ficheId}');
        switch (q.type) {
          case TypeQuestion.qcm:
            expect(q.reponses.length, inInclusiveRange(3, 4),
                reason: '${q.id} doit avoir 3 ou 4 réponses');
            expect(q.bonne, inInclusiveRange(0, q.reponses.length - 1),
                reason: '${q.id} : index de bonne réponse hors limites');
          case TypeQuestion.ordre:
            expect(q.reponses.length, inInclusiveRange(3, 6),
                reason: '${q.id} doit avoir 3 à 6 étapes');
        }
        expect(q.explication, isNotEmpty, reason: '${q.id} sans explication');
      }
    }
  });

  test('chaque image de fiche existe dans assets/images', () {
    for (final module in modules) {
      for (final fiche in module.fiches) {
        expect(fiche.image, isNotNull, reason: '${fiche.id} sans image');
        expect(File('assets/images/${fiche.image}').existsSync(), isTrue,
            reason: 'image manquante : ${fiche.image}');
      }
    }
  });

  test('estBonne compare bien avec l\'index de la bonne réponse', () {
    final q = modules.first.questions.first;
    expect(q.estBonne(q.bonne), isTrue);
    expect(q.estBonne((q.bonne + 1) % q.reponses.length), isFalse);
  });

  test('un type de question inconnu est refusé clairement', () {
    expect(() => TypeQuestion.fromCode('devinette'), throwsFormatException);
  });
}
