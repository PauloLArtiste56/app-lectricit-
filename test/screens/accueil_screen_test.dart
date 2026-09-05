import 'package:elecapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets("l'accueil affiche les modules avec leur progression",
      (tester) async {
    await tester.pumpWidget(const ElecApp());

    // Pendant le chargement du JSON, un indicateur tourne.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text("Grandeurs électriques et loi d'Ohm"), findsOneWidget);
    expect(find.text('0/10 questions réussies'), findsNWidgets(5));
    expect(find.text('Contenu à venir'), findsNothing);
  });
}
