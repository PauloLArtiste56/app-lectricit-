import 'package:elecapp/models/progression.dart';
import 'package:elecapp/models/recompense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('récompenses et badges font l\'aller-retour JSON', () {
    final p = Progression();
    p.recompenses.add(const Recompense(id: 'quete:deux_quiz:2026-09-06', date: '2026-09-06', xp: 20));
    p.badges['premier_quiz'] = '2026-09-06';

    final relu = Progression.fromJson(p.toJson());
    expect(relu.recompenses.length, 1);
    expect(relu.recompenses.first.id, 'quete:deux_quiz:2026-09-06');
    expect(relu.recompenses.first.xp, 20);
    expect(relu.badges, {'premier_quiz': '2026-09-06'});

    // Boutique : XP dépensés, gels, tenues.
    p.xpDepenses = 250;
    p.gels = 1;
    p.gelsUtilises.add('2026-09-04');
    p.achats.add('lunettes');
    p.tenue = 'lunettes';
    final relu2 = Progression.fromJson(p.toJson());
    expect(relu2.xpDepenses, 250);
    expect(relu2.gels, 1);
    expect(relu2.gelsUtilises, ['2026-09-04']);
    expect(relu2.achats, ['lunettes']);
    expect(relu2.tenue, 'lunettes');

    // Un ancien fichier sans ces champs se lit sans erreur.
    final ancien = Progression.fromJson({'progression': <String, dynamic>{}, 'historique': <Object>[]});
    expect(ancien.recompenses, isEmpty);
    expect(ancien.badges, isEmpty);
    expect(ancien.gels, 0);
    expect(ancien.tenue, isNull);
  });
}
