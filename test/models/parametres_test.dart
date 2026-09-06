import 'package:elecapp/models/parametres.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les paramètres font un aller-retour JSON et gardent les défauts', () {
    const p = Parametres(theme: 'sombre', tailleSeance: 15, parcoursLibre: true);
    final relu = Parametres.fromJson(p.toJson());
    expect(relu.theme, 'sombre');
    expect(relu.tailleSeance, 15);
    expect(relu.parcoursLibre, isTrue);
    expect(relu.melanger, isTrue);
    expect(relu.dureeExamen, const Duration(minutes: 10));

    // Un JSON incomplet (ancienne version) prend les valeurs par défaut.
    final ancien = Parametres.fromJson({'theme': 'clair'});
    expect(ancien.theme, 'clair');
    expect(ancien.tailleExamen, 20);
    expect(ancien.objectifXpJour, 50);
    expect(ancien.sons, isTrue);
    expect(Parametres.fromJson(const Parametres(sons: false).toJson()).sons, isFalse);

    // L'objectif du jour est conservé.
    final avecObjectif = Parametres.fromJson(const Parametres(objectifXpJour: 200).toJson());
    expect(avecObjectif.objectifXpJour, 200);
  });
}
