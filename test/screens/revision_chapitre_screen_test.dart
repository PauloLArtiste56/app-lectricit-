import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/main.dart';
import 'package:elecapp/screens/module_screen.dart';
import 'package:elecapp/screens/revision_chapitre_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la bannière du parcours ouvre la fiche de révision du chapitre',
      (tester) async {
    tester.view.physicalSize = const Size(480, 20000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ElecApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHAPITRE 1'));
    await tester.pumpAndSettle();

    expect(find.byType(RevisionChapitreScreen), findsOneWidget);
    final etat = Provider.of<AppState>(
        tester.element(find.byType(RevisionChapitreScreen)), listen: false);
    final chapitre = etat.chapitres.first;
    final modules = etat.modulesDuChapitre(chapitre);
    final fiches = modules.fold(0, (s, m) => s + m.fiches.length);
    expect(find.text(chapitre.titre), findsOneWidget);
    expect(find.textContaining('$fiches fiches de ${modules.length} modules'),
        findsOneWidget);
    // Le premier module et ses trois fiches sont là, contenu compris.
    expect(find.text(modules.first.titre), findsOneWidget);
    for (final f in modules.first.fiches) {
      expect(find.text(f.titre), findsOneWidget);
    }
    // Rien n'est marqué comme lu : la fiche de révision se lit sans compter.
    expect(etat.ficheLue(modules.first, modules.first.fiches.first.id), isFalse);
    expect(etat.fichesLuesAujourdhui, 0);

    // Le titre d'un module mène à ce module.
    await tester.tap(find.text(modules.first.titre));
    await tester.pumpAndSettle();
    expect(find.byType(ModuleScreen), findsOneWidget);
  });
}
