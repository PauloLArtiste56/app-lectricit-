import 'dart:convert';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/screens/boutique_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 60 bonnes réponses dans l'historique = 600 XP.
final _progression = jsonEncode({
  'progression': <String, dynamic>{},
  'historique': [
    {'module': 'grandeurs', 'date': '2026-09-05', 'score': 20, 'total': 20},
    {'module': 'grandeurs', 'date': '2026-09-05', 'score': 20, 'total': 20},
    {'module': 'grandeurs', 'date': '2026-09-05', 'score': 20, 'total': 20},
  ],
});

void main() {
  testWidgets('acheter un gel et une tenue, la porter, la retirer', (tester) async {
    SharedPreferences.setMockInitialValues({'progression': _progression});
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final etat = AppState(horloge: () => DateTime(2026, 9, 6));
    await etat.charger();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: etat,
      child: const MaterialApp(home: BoutiqueScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('600 XP disponibles'), findsOneWidget);
    expect(find.text('En stock : 0 / 2'), findsOneWidget);

    await tester.tap(find.text('100 XP'));
    await tester.pumpAndSettle();
    expect(find.text('En stock : 1 / 2'), findsOneWidget);
    expect(find.text('500 XP disponibles'), findsOneWidget);
    expect(etat.gels, 1);

    // Lunettes (150 XP) : achetées et portées d'un coup.
    await tester.tap(find.text('150 XP'));
    await tester.pumpAndSettle();
    expect(find.text('350 XP disponibles'), findsOneWidget);
    expect(find.text('Portée'), findsOneWidget);
    expect(etat.tenuePortee?.id, 'lunettes');
    // La couronne (1 000 XP) est hors de portée : bouton désactivé.
    final couronne = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '1000 XP'));
    expect(couronne.onPressed, isNull);

    await tester.tap(find.text('Retirer la tenue'));
    await tester.pumpAndSettle();
    expect(etat.tenuePortee, isNull);
    expect(find.text('Porter'), findsOneWidget);
    await tester.tap(find.text('Porter'));
    await tester.pumpAndSettle();
    expect(etat.tenuePortee?.id, 'lunettes');

    // Tout est enregistré.
    final relu = AppState(horloge: () => DateTime(2026, 9, 6));
    await relu.charger();
    expect(relu.gels, 1);
    expect(relu.xpDisponibles, 350);
    expect(relu.tenuePortee?.id, 'lunettes');
    // Le niveau reste calculé sur le total gagné.
    expect(relu.xpTotal, 600);
  });

  testWidgets('la boutique s\'ouvre depuis le parcours et la tenue s\'affiche sur la pile',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'progression': jsonEncode({
        'progression': <String, dynamic>{},
        'historique': <Object>[],
        'achats': ['casque'],
        'tenue': 'casque',
        'gels': 2,
      }),
    });
    tester.view.physicalSize = const Size(480, 20000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    expect(
      find.image(const AssetImage('assets/images/decors/tenue_casque.png')),
      findsOneWidget,
    );
    // Les gels en réserve sont visibles sur la carte d'entraînement.
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    await tester.tap(find.byTooltip('Boutique'));
    await tester.pumpAndSettle();
    expect(find.byType(BoutiqueScreen), findsOneWidget);
    expect(find.text('En stock : 2 / 2'), findsOneWidget);
  });
}
