import 'dart:convert';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/models/parametres.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Douze quiz : assez pour que le rappel de sauvegarde se déclenche.
String _progressionFournie() => jsonEncode({
      'progression': <String, dynamic>{},
      'historique': [
        for (var i = 0; i < 12; i++)
          {'module': 'grandeurs', 'date': '2026-09-01', 'score': 5, 'total': 10},
      ],
    });

void main() {
  test('le rappel de sauvegarde ne sort qu\'après dix quiz et se tait ensuite',
      () async {
    SharedPreferences.setMockInitialValues({});
    final etat = AppState(horloge: () => DateTime(2026, 9, 6));
    await etat.charger();
    expect(etat.sauvegardeConseillee, isFalse);

    SharedPreferences.setMockInitialValues({'progression': _progressionFournie()});
    final charge = AppState(horloge: () => DateTime(2026, 9, 6));
    await charge.charger();
    expect(charge.sauvegardeConseillee, isTrue);

    await charge.marquerSauvegarde();
    expect(charge.parametres.derniereSauvegarde, '2026-09-06');
    expect(charge.sauvegardeConseillee, isFalse);

    // Un mois plus tard, le rappel revient.
    final plusTard = AppState(horloge: () => DateTime(2026, 10, 20));
    await plusTard.charger();
    expect(plusTard.parametres.derniereSauvegarde, '2026-09-06');
    expect(plusTard.sauvegardeConseillee, isTrue);
  });

  testWidgets('la taille du texte choisie s\'applique à toute l\'appli',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'parametres': jsonEncode(const Parametres(tailleTexte: 1.2).toJson()),
    });
    tester.view.physicalSize = const Size(480, 20000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    final contexte = tester.element(find.text('Ma séance du jour'));
    expect(MediaQuery.textScalerOf(contexte).scale(10), closeTo(12, 0.001));
  });
}
