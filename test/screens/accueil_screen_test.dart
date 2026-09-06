import 'package:elecapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Écran de test assez haut pour afficher les 5 modules sans défiler.
void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 20000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets("l'onglet Modules affiche les modules avec leur progression",
      (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());

    // Pendant le chargement du JSON, un indicateur tourne.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Modules'));
    await tester.pumpAndSettle();

    expect(find.text("Grandeurs électriques et loi d'Ohm"), findsOneWidget);
    expect(find.textContaining('questions réussies'), findsNWidgets(100));
    expect(find.text('0/20 questions réussies'), findsWidgets);
    expect(find.text('Contenu à venir'), findsNothing);
    // Les sections par thème.
    expect(find.text('Les bases'), findsOneWidget);
    expect(find.text('Sécurité et habilitation'), findsOneWidget);
  });

  testWidgets('la recherche filtre les modules, sans tenir compte des accents',
      (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modules'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'eclairage');
    await tester.pumpAndSettle();
    expect(find.text('Éclairage et commandes'), findsOneWidget);
    expect(find.text('Éclairage extérieur et jardin'), findsOneWidget);
    expect(find.text("Grandeurs électriques et loi d'Ohm"), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun module ne correspond'), findsOneWidget);
  });
}
