import 'dart:convert';

import 'package:elecapp/data/insignes.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/screens/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Une progression déjà enregistrée : 8 questions réussies sur le module 1
/// et un quiz dans l'historique.
final _progressionExistante = jsonEncode({
  'progression': {
    'grandeurs': {
      'fiches_lues': ['ohm'],
      'questions_reussies': ['q001', 'q002', 'q003', 'q004', 'q005', 'q006', 'q007', 'q008'],
      'meilleur_score': 8,
    },
  },
  'historique': [
    {'module': 'grandeurs', 'date': '2026-09-05', 'score': 8, 'total': 10},
  ],
});

Future<void> _ouvrirStats(WidgetTester tester) async {
  _ecranHaut(tester);
  await tester.pumpWidget(const ElecApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Stats'));
  await tester.pumpAndSettle();
}


/// Écran de test assez haut pour afficher les 5 modules sans défiler.
void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 20000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('formaterDate passe de ISO à JJ/MM/AAAA', () {
    expect(StatsScreen.formaterDate('2026-09-05'), '05/09/2026');
  });

  testWidgets('sans progression : 0 % et historique vide', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _ouvrirStats(tester);

    expect(find.text('0 %'), findsOneWidget);
    expect(find.textContaining('Aucun quiz'), findsOneWidget);
    // Le récap de la semaine est là, à zéro.
    expect(find.text('Cette semaine'), findsOneWidget);
    expect(find.text('+0 XP'), findsOneWidget);
    expect(find.text('0 / 7'), findsOneWidget);
    // La grille des badges est là, tous encore à gagner.
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('0/${Insigne.tous.length}'), findsOneWidget);
    expect(find.text('Premier pas'), findsOneWidget);
  });

  testWidgets('avec progression : score, historique et réinitialisation',
      (tester) async {
    SharedPreferences.setMockInitialValues({'progression': _progressionExistante});
    await _ouvrirStats(tester);

    expect(find.text('05/09/2026'), findsOneWidget);
    expect(find.text('8 / 10'), findsOneWidget);
    // 8 bonnes réponses dans l'historique : 80 XP, toujours niveau 1.
    expect(find.text('80 XP'), findsOneWidget);
    expect(find.text('Niveau 1'), findsOneWidget);
    expect(find.textContaining('Aucun quiz'), findsNothing);

    // La réinitialisation demande confirmation puis vide tout.
    await tester.tap(find.text('Réinitialiser la progression'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();

    expect(find.text('0 %'), findsOneWidget);
    expect(find.textContaining('Aucun quiz'), findsOneWidget);

    // Et la liste des modules est bien repassée à zéro.
    await tester.tap(find.text('Modules'));
    await tester.pumpAndSettle();
    expect(find.textContaining('questions réussies'), findsNWidgets(100));
    expect(find.text('0/20 questions réussies'), findsWidgets);
  });
}
