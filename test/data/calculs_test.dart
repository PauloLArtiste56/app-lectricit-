import 'package:elecapp/data/calculs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loi d\'Ohm dans les trois sens', () {
    expect(Calculs.tension(10, 2), 20);
    expect(Calculs.courant(20, 10), 2);
    expect(Calculs.resistance(20, 2), 10);
    // Division par zéro : on renvoie 0 plutôt qu'un infini affiché à l'écran.
    expect(Calculs.courant(20, 0), 0);
    expect(Calculs.resistance(20, 0), 0);
  });

  test('puissance, courant et énergie', () {
    expect(Calculs.puissance(230, 10), 2300);
    expect(Calculs.courantPourPuissance(2000, 230), closeTo(8.7, 0.05));
    expect(Calculs.courantPourPuissance(2000, 0), 0);
    // Un radiateur de 2 kW pendant 5 h : 10 kWh, 2 € à 0,20 € le kWh.
    expect(Calculs.energie(2000, 5), 10);
    expect(Calculs.cout(10, 0.20), closeTo(2, 0.0001));
  });

  test('section minimale et calibre associé', () {
    expect(Calculs.sectionMinimale(16), 1.5);
    expect(Calculs.sectionMinimale(17), 2.5);
    expect(Calculs.sectionMinimale(20), 2.5);
    expect(Calculs.sectionMinimale(32), 6);
    // Une borne de 7,4 kW appelle 32,2 A sous 230 V : juste au-dessus du
    // 32 A, donc 10 mm² et un disjoncteur 40 A, comme dans le cas pratique.
    final borne = Calculs.courantPourPuissance(7400, 230);
    expect(borne, closeTo(32.2, 0.1));
    expect(Calculs.sectionMinimale(borne), 10);
    expect(Calculs.calibrePour(10), 40);
    // Au-delà du tableau : pas de réponse.
    expect(Calculs.sectionMinimale(70), isNull);
    expect(Calculs.calibrePour(2.5), 20);
    expect(Calculs.calibrePour(3), isNull);
  });

  test('chute de tension en monophasé et en triphasé', () {
    // 25 m, 16 A, 2,5 mm² : 2 × 0,023 × 25 × 16 / 2,5 = 7,36 V.
    final mono = Calculs.chuteTension(longueur: 25, courantA: 16, section: 2.5);
    expect(mono, closeTo(7.36, 0.001));
    expect(Calculs.chutePourcent(mono, 230), closeTo(3.2, 0.01));

    // En triphasé, le facteur passe de 2 à racine de 3 : chute plus faible.
    final tri = Calculs.chuteTension(
        longueur: 25, courantA: 16, section: 2.5, triphase: true);
    expect(tri, lessThan(mono));
    expect(tri, closeTo(6.373, 0.01));

    // Doubler la section divise la chute par deux.
    final grosse = Calculs.chuteTension(longueur: 25, courantA: 16, section: 5);
    expect(grosse, closeTo(mono / 2, 0.0001));
    // Section nulle : pas de division par zéro.
    expect(Calculs.chuteTension(longueur: 25, courantA: 16, section: 0), 0);
    expect(Calculs.chutePourcent(5, 0), 0);
  });
}
