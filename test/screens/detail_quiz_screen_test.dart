import 'dart:convert';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/quiz_session.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/screens/detail_quiz_screen.dart';
import 'package:elecapp/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 20000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _ouvrirStats(WidgetTester tester) async {
  await tester.pumpWidget(const ElecApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stats'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('un quiz de l\'historique montre ses questions ratées',
      (tester) async {
    // Un quiz réel : 8 bonnes réponses sur 10, deux ratées enregistrées.
    final etat = AppState();
    await etat.charger();
    final module = etat.modules.first;
    final questions = module.questions.take(10).toList();
    final session = QuizSession(questions, melanger: false);
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      session.repondre(i < 8 ? q.bonne : (q.bonne + 1) % q.reponses.length);
      session.suivante();
    }
    await etat.enregistrerResultat(session, moduleComplet: module);
    final entree = etat.historique.last;
    expect(entree.ratees.length, 2);
    final ratees = etat.rateesDe(entree);
    expect(ratees.length, 2);

    _ecranHaut(tester);
    await _ouvrirStats(tester);
    await tester.tap(find.text(module.titre).last);
    await tester.pumpAndSettle();

    expect(find.byType(DetailQuizScreen), findsOneWidget);
    expect(find.text('8 / 10'), findsOneWidget);
    expect(find.text('Questions ratées (2)'), findsOneWidget);
    for (final q in ratees) {
      expect(find.text(q.enonce), findsOneWidget);
      expect(find.text(DetailQuizScreen.bonneReponse(q)), findsOneWidget);
    }

    // Le bouton relance un quiz limité à ces deux questions.
    await tester.tap(find.text('Refaire ces 2 questions'));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('Question 1 / 2'), findsOneWidget);
  });

  testWidgets('un ancien quiz sans détail le dit, un sans-faute aussi',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'progression': jsonEncode({
        'progression': <String, dynamic>{},
        'historique': [
          // Enregistré avant l'ajout des ratées : pas de liste.
          {'module': 'grandeurs', 'date': '2026-09-01', 'score': 6, 'total': 10},
          {'module': 'grandeurs', 'date': '2026-09-02', 'score': 10, 'total': 10},
        ],
      }),
    });
    _ecranHaut(tester);
    await _ouvrirStats(tester);

    // Le plus récent d'abord : le sans-faute.
    await tester.tap(find.text('Grandeurs électriques et loi d\'Ohm').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sans faute'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grandeurs électriques et loi d\'Ohm').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('n\'ont pas été enregistrées'), findsOneWidget);
    expect(find.textContaining('Refaire'), findsNothing);
  });
}
