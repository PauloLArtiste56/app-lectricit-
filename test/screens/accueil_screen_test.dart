import 'package:elecapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Écran de test assez haut pour afficher les 5 modules sans défiler.
void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets("l'accueil affiche les modules avec leur progression",
      (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());

    // Pendant le chargement du JSON, un indicateur tourne.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text("Grandeurs électriques et loi d'Ohm"), findsOneWidget);
    expect(find.text('0/20 questions réussies'), findsNWidgets(9));
    expect(find.text('Contenu à venir'), findsNothing);
  });
}
