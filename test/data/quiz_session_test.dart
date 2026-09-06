import 'package:elecapp/data/quiz_session.dart';
import 'package:elecapp/models/question.dart';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

Question _q(String id, int bonne) => Question(
      id: id,
      ficheId: 'f',
      type: TypeQuestion.qcm,
      enonce: 'Énoncé $id',
      reponses: const ['a', 'b', 'c'],
      bonne: bonne,
      explication: 'Parce que.',
    );

void main() {
  test('déroulé complet : score et questions ratées', () {
    final session = QuizSession([_q('q1', 0), _q('q2', 1), _q('q3', 2)], melanger: false);

    expect(session.numero, 1);
    expect(session.total, 3);
    expect(session.aRepondu, isFalse);

    session.repondre(0); // juste
    expect(session.aRepondu, isTrue);
    expect(session.score, 1);

    session.suivante();
    expect(session.numero, 2);
    expect(session.aRepondu, isFalse);

    session.repondre(2); // faux (bonne = 1)
    expect(session.score, 1);
    expect(session.questionsRatees.map((q) => q.id), ['q2']);

    session.suivante();
    expect(session.estDerniere, isTrue);
    session.repondre(2); // juste
    expect(session.estTerminee, isFalse);

    session.suivante();
    expect(session.estTerminee, isTrue);
    expect(session.score, 2);
  });

  test('une seule réponse par question, et pas de suivante sans réponse', () {
    final session = QuizSession([_q('q1', 0), _q('q2', 0)], melanger: false);

    session.suivante(); // ignoré : pas encore répondu
    expect(session.numero, 1);

    session.repondre(1); // faux
    session.repondre(0); // ignoré : déjà répondu
    expect(session.choix, 1);
    expect(session.score, 0);
  });

  test('la progression va de 1/n à n/n', () {
    final session = QuizSession([_q('q1', 0), _q('q2', 0)], melanger: false);
    expect(session.progression, 0.5);
    session.repondre(0);
    session.suivante();
    expect(session.progression, 1.0);
  });

  test('mélange : les index affichés sont bien convertis', () {
    final q = _q('q1', 2); // bonne = 'c'
    // Avec une graine fixe, l'ordre est prévisible et reproductible.
    final session = QuizSession([q, q, q], random: Random(42));
    final affichees = session.reponsesAffichees;
    expect(affichees.toSet(), {'a', 'b', 'c'});
    final indexDeC = affichees.indexOf('c');
    expect(session.estBonneAffichee(indexDeC), isTrue);
    session.repondre(indexDeC);
    expect(session.score, 1);
    expect(session.derniereReussie, isTrue);
  });

  Question ordre() => const Question(
        id: 'o1',
        ficheId: 'f',
        type: TypeQuestion.ordre,
        enonce: 'Remets dans l\'ordre',
        reponses: ['Un', 'Deux', 'Trois'],
        explication: '.',
      );

  test('question ordre : bon ordre = réussie, mauvais ordre = ratée', () {
    final ok = QuizSession([ordre()], melanger: false);
    ok.repondreOrdre([0, 1, 2]);
    expect(ok.derniereReussie, isTrue);
    expect(ok.estBienPlacee(0), isTrue);

    final ko = QuizSession([ordre()], melanger: false);
    ko.repondreOrdre([2, 1, 0]);
    expect(ko.derniereReussie, isFalse);
    expect(ko.estBienPlacee(1), isTrue); // "Deux" est resté au milieu
    expect(ko.estBienPlacee(0), isFalse);
    expect(ko.questionsRatees.single.id, 'o1');
  });

  test('question ordre mélangée : remettre les index affichés dans le bon ordre', () {
    final session = QuizSession([ordre()], random: Random(7));
    final affichees = session.reponsesAffichees;
    final bonOrdre = [affichees.indexOf('Un'), affichees.indexOf('Deux'), affichees.indexOf('Trois')];
    session.repondreOrdre(bonOrdre);
    expect(session.derniereReussie, isTrue);
  });

  test('terminerMaintenant compte ratées la question en cours et la suite', () {
    final session = QuizSession([_q('q1', 0), _q('q2', 1), _q('q3', 2)], melanger: false);
    session.repondre(0); // juste
    session.suivante();
    session.terminerMaintenant(); // q2 sans réponse, q3 jamais vue
    expect(session.estTerminee, isTrue);
    expect(session.score, 1);
    expect(session.questionsRatees.map((q) => q.id), ['q2', 'q3']);
  });

  test('terminerMaintenant après une réponse ne recompte pas la question', () {
    final session = QuizSession([_q('q1', 0), _q('q2', 1)], melanger: false);
    session.repondre(1); // faux
    session.terminerMaintenant();
    expect(session.questionsRatees.map((q) => q.id), ['q1', 'q2']);
    expect(session.score, 0);
  });
}
