import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/data/progression_store.dart';
import 'package:elecapp/data/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppState> etatCharge() async {
    final etat = AppState();
    await etat.charger();
    expect(etat.pret, isTrue, reason: '${etat.erreur}');
    return etat;
  }

  test('au départ, aucune question réussie', () async {
    final etat = await etatCharge();
    final module = etat.modules.first;
    expect(etat.questionsReussies(module), 0);
    expect(etat.moduleTermine(module), isFalse);
    expect(etat.historique, isEmpty);
  });

  test('un quiz enregistre les réussites, le meilleur score et l\'historique',
      () async {
    final etat = await etatCharge();
    final module = etat.modules.first;

    final session = QuizSession(module.questions, melanger: false);
    for (final q in module.questions) {
      // On rate volontairement la première question.
      session.repondre(q == module.questions.first ? (q.bonne + 1) % q.reponses.length : q.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session, moduleComplet: module);

    expect(etat.questionsReussies(module), module.nombreQuestions - 1);
    expect(etat.progressionDe(module).meilleurScore, module.nombreQuestions - 1);
    expect(etat.historique.single.score, module.nombreQuestions - 1);
    expect(etat.historique.single.total, module.nombreQuestions);
    expect(etat.historique.single.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  test('refaire les ratées complète la progression sans toucher au meilleur score',
      () async {
    final etat = await etatCharge();
    final module = etat.modules.first;
    final ratee = module.questions.first;

    final complet = QuizSession(module.questions, melanger: false);
    for (final q in module.questions) {
      complet.repondre(q == ratee ? (q.bonne + 1) % q.reponses.length : q.bonne);
      complet.suivante();
    }
    await etat.enregistrerResultat(complet, moduleComplet: module);

    final rattrapage = QuizSession([ratee], melanger: false);
    rattrapage.repondre(ratee.bonne);
    rattrapage.suivante();
    await etat.enregistrerResultat(rattrapage, moduleComplet: module);

    expect(etat.questionsReussies(module), module.nombreQuestions);
    expect(etat.moduleTermine(module), isTrue);
    expect(etat.progressionDe(module).meilleurScore, module.nombreQuestions - 1);
    expect(etat.historique.length, 2);
  });

  test('la progression survit à un redémarrage', () async {
    final etat1 = await etatCharge();
    final module = etat1.modules.first;
    await etat1.marquerFicheLue(module, 'ohm');

    // Nouvel AppState = nouveau démarrage de l'appli, même stockage.
    final etat2 = AppState(loader: ContentLoader(), store: ProgressionStore());
    await etat2.charger();
    expect(etat2.ficheLue(etat2.modules.first, 'ohm'), isTrue);

    await etat2.reinitialiser();
    final etat3 = AppState();
    await etat3.charger();
    expect(etat3.ficheLue(etat3.modules.first, 'ohm'), isFalse);
  });

  test('révision ciblée : les ratées reviennent jusqu\'à être réussies', () async {
    final etat = await etatCharge();
    final module = etat.modules.first;
    final ratee = module.questions.first;

    final complet = QuizSession(module.questions, melanger: false);
    for (final q in module.questions) {
      complet.repondre(q == ratee ? (q.bonne + 1) % q.reponses.length : q.bonne);
      complet.suivante();
    }
    await etat.enregistrerResultat(complet, moduleComplet: module);

    expect(etat.nombreARevoir, 1);
    expect(etat.questionsARevoir(module).map((q) => q.id), [ratee.id]);
    // La révision commence par les ratées.
    expect(etat.questionsPourRevision().first.id, ratee.id);
    expect(etat.questionsPourRevision().length, AppState.tailleRevision);

    // Séance de révision (sans module) : la ratée est réussie.
    final revision = QuizSession([ratee], melanger: false);
    revision.repondre(ratee.bonne);
    revision.suivante();
    await etat.enregistrerResultat(revision);

    expect(etat.nombreARevoir, 0);
    expect(etat.moduleTermine(module), isTrue);
    expect(etat.historique.last.moduleId, AppState.idRevision);
    // Le meilleur score du module n'a pas bougé (ce n'était pas un quiz complet).
    expect(etat.progressionDe(module).meilleurScore, module.nombreQuestions - 1);
  });

  test('ficheDe retrouve la fiche et le module d\'une question', () async {
    final etat = await etatCharge();
    final q = etat.modules.first.questions.first;
    final cible = etat.ficheDe(q);
    expect(cible, isNotNull);
    expect(cible!.module.id, 'grandeurs');
    expect(cible.fiche.id, q.ficheId);
  });
}
