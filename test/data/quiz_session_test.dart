import 'package:elecapp/data/quiz_session.dart';
import 'package:elecapp/models/question.dart';
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
    final session = QuizSession([_q('q1', 0), _q('q2', 1), _q('q3', 2)]);

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
    final session = QuizSession([_q('q1', 0), _q('q2', 0)]);

    session.suivante(); // ignoré : pas encore répondu
    expect(session.numero, 1);

    session.repondre(1); // faux
    session.repondre(0); // ignoré : déjà répondu
    expect(session.choix, 1);
    expect(session.score, 0);
  });

  test('la progression va de 1/n à n/n', () {
    final session = QuizSession([_q('q1', 0), _q('q2', 0)]);
    expect(session.progression, 0.5);
    session.repondre(0);
    session.suivante();
    expect(session.progression, 1.0);
  });
}
