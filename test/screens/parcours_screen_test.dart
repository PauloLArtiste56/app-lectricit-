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
    expect(find.text('CHAPITRE 1'), findsOneWidget);
    // Seul le premier module est ouvert : bulle « Commencer », les autres
    // sont verrouillés.
    expect(find.text('COMMENCER'), findsOneWidget);
    final noeuds = tester.widgetList<NoeudModule>(find.byType(NoeudModule)).toList();
    expect(noeuds.first.etat, EtatNoeud.aFaire);
    expect(noeuds.first.courant, isTrue);
    expect(noeuds.where((n) => n.etat == EtatNoeud.verrouille).length, 99);
    // La mascotte est posée sur le chemin.
    expect(
      find.image(const AssetImage('assets/images/decors/pile_0.png')),
      findsOneWidget,
    );
    expect(find.text('Les fondamentaux'), findsOneWidget);
    // Aucun module réussi au départ : trois chapitres comptent 11 modules.
    expect(find.text('0/11'), findsNWidgets(3));
  });

  testWidgets('un rond ouvert mène au module, un rond verrouillé prévient',
      (tester) async {
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Circuits série / parallèle'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Réussis d'abord « Courant continu"), findsOneWidget);
    expect(find.textContaining('Lancer le quiz'), findsNothing);

    await tester.tap(find.text("Grandeurs électriques et loi d'Ohm"));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lancer le quiz'), findsOneWidget);
  });

  testWidgets('un module réussi passe en vert et déverrouille le suivant', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progression': '{"progression": {"grandeurs": {"questions_reussies": '
          '["q001","q002","q003","q004","q005","q006","q007","q008","q009",'
          '"q010","q011","q012","q013","q014","q015","q016"]}}, "historique": []}',
    });
    _ecranHaut(tester);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    final noeuds = tester.widgetList<NoeudModule>(find.byType(NoeudModule)).toList();
    expect(noeuds[0].module.id, 'grandeurs');
    expect(noeuds[0].etat, EtatNoeud.reussi);
    expect(noeuds[0].courant, isFalse);
    // Le suivant est déverrouillé et devient le module en cours.
    expect(noeuds[1].etat, EtatNoeud.aFaire);
    expect(noeuds[1].courant, isTrue);
    expect(noeuds[2].etat, EtatNoeud.verrouille);
    expect(find.text('1/11'), findsOneWidget);
  });
}
