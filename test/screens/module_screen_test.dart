import 'package:elecapp/data/app_state.dart';
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
