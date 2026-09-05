import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/quiz_session.dart';
import 'package:elecapp/models/fiche.dart';
import 'package:elecapp/models/module.dart';
import 'package:elecapp/models/question.dart';
import 'package:elecapp/screens/module_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _module = Module(
  id: 'test',
  titre: 'Module test',
  ordre: 1,
  fiches: [
    Fiche(id: 'f1', titre: 'Première fiche', contenu: 'Texte de la première fiche.'),
    Fiche(id: 'f2', titre: 'Seconde fiche', contenu: 'Texte de la seconde fiche.'),
  ],
  questions: [
    Question(
      id: 'q1',
      ficheId: 'f1',
      type: TypeQuestion.qcm,
      enonce: 'Question ?',
      reponses: ['a', 'b', 'c'],
      bonne: 0,
      explication: 'Parce que.',
    ),
  ],
);

Widget _app() => ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(home: ModuleScreen(module: _module)),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  mainReprise();

  testWidgets('liste les fiches et le bouton quiz', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('Première fiche'), findsOneWidget);
    expect(find.text('Seconde fiche'), findsOneWidget);
    expect(find.text('Lancer le quiz (1 questions)'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('ouvrir une fiche la marque comme lue', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Première fiche'));
    await tester.pumpAndSettle();

    expect(find.text('Fiche 1 / 2'), findsOneWidget);
    expect(find.text('Texte de la première fiche.'), findsOneWidget);

    // "Fiche suivante" enchaîne sur la seconde, qui n'a plus ce bouton.
    await tester.tap(find.text('Fiche suivante'));
    await tester.pumpAndSettle();
    expect(find.text('Fiche 2 / 2'), findsOneWidget);
    expect(find.text('Fiche suivante'), findsNothing);

    // Retour au module : les deux fiches sont cochées.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });

  testWidgets('"Passer au quiz" depuis une fiche ouvre le quiz', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Seconde fiche'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passer au quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 / 1'), findsOneWidget);
  });
}

const _module3 = Module(
  id: 'test3',
  titre: 'Module trois questions',
  ordre: 1,
  fiches: [],
  questions: [
    Question(id: 'a', ficheId: 'f', type: TypeQuestion.qcm, enonce: 'Question A ?', reponses: ['x', 'y', 'z'], bonne: 0, explication: '.'),
    Question(id: 'b', ficheId: 'f', type: TypeQuestion.qcm, enonce: 'Question B ?', reponses: ['x', 'y', 'z'], bonne: 1, explication: '.'),
    Question(id: 'c', ficheId: 'f', type: TypeQuestion.qcm, enonce: 'Question C ?', reponses: ['x', 'y', 'z'], bonne: 2, explication: '.'),
  ],
);

void mainReprise() {
  testWidgets('module commencé : choix entre les ratées et tout refaire',
      (tester) async {
    final etat = AppState();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: etat,
      child: const MaterialApp(home: ModuleScreen(module: _module3)),
    ));
    expect(find.text('Lancer le quiz (3 questions)'), findsOneWidget);

    // On simule un quiz complet avec B et C ratées.
    final session = QuizSession(_module3.questions, melanger: false);
    session.repondre(0); session.suivante(); // A juste
    session.repondre(0); session.suivante(); // B faux
    session.repondre(0); session.suivante(); // C faux
    await etat.enregistrerResultat(session, moduleComplet: _module3);
    await tester.pump();

    expect(find.text('Refaire uniquement les ratées (2)'), findsOneWidget);
    expect(find.text('Recommencer depuis le début (3 questions)'), findsOneWidget);

    // Le quiz des ratées ne contient que B et C.
    await tester.tap(find.text('Refaire uniquement les ratées (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 / 2'), findsOneWidget);
    // Les questions sont mélangées : c'est B ou C, jamais A (réussie).
    expect(find.text('Question A ?'), findsNothing);
    expect(find.textContaining(RegExp(r'Question [BC] \?')), findsOneWidget);
  });

  testWidgets('module terminé : un seul bouton "Refaire le quiz"',
      (tester) async {
    final etat = AppState();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: etat,
      child: const MaterialApp(home: ModuleScreen(module: _module3)),
    ));
    final session = QuizSession(_module3.questions, melanger: false);
    for (final q in _module3.questions) { session.repondre(q.bonne); session.suivante(); }
    await etat.enregistrerResultat(session, moduleComplet: _module3);
    await tester.pump();

    expect(find.text('Refaire le quiz (3 questions)'), findsOneWidget);
    expect(find.textContaining('ratées'), findsNothing);
  });
}
