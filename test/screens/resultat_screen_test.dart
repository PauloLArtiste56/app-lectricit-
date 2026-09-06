import 'dart:convert';
import 'dart:io';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/models/module.dart';
import 'package:elecapp/models/question.dart';
import 'package:elecapp/screens/resultat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _q1 = Question(
  id: 'q1',
  ficheId: 'f',
  type: TypeQuestion.qcm,
  enonce: 'Unité de la tension ?',
  reponses: ['Ampère', 'Volt', 'Ohm'],
  bonne: 1,
  explication: 'Volts.',
);
const _q2 = Question(
  id: 'q2',
  ficheId: 'f',
  type: TypeQuestion.qcm,
  enonce: 'Unité du courant ?',
  reponses: ['Ampère', 'Volt', 'Ohm'],
  bonne: 0,
  explication: 'Ampères.',
);
const _module = Module(
  id: 'test',
  titre: 'Module test',
  ordre: 1,
  fiches: [],
  questions: [_q1, _q2],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('affiche le score et les questions ratées avec la bonne réponse',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
      home: ResultatScreen(
        titre: 'Module test',
        module: _module,
        score: 1,
        total: 2,
        questionsRatees: [_q1],
      ),
    ),
    ));

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Unité de la tension ?'), findsOneWidget);
    expect(find.text('Bonne réponse : Volt'), findsOneWidget);
    expect(find.text('Refaire les ratées (1)'), findsOneWidget);
  });

  testWidgets('sans faute : pas de liste ni de bouton "Refaire"',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
      home: ResultatScreen(
        titre: 'Module test',
        module: _module,
        score: 2,
        total: 2,
        questionsRatees: [],
      ),
    ),
    ));

    expect(find.text('Sans faute !'), findsOneWidget);
    expect(find.textContaining('Refaire les ratées'), findsNothing);
    expect(find.text('Retour au parcours'), findsOneWidget);
  });

  testWidgets('"Refaire les ratées" relance un quiz limité aux ratées',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
      home: ResultatScreen(
        titre: 'Module test',
        module: _module,
        score: 1,
        total: 2,
        questionsRatees: [_q1],
      ),
    ),
    ));

    await tester.tap(find.text('Refaire les ratées (1)'));
    await tester.pumpAndSettle();

    // Un quiz d'une seule question : la ratée.
    expect(find.text('Question 1 / 1'), findsOneWidget);
    expect(find.text('Unité de la tension ?'), findsOneWidget);
  });

  testWidgets('un module réussi est fêté et propose le module suivant',
      (tester) async {
    // Progression réelle : 16 questions du premier module déjà réussies.
    final modules = ContentLoader.parserModules(
        File('assets/content.json').readAsStringSync());
    final premier = modules.first;
    final reussies = premier.questions.take(16).map((q) => q.id).toList();
    SharedPreferences.setMockInitialValues({
      'progression': jsonEncode({
        'progression': {
          premier.id: {'questions_reussies': reussies},
        },
        'historique': <Object>[],
      }),
    });
    final etat = AppState();
    await etat.charger();
    expect(etat.moduleReussi(premier), isTrue);
    // Assez haut pour voir les boutons sous la liste des ratées.
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: etat,
      child: MaterialApp(
        home: ResultatScreen(
          titre: premier.titre,
          module: premier,
          score: 16,
          total: 20,
          questionsRatees: premier.questions.skip(16).toList(),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Module réussi !'), findsOneWidget);
    expect(find.textContaining('Module suivant :'), findsOneWidget);
    // « Refaire les ratées » reste disponible, en second choix.
    expect(find.text('Refaire les ratées (4)'), findsOneWidget);
  });

  testWidgets('un module déjà réussi avant le quiz n\'est pas refêté',
      (tester) async {
    final modules = ContentLoader.parserModules(
        File('assets/content.json').readAsStringSync());
    final premier = modules.first;
    SharedPreferences.setMockInitialValues({
      'progression': jsonEncode({
        'progression': {
          premier.id: {
            'questions_reussies':
                premier.questions.map((q) => q.id).toList(),
          },
        },
        'historique': <Object>[],
      }),
    });
    final etat = AppState();
    await etat.charger();

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: etat,
      child: MaterialApp(
        home: ResultatScreen(
          titre: premier.titre,
          module: premier,
          score: 20,
          total: 20,
          questionsRatees: const [],
          dejaReussi: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Module réussi !'), findsNothing);
    expect(find.text('Sans faute !'), findsOneWidget);
    expect(find.textContaining('Module suivant :'), findsOneWidget);
  });
}
