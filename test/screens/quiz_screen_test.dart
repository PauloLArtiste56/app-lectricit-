import 'dart:io';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/models/module.dart';
import 'package:elecapp/models/question.dart';
import 'package:elecapp/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


/// Écran de test assez haut pour afficher tout l'accueil sans défiler.
void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 20000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('feedback immédiat puis passage à la question suivante',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(home: QuizScreen(module: _module, melanger: false)),
    ));

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
    await tester.pumpAndSettle();
    expect(find.text('Quiz terminé'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets("depuis l'accueil, module puis \"Lancer le quiz\" ouvre le quiz",
      (tester) async {
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("Grandeurs électriques et loi d'Ohm"));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Lancer le quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Question 1 / 20'), findsOneWidget);
  });

  testWidgets('une mauvaise réponse propose "Revoir la fiche"', (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Grandeurs électriques et loi d'Ohm"));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Lancer le quiz'));
    await tester.pumpAndSettle();

    // On repère la question affichée dans le contenu réel, puis on choisit
    // une réponse fausse à coup sûr (le quiz est mélangé).
    final questions = ContentLoader.parserModules(
      File('assets/content.json').readAsStringSync(),
    ).first.questions;
    final textes = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .toSet();
    final affichee = questions.firstWhere((q) => textes.contains(q.enonce));
    final mauvaise = affichee.reponses[(affichee.bonne + 1) % affichee.reponses.length];
    await tester.tap(find.text(mauvaise));
    await tester.pump();
    expect(find.text('Mauvaise réponse'), findsOneWidget);
    expect(find.textContaining('Revoir la fiche'), findsOneWidget);

    await tester.tap(find.textContaining('Revoir la fiche'));
    await tester.pumpAndSettle();
    expect(find.text('Retour au quiz'), findsOneWidget);
    await tester.tap(find.text('Retour au quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Mauvaise réponse'), findsOneWidget);
  });

  testWidgets('question "ordre" : valider dans le bon ordre', (tester) async {
    const module = Module(
      id: 'ordre',
      titre: 'Ordre',
      ordre: 1,
      fiches: [],
      questions: [
        Question(
          id: 'o1',
          ficheId: 'f',
          type: TypeQuestion.ordre,
          enonce: 'Remets les étapes dans l\'ordre',
          reponses: ['Première', 'Deuxième', 'Troisième'],
          explication: 'Dans cet ordre.',
        ),
      ],
    );
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(home: QuizScreen(module: module, melanger: false)),
    ));
    expect(find.text('Valider cet ordre'), findsOneWidget);
    await tester.tap(find.text('Valider cet ordre'));
    await tester.pump();
    expect(find.text('Bonne réponse !'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
  });

  testWidgets("la carte d'entraînement lance la séance du jour", (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    expect(find.text('Ma séance du jour'), findsOneWidget);
    await tester.tap(find.textContaining('Lancer la séance'));
    await tester.pumpAndSettle();
    expect(find.text('Séance du jour'), findsOneWidget);
    expect(find.text('Question 1 / ${AppState.tailleSeance}'), findsOneWidget);
  });
}
