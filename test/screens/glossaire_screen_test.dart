import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/screens/fiche_screen.dart';
import 'package:elecapp/screens/glossaire_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('le glossaire s\'ouvre depuis l\'onglet Modules et se filtre', (tester) async {
    tester.view.physicalSize = const Size(480, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modules'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Glossaire'));
    await tester.pumpAndSettle();
    expect(find.byType(GlossaireScreen), findsOneWidget);
    // Trié par ordre alphabétique : « Ampère » avant « Arc électrique ».
    expect(find.text('Ampère'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'differentiel');
    await tester.pumpAndSettle();
    expect(find.text('Différentiel'), findsOneWidget);
    expect(find.text('Ampère'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun terme'), findsOneWidget);
  });

  testWidgets('dans une fiche, un terme du glossaire est cliquable', (tester) async {
    tester.view.physicalSize = const Size(480, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final etat = AppState();
    await etat.charger();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: etat,
      child: MaterialApp(home: FicheScreen(module: etat.modules.first, index: 0)),
    ));
    await tester.pumpAndSettle();

    // La fiche contient au moins un terme souligné (segment avec recognizer).
    final riche = tester.widget<Text>(find.byWidgetPredicate(
      (w) => w is Text && w.textSpan != null && w.textSpan!.toPlainText().length > 100,
    ));
    final spans = <InlineSpan>[];
    riche.textSpan!.visitChildren((s) {
      spans.add(s);
      return true;
    });
    final cliquables = spans.whereType<TextSpan>().where((s) => s.recognizer != null).toList();
    expect(cliquables, isNotEmpty);
    // Simuler l'appui ouvre la définition en bas de l'écran.
    (cliquables.first.recognizer as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
  });
}
