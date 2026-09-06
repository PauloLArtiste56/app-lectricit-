import 'dart:math';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/data/progression_store.dart';
import 'package:elecapp/data/quiz_session.dart';
import 'package:elecapp/models/question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  mainRevisionEspacee();

  Future<AppState> etatCharge() async {
    final etat = AppState();
    await etat.charger();
    expect(etat.pret, isTrue, reason: '${etat.erreur}');
    return etat;
  }

  test('le parcours déverrouille les modules un à un', () async {
    final etat = await etatCharge();
    final premier = etat.modules.first;
    final chapitre = etat.chapitres.first;
    final deuxieme = etat.modulesDuChapitre(chapitre)[1];
    final troisieme = etat.modulesDuChapitre(chapitre)[2];
    expect(etat.moduleDeverrouille(premier), isTrue);
    expect(etat.moduleDeverrouille(deuxieme), isFalse);
    expect(etat.moduleCourant, premier);
    expect(etat.moduleAvant(deuxieme), premier);

    // 16 bonnes réponses sur 20 : le seuil de 80 % est atteint.
    final session = QuizSession(premier.questions, melanger: false);
    for (final (i, q) in premier.questions.indexed) {
      session.repondre(i < 16 ? q.bonne : (q.bonne + 1) % q.reponses.length);
      session.suivante();
    }
    await etat.enregistrerResultat(session);
    expect(etat.moduleReussi(premier), isTrue);
    expect(etat.moduleTermine(premier), isFalse);
    expect(etat.moduleDeverrouille(deuxieme), isTrue);
    expect(etat.moduleDeverrouille(troisieme), isFalse);
    expect(etat.moduleCourant, deuxieme);
    expect(etat.modulesReussisDans(chapitre), 1);
  });

  test("l'examen blanc tire 20 questions dans les modules déjà abordés",
      () async {
    final etat = await etatCharge();
    // Au départ, seul le premier module est ouvert.
    expect(etat.modulesVus.map((m) => m.id), [etat.modules.first.id]);
    final questions = etat.questionsExamen(random: Random(1));
    expect(questions.length, AppState.tailleExamen);
    expect(questions.map((q) => q.id).toSet().length, AppState.tailleExamen);
    for (final q in questions) {
      expect(etat.moduleDe(q), etat.modules.first);
    }

    // Un examen va dans l'historique sous son propre identifiant.
    final session = QuizSession(questions, melanger: false);
    for (final q in questions) {
      session.repondre(q.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session, examen: true);
    expect(etat.historique.last.moduleId, AppState.idExamen);
  });

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

/// Tests de la révision espacée, avec une horloge simulée.
void mainRevisionEspacee() {
  DateTime maintenant = DateTime(2026, 9, 5);
  Future<AppState> etatCharge() async {
    final etat = AppState(horloge: () => maintenant);
    await etat.charger();
    expect(etat.pret, isTrue, reason: '${etat.erreur}');
    return etat;
  }

  Future<void> jouer(AppState etat, Question q, {required bool juste}) async {
    final s = QuizSession([q], melanger: false);
    s.repondre(juste ? q.bonne : (q.bonne + 1) % q.reponses.length);
    s.suivante();
    await etat.enregistrerResultat(s);
  }

  test('réussite : la question revient plus tard, échec : dès demain', () async {
    maintenant = DateTime(2026, 9, 5);
    final etat = await etatCharge();
    final module = etat.modules.first;
    final q = module.questions.first;

    await jouer(etat, q, juste: true);
    var r = etat.progressionDe(module).revisions[q.id]!;
    expect(r.niveau, 1);
    expect(r.prochaine, '2026-09-06');
    expect(etat.questionsDues(), isEmpty);

    maintenant = DateTime(2026, 9, 6);
    expect(etat.questionsDues().map((x) => x.id), [q.id]);
    await jouer(etat, q, juste: true);
    r = etat.progressionDe(module).revisions[q.id]!;
    expect(r.niveau, 2);
    expect(r.prochaine, '2026-09-09'); // 3 jours au niveau 2

    maintenant = DateTime(2026, 9, 9);
    await jouer(etat, q, juste: true);
    r = etat.progressionDe(module).revisions[q.id]!;
    expect(r.niveau, 3);
    expect(r.prochaine, '2026-09-16'); // 7 jours au niveau 3

    maintenant = DateTime(2026, 9, 16);
    await jouer(etat, q, juste: false);
    r = etat.progressionDe(module).revisions[q.id]!;
    expect(r.niveau, 0);
    expect(r.prochaine, '2026-09-17'); // échec : dès demain
  });

  test('la séance du jour : les dues d\'abord, puis des nouvelles, 10 max', () async {
    maintenant = DateTime(2026, 9, 5);
    final etat = await etatCharge();
    expect(etat.questionsDuJour().length, AppState.tailleSeance);
    expect(etat.nombreDues, 0);

    final q = etat.modules.first.questions.first;
    await jouer(etat, q, juste: false);
    maintenant = DateTime(2026, 9, 6);
    final seance = etat.questionsDuJour();
    expect(seance.first.id, q.id);
    expect(seance.length, AppState.tailleSeance);
    expect(etat.questionsJamaisFaites(), isNot(contains(q)));
  });

  test('série de jours consécutifs', () async {
    maintenant = DateTime(2026, 9, 5);
    final etat = await etatCharge();
    final q = etat.modules.first.questions.first;
    expect(etat.serieJours, 0);

    await jouer(etat, q, juste: true);
    expect(etat.serieJours, 1);
    maintenant = DateTime(2026, 9, 6);
    expect(etat.serieJours, 1); // hier : la série tient encore
    await jouer(etat, q, juste: true);
    expect(etat.serieJours, 2);
    maintenant = DateTime(2026, 9, 8);
    expect(etat.serieJours, 0); // un jour sauté : série cassée
  });

  test('la progression survit à un redémarrage (révisions incluses)', () async {
    maintenant = DateTime(2026, 9, 5);
    final etat = await etatCharge();
    final q = etat.modules.first.questions.first;
    await jouer(etat, q, juste: true);
    final etat2 = AppState(horloge: () => maintenant);
    await etat2.charger();
    expect(etat2.progressionDe(etat2.modules.first).revisions[q.id]?.prochaine, '2026-09-06');
  });
}
