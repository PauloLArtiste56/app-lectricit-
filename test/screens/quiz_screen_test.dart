import 'package:elecapp/main.dart';
import 'package:elecapp/models/module.dart';
import 'package:elecapp/models/question.dart';
import 'package:elecapp/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _module = Module(
  id: 'test',
  titre: 'Module test',
  ordre: 1,
  fiches: const [],
  questions: const [
    Question(
      id: 'q1',
      ficheId: 'f',
      type: TypeQuestion.qcm,
      enonce: 'Unité de la tension ?',
      reponses: ['Ampère', 'Volt', 'Ohm'],
      bonne: 1,
      explication: 'La tension se mesure en volts.',
    ),
    Question(
      id: 'q2',
      ficheId: 'f',
      type: TypeQuestion.qcm,
      enonce: 'Unité du courant ?',
      reponses: ['Ampère', 'Volt', 'Ohm'],
      bonne: 0,
      explication: "L'intensité se mesure en ampères.",
    ),
  ],
);

void main() {
  testWidgets('feedback immédiat puis passage à la question suivante',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: QuizScreen(module: _module)));

    expect(find.text('Question 1 / 2'), findsOneWidget);
    expect(find.text('Unité de la tension ?'), findsOneWidget);
    expect(find.text('La tension se mesure en volts.'), findsNothing);

    // Mauvaise réponse : feedback rouge + explication.
    await tester.tap(find.text('Ohm'));
    await tester.pump();
    expect(find.text('Mauvaise réponse'), findsOneWidget);
    expect(find.text('La tension se mesure en volts.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // la bonne, en vert
    expect(find.byIcon(Icons.cancel), findsOneWidget); // la choisie, en rouge

    await tester.tap(find.text('Question suivante'));
    await tester.pump();
    expect(find.text('Question 2 / 2'), findsOneWidget);

    // Bonne réponse sur la dernière, puis fin.
    await tester.tap(find.text('Ampère'));
    await tester.pump();
    expect(find.text('Bonne réponse !'), findsOneWidget);

    await tester.tap(find.text('Terminer'));
    await tester.pump();
    expect(find.text('Quiz terminé'), findsOneWidget);
    expect(find.text('Score : 1 / 2'), findsOneWidget);
  });

  testWidgets("depuis l'accueil, un clic sur un module ouvre son quiz",
      (tester) async {
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("Grandeurs électriques et loi d'Ohm"));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 / 10'), findsOneWidget);
  });
}
