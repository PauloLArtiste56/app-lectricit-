import 'package:elecapp/main.dart';
import 'package:elecapp/widgets/noeud_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 20000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('le parcours libre retire les cadenas', (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.textContaining('100 modules'), findsOneWidget);

    await tester.tap(find.text('Parcours libre'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final noeuds = tester.widgetList<NoeudModule>(find.byType(NoeudModule));
    expect(noeuds.where((n) => n.etat == EtatNoeud.verrouille), isEmpty);
  });

  testWidgets('le thème sombre s\'applique tout de suite', (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sombre'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('un import invalide prévient sans rien changer', (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importer une progression'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'n\'importe quoi');
    await tester.tap(find.text('Importer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pas un export valide'), findsOneWidget);
  });

  testWidgets('l\'objectif du jour se règle et s\'affiche sur le parcours',
      (tester) async {
    tester.view.physicalSize = const Size(480, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    expect(find.text('0 / 50 XP'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Objectif du jour'), findsOneWidget);
    expect(find.text('Sons'), findsOneWidget);
    await tester.tap(find.text('50 XP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('200 XP').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('0 / 200 XP'), findsOneWidget);
  });
}
