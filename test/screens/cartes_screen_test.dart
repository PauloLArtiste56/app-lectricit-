import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/models/question.dart';
import 'package:elecapp/screens/cartes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _q1 = Question(
  id: 'q1',
  ficheId: 'f',
  type: TypeQuestion.qcm,
  enonce: 'Unité de la tension ?',
  reponses: ['Ampère', 'Volt', 'Ohm'],
  bonne: 1,
  explication: 'La tension se mesure en volts.',
);
const _q2 = Question(
  id: 'q2',
  ficheId: 'f',
  type: TypeQuestion.ordre,
  enonce: 'Ordre de consignation ?',
  reponses: ['Séparer', 'Condamner', 'Vérifier'],
  bonne: 0,
  explication: 'Toujours dans cet ordre.',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('retourner une carte, puis « Je sais » / « À revoir » jusqu\'au bilan',
      (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: CartesScreen(titre: 'Cartes test', questions: [_q1, _q2]),
      ),
    ));
    expect(find.text('Carte 1 / 2'), findsOneWidget);
    expect(find.text('Unité de la tension ?'), findsOneWidget);
    // Recto : pas encore de réponse ni de boutons de tri.
    expect(find.text('Volt'), findsNothing);
    expect(find.text('Je sais'), findsNothing);

    await tester.tap(find.text('Retourner la carte'));
    await tester.pumpAndSettle();
    expect(find.text('Volt'), findsOneWidget);
    expect(find.text('La tension se mesure en volts.'), findsOneWidget);

    await tester.tap(find.text('Je sais'));
    await tester.pumpAndSettle();
    expect(find.text('Carte 2 / 2'), findsOneWidget);
    expect(find.text('Ordre de consignation ?'), findsOneWidget);

    // Toucher la carte la retourne aussi ; une question ordre montre le bon ordre.
    await tester.tap(find.text('Ordre de consignation ?'));
    await tester.pumpAndSettle();
    expect(find.text('Séparer → Condamner → Vérifier'), findsOneWidget);
    await tester.tap(find.text('À revoir'));
    await tester.pumpAndSettle();

    expect(find.text('Cartes terminées'), findsOneWidget);
    expect(find.text('1 sue · 1 à revoir'), findsOneWidget);
    expect(find.text('Refaire celles à revoir (1)'), findsOneWidget);

    await tester.tap(find.text('Refaire celles à revoir (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Carte 1 / 1'), findsOneWidget);
    expect(find.text('Ordre de consignation ?'), findsOneWidget);
  });
}
