import 'package:elecapp/main.dart';
import 'package:elecapp/widgets/banniere_chapitre.dart';
import 'package:elecapp/widgets/noeud_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écran de test assez haut pour afficher tout le parcours sans défiler.
void _ecranHaut(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 20000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('le parcours affiche les chapitres et un rond par module',
      (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    expect(find.text('Ma séance du jour'), findsOneWidget);
    expect(find.byType(BanniereChapitre), findsNWidgets(10));
    expect(find.byType(NoeudModule), findsNWidgets(100));
    expect(find.text('Chapitre 1'), findsOneWidget);
    expect(find.text('Les fondamentaux'), findsOneWidget);
    // Aucun module réussi au départ : trois chapitres comptent 11 modules.
    expect(find.text('0/11'), findsNWidgets(3));
  });

  testWidgets('un rond du parcours ouvre le module', (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Circuits série / parallèle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lancer le quiz'), findsOneWidget);
  });

  testWidgets('un module réussi passe en vert avec une coche', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progression': '{"progression": {"grandeurs": {"questions_reussies": '
          '["q001","q002","q003","q004","q005","q006","q007","q008","q009",'
          '"q010","q011","q012","q013","q014","q015","q016"]}}, "historique": []}',
    });
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    final noeud = tester.widget<NoeudModule>(find.byType(NoeudModule).first);
    expect(noeud.module.id, 'grandeurs');
    expect(noeud.etat, EtatNoeud.reussi);
    expect(find.text('1/11'), findsOneWidget);
  });
}
