import 'package:elecapp/main.dart';
import 'package:elecapp/screens/outils_screen.dart';
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

  test('formater écrit à la française, sans zéros inutiles', () {
    expect(formater(20), '20');
    expect(formater(8.695), '8,7');
    expect(formater(7.36), '7,36');
    expect(double.infinity.isInfinite, isTrue);
    expect(formater(double.infinity), '—');
  });

  test('lireNombre accepte la virgule comme le point', () {
    expect(lireNombre('2,5'), 2.5);
    expect(lireNombre(' 2.5 '), 2.5);
    expect(lireNombre(''), isNull);
    expect(lireNombre('abc'), isNull);
  });

  testWidgets('la boîte à outils s\'ouvre depuis Modules et calcule',
      (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modules'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Boîte à outils'));
    await tester.pumpAndSettle();

    expect(find.byType(OutilsScreen), findsOneWidget);
    expect(find.text('Loi d\'Ohm'), findsOneWidget);
    expect(find.text('Section de câble'), findsOneWidget);
    expect(find.text('Chute de tension'), findsOneWidget);

    // Loi d'Ohm : 10 Ω et 2 A donnent 20 V.
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), '10');
    await tester.enterText(champs.at(1), '2');
    await tester.pumpAndSettle();
    expect(find.text('U = R × I = 20 V'), findsOneWidget);

    // On bascule sur la résistance : 20 V et 2 A donnent 10 Ω.
    await tester.tap(find.text('Résistance'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.pumpAndSettle();
    expect(find.text('R = U / I = 10 Ω'), findsOneWidget);
  });

  testWidgets('section et chute de tension : conseil et alerte', (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const MaterialApp(home: OutilsScreen()));
    await tester.pumpAndSettle();

    // Section : 20 A demandent du 2,5 mm² avec un disjoncteur 20 A.
    final section = find.descendant(
      of: find.ancestor(
        of: find.text('Section de câble'),
        matching: find.byType(Card),
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(section, '20');
    await tester.pumpAndSettle();
    expect(find.text('Section minimale 2,5 mm², disjoncteur 20 A'), findsOneWidget);

    // Chute de tension : 25 m en 2,5 mm² sous 16 A, soit 3,2 %.
    final chute = find.descendant(
      of: find.ancestor(
        of: find.text('Chute de tension'),
        matching: find.byType(Card),
      ),
      matching: find.byType(TextField),
    );
    await tester.enterText(chute.at(0), '25');
    await tester.enterText(chute.at(1), '16');
    await tester.enterText(chute.at(2), '2,5');
    await tester.pumpAndSettle();
    expect(find.textContaining('Chute de 7,36 V, soit 3,2 %'), findsOneWidget);

    // Trois fois plus long : la chute dépasse les 5 % admis.
    await tester.enterText(chute.at(0), '75');
    await tester.pumpAndSettle();
    expect(find.textContaining('trop, il faut une section plus grosse'),
        findsOneWidget);
  });
}
