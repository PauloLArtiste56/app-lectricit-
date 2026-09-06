import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/screens/cas_pratiques_screen.dart';
import 'package:elecapp/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la liste des cas mène à un quiz avec le contexte, puis le cas est résolu',
      (tester) async {
    tester.view.physicalSize = const Size(480, 20000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Cas pratiques : 0 /'));
    await tester.pumpAndSettle();
    expect(find.byType(CasPratiquesScreen), findsOneWidget);
    final etat = Provider.of<AppState>(
        tester.element(find.byType(CasPratiquesScreen)), listen: false);
    final cas = etat.casPratiques;
    expect(cas.length, greaterThanOrEqualTo(10));
    expect(find.text(cas.first.titre), findsOneWidget);
    expect(find.text('${cas.first.etapes.length} étapes'), findsWidgets);

    await tester.tap(find.text(cas.first.titre));
    await tester.pumpAndSettle();
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text(cas.first.contexte), findsOneWidget);
    expect(find.text('Question 1 / ${cas.first.etapes.length}'), findsOneWidget);
    // Les étapes restent dans l'ordre, même avec le mélange activé.
    expect(find.text(cas.first.etapes.first.enonce), findsOneWidget);

    for (final etape in cas.first.etapes) {
      await tester.tap(find.text(etape.reponses[etape.bonne]));
      await tester.pumpAndSettle();
      await tester.tap(find.text(etape == cas.first.etapes.last
          ? 'Terminer'
          : 'Question suivante'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Sans faute !'), findsOneWidget);
    expect(etat.casResolu(cas.first), isTrue);
    expect(etat.casResolus, 1);
    expect(etat.historique.last.moduleId, 'cas:${cas.first.id}');
  });
}
