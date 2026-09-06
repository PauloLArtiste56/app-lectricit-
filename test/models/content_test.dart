import 'dart:io';

import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/models/question.dart';
import 'package:elecapp/models/tenue.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vérifie que `assets/content.json` est bien formé et cohérent.
/// Ce test tourne sur le vrai fichier : il sert de garde-fou quand on
/// ajoute du contenu à la main.
void main() {
  final modules = ContentLoader.parserModules(
    File('assets/content.json').readAsStringSync(),
  );

  test('les modules sont présents, avec un thème', () {
    expect(modules.length, 100);
    expect(modules.every((m) => m.theme.isNotEmpty), isTrue);
    expect(modules.first.titre, "Grandeurs électriques et loi d'Ohm");
  });

  test('chaque module a des fiches et au moins 20 questions', () {
    for (final module in modules) {
      expect(module.fiches, isNotEmpty, reason: '${module.id} sans fiche');
      expect(module.nombreQuestions, greaterThanOrEqualTo(20), reason: module.id);
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
          case TypeQuestion.image:
            expect(q.reponses.length, inInclusiveRange(3, 4),
                reason: '${q.id} doit avoir 3 ou 4 réponses');
            expect(q.bonne, inInclusiveRange(0, q.reponses.length - 1),
                reason: '${q.id} : index de bonne réponse hors limites');
            expect(q.image, isNotNull, reason: '${q.id} sans image');
            expect(File('assets/images/${q.image}').existsSync(), isTrue,
                reason: '${q.id} : image introuvable ${q.image}');
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

  test('le parcours range chaque module dans un chapitre, une seule fois', () {
    final modules = ContentLoader.parserModules(
        File('assets/content.json').readAsStringSync());
    final chapitres = ContentLoader.parserParcours(
        File('assets/parcours.json').readAsStringSync());
    expect(chapitres.length, 10);
    final ids = [for (final c in chapitres) ...c.modulesIds];
    expect(ids.toSet().length, ids.length, reason: 'module en double');
    expect(ids.toSet(), modules.map((m) => m.id).toSet());
    for (final c in chapitres) {
      expect(c.titre, isNotEmpty);
      expect(c.modulesIds, isNotEmpty);
      expect(c.couleur, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      expect(c.decors, isNotEmpty);
      for (final d in c.decors) {
        expect(File('assets/images/decors/$d.png').existsSync(), isTrue,
            reason: 'décor manquant : $d');
      }
    }
    for (var n = 0; n <= 3; n++) {
      expect(File('assets/images/decors/pile_$n.png').existsSync(), isTrue);
    }
    for (final t in Tenue.toutes) {
      expect(File('assets/images/${t.image}').existsSync(), isTrue, reason: t.id);
    }
  });

  test('le contenu compte des questions avec image', () {
    final images = [
      for (final m in modules)
        for (final q in m.questions)
          if (q.type == TypeQuestion.image) q,
    ];
    expect(images.length, greaterThanOrEqualTo(15));
  });
}
