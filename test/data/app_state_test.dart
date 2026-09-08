import 'dart:math';

import 'package:elecapp/data/app_state.dart';
import 'package:elecapp/data/content_loader.dart';
import 'package:elecapp/data/progression_store.dart';
import 'package:elecapp/data/quetes.dart';
import 'package:elecapp/data/quiz_session.dart';
import 'package:elecapp/data/sons.dart';
import 'package:elecapp/models/module.dart';
import 'package:elecapp/models/parametres.dart';
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

  test('les XP viennent de l\'historique et font monter de niveau', () async {
    expect(AppState.niveauPour(0), 1);
    expect(AppState.niveauPour(99), 1);
    expect(AppState.niveauPour(100), 2);
    expect(AppState.niveauPour(400), 3);
    expect(AppState.xpDebutNiveau(3), 400);

    final etat = await etatCharge();
    expect(etat.xpTotal, 0);
    expect(etat.niveau, 1);
    expect(etat.xpManquants, 100);

    final module = etat.modules.first;
    final session = QuizSession(module.questions, melanger: false);
    for (final q in module.questions) {
      session.repondre(q.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session, moduleComplet: module);
    // 20 bonnes réponses = 200 XP, plus les quêtes du jour éventuellement
    // accomplies par ce sans-faute (elles dépendent de la date).
    final bonus = etat.recompenses.fold(0, (s, r) => s + r.xp);
    expect(etat.xpTotal, 200 + bonus);
    expect(etat.niveau, AppState.niveauPour(etat.xpTotal));
    expect(etat.niveau, greaterThanOrEqualTo(2));
    expect(etat.xpManquants, AppState.xpDebutNiveau(etat.niveau + 1) - etat.xpTotal);
  });

  test('l\'objectif du jour suit les XP gagnés aujourd\'hui', () async {
    final etat = AppState(horloge: () => DateTime(2026, 9, 6));
    await etat.charger();
    expect(etat.objectifJour, 50);
    expect(etat.xpDuJour, 0);
    expect(etat.objectifAtteint, isFalse);
    expect(etat.progressionObjectif, 0);

    final module = etat.modules.first;
    final session = QuizSession(module.questions.take(3).toList(), melanger: false);
    for (final q in session.questions) {
      session.repondre(q.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session);
    // 3 bonnes réponses = 30 XP, plus une éventuelle quête accomplie.
    final bonus = etat.recompenses.fold(0, (s, r) => s + r.xp);
    expect(etat.xpDuJour, 30 + bonus);
    expect(etat.progressionObjectif,
        closeTo(((30 + bonus) / 50).clamp(0.0, 1.0), 0.001));

    await etat.modifierParametres(const Parametres(objectifXpJour: 20));
    expect(etat.objectifAtteint, isTrue);
    expect(etat.progressionObjectif, 1);
  });

  test('les quêtes du jour versent leur XP une seule fois et les badges restent',
      () async {
    final etat = AppState(horloge: () => DateTime(2026, 9, 6));
    await etat.charger();
    final quetes = etat.quetesDuJour;
    expect(quetes.length, 3);
    expect(quetes.every((q) => !q.accomplie), isTrue);
    expect(etat.badgesObtenus, isEmpty);

    // On remplit toutes les quêtes possibles : trois fiches, une révision,
    // un examen, deux quiz complets sans faute (module réussi, 100 XP).
    final module = etat.modules.first;
    for (final f in module.fiches) {
      await etat.marquerFicheLue(module, f.id);
    }
    expect(etat.fichesLuesAujourdhui, 3);

    Future<void> quiz(List<Question> questions,
        {Module? moduleComplet, bool examen = false}) async {
      final session = QuizSession(questions, melanger: false);
      for (final q in questions) {
        session.repondre(q.bonne);
        session.suivante();
      }
      await etat.enregistrerResultat(session,
          moduleComplet: moduleComplet, examen: examen);
    }

    await quiz(module.questions.take(5).toList());
    await quiz(module.questions.take(5).toList(), examen: true);
    await quiz(module.questions, moduleComplet: module);
    await quiz(module.questions, moduleComplet: module);

    expect(etat.quetesDuJour.every((q) => q.accomplie), isTrue);
    expect(etat.recompenses.length, 3);
    expect(etat.quetesAccomplies, 3);
    final xpQuetes = etat.quetesDuJour.fold(0, (s, q) => s + q.quete.xp);
    final xpQuiz = etat.historique.fold(0, (s, e) => s + AppState.xpPour(e.score));
    expect(etat.xpTotal, xpQuiz + xpQuetes);
    expect(etat.xpDuJour, etat.xpTotal);

    // Un quiz de plus ne reverse rien.
    await quiz(module.questions.take(2).toList());
    expect(etat.recompenses.length, 3);
    expect(etat.recompensesRecentes, isEmpty);

    // Badges débloqués par ce parcours, avec la date du jour.
    expect(etat.badgesObtenus.keys,
        containsAll(['premier_quiz', 'premier_module', 'sans_faute', 'examen']));
    expect(etat.badgesObtenus['premier_quiz'], '2026-09-06');
    expect(etat.badgesObtenus.containsKey('serie_7'), isFalse);

    // Tout est bien enregistré : un nouvel état relit quêtes et badges.
    final etat2 = AppState(horloge: () => DateTime(2026, 9, 6));
    await etat2.charger();
    expect(etat2.recompenses.length, 3);
    expect(etat2.quetesDuJour.every((q) => q.accomplie), isTrue);
    expect(etat2.badgesObtenus.length, etat.badgesObtenus.length);
    expect(etat2.xpTotal, etat.xpTotal);

    // Le lendemain, trois nouvelles quêtes repartent de zéro.
    final etat3 = AppState(horloge: () => DateTime(2026, 9, 7));
    await etat3.charger();
    expect(etat3.quetesDuJour.every((q) => !q.accomplie), isTrue);
    expect(etat3.xpDuJour, 0);
  });

  test('les sons respectent le réglage', () async {
    final sons = Sons(actif: false);
    final etat = AppState(sons: sons);
    await etat.charger();
    etat.jouer(Son.bonne);
    expect(sons.joues, [Son.bonne]);
    await etat.modifierParametres(const Parametres(sons: false));
    etat.jouer(Son.mauvaise);
    expect(sons.joues, [Son.bonne]);
  });

  test('cas pratiques : chargés, résolus à 80 %, et cartes « à revoir »', () async {
    final etat = await etatCharge();
    expect(etat.casPratiques.length, greaterThanOrEqualTo(10));
    expect(etat.casResolus, 0);
    final cas = etat.casPratiques.first;
    expect(etat.casParId(cas.id), same(cas));

    // 2 bonnes sur 4 : pas résolu.
    var session = QuizSession(cas.etapes, melanger: false);
    for (var i = 0; i < cas.etapes.length; i++) {
      session.repondre(i < 2 ? cas.etapes[i].bonne : (cas.etapes[i].bonne + 1) % 4);
      session.suivante();
    }
    await etat.enregistrerResultat(session, cas: cas);
    expect(etat.casResolu(cas), isFalse);
    expect(etat.historique.last.moduleId, 'cas:${cas.id}');
    // Les étapes ne sont pas des questions de module : rien dans la progression.
    expect(etat.totalReussies, 0);

    // Puis sans faute : résolu.
    session = QuizSession(cas.etapes, melanger: false);
    for (final e in cas.etapes) {
      session.repondre(e.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session, cas: cas);
    expect(etat.casResolu(cas), isTrue);
    expect(etat.casResolus, 1);

    // « À revoir » sur une carte : la question rejoint les points faibles.
    final q = etat.modules.first.questions.first;
    expect(etat.nombreARevoir, 0);
    await etat.marquerARevoir(q);
    expect(etat.nombreARevoir, 1);
    expect(etat.questionsPourRevision(), contains(q));
    final relu = AppState();
    await relu.charger();
    expect(relu.nombreARevoir, 1);
  });

  test('couronnes : réussi, sans faute, puis confirmé en révision', () async {
    var maintenant = DateTime(2026, 9, 6);
    final etat = AppState(horloge: () => maintenant);
    await etat.charger();
    final module = etat.modules.first;
    expect(etat.couronnes(module), 0);
    expect(etat.prochaineCouronne(module), contains('80 %'));
    expect(etat.couronnesMax, etat.modulesAvecContenu.length * 3);
    expect(etat.glossaire.length, greaterThanOrEqualTo(60));

    Future<void> quiz({int ratees = 0}) async {
      final session = QuizSession(module.questions, melanger: false);
      for (var i = 0; i < module.questions.length; i++) {
        final q = module.questions[i];
        session.repondre(i < ratees ? (q.bonne + 1) % q.reponses.length : q.bonne);
        session.suivante();
      }
      await etat.enregistrerResultat(session, moduleComplet: module);
    }

    // 17/20 : réussi, une couronne.
    await quiz(ratees: 3);
    expect(etat.couronnes(module), 1);
    expect(etat.prochaineCouronne(module), contains('sans faute'));
    // Sans faute : deux couronnes, mais chaque question n'est réussie qu'une
    // ou deux fois : pas encore confirmé.
    await quiz();
    expect(etat.couronnes(module), 2);
    expect(etat.couronnesTotal, 2);
    // Le lendemain, tout est réussi une fois de plus : niveau ≥ 2 partout.
    maintenant = DateTime(2026, 9, 8);
    await quiz();
    expect(etat.couronnes(module), 3);
    expect(etat.prochaineCouronne(module), isNull);
    expect(etat.badgesObtenus.keys, contains('triple_couronne'));
  });

  test('un gel de série comble un jour manqué, deux gels deux jours, pas plus',
      () async {
    var maintenant = DateTime(2026, 9, 1);
    final etat = AppState(horloge: () => maintenant);
    await etat.charger();
    final module = etat.modules.first;
    Future<void> quiz() async {
      final session = QuizSession(module.questions, melanger: false);
      for (final q in module.questions) {
        session.repondre(q.bonne);
        session.suivante();
      }
      await etat.enregistrerResultat(session, moduleComplet: module);
    }

    await quiz(); // 1er septembre : 200 XP
    expect(etat.serieJours, 1);
    expect(etat.peutAcheterGel(), isTrue);
    expect(await etat.acheterGel(), isTrue);
    expect(await etat.acheterGel(), isTrue);
    expect(etat.gels, 2);
    expect(etat.xpDisponibles, etat.xpTotal - 2 * AppState.prixGel);
    expect(etat.xpDepenses, 2 * AppState.prixGel);
    // Deux au maximum.
    expect(await etat.acheterGel(), isFalse);

    // Le 2 est manqué ; le 3, la série tient grâce à un gel.
    maintenant = DateTime(2026, 9, 3);
    await quiz();
    expect(etat.gels, 1);
    expect(etat.gelsUtilises, ['2026-09-02']);
    expect(etat.serieJours, 3);

    // Les 4 et 5 manqués : un seul gel, la série est perdue, le gel gardé.
    maintenant = DateTime(2026, 9, 6);
    final relu = AppState(horloge: () => maintenant);
    await relu.charger();
    expect(relu.gels, 1);
    expect(relu.serieJours, 0);
  });

  test('statistiques par chapitre et chapitre le plus faible', () async {
    final etat = await etatCharge();
    final chapitre = etat.chapitres.first;
    final modules = etat.modulesDuChapitre(chapitre);
    expect(etat.questionsDansChapitre(chapitre),
        modules.fold(0, (s, m) => s + m.nombreQuestions));
    expect(etat.reussiesDansChapitre(chapitre), 0);
    expect(etat.scoreChapitre(chapitre), 0);
    // Rien de commencé : aucun chapitre à travailler en priorité.
    expect(etat.chapitreLePlusFaible, isNull);

    // 10 questions réussies dans le premier module du chapitre.
    final module = modules.first;
    final session = QuizSession(module.questions.take(10).toList(), melanger: false);
    for (final q in session.questions) {
      session.repondre(q.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session);
    expect(etat.reussiesDansChapitre(chapitre), 10);
    expect(etat.scoreChapitre(chapitre),
        closeTo(10 / etat.questionsDansChapitre(chapitre), 0.0001));
    // Seul chapitre commencé, donc le plus faible.
    expect(etat.chapitreLePlusFaible, same(chapitre));
    for (final autre in etat.chapitres.skip(1)) {
      expect(etat.scoreChapitre(autre), 0);
    }
  });

  test('les quêtes d\'un jour sont toujours les mêmes trois', () {
    final a = Quete.pourLeJour('2026-09-06').map((q) => q.id).toList();
    final b = Quete.pourLeJour('2026-09-06').map((q) => q.id).toList();
    expect(a, b);
    expect(a.toSet().length, 3);
    // Sur une semaine, le tirage change au moins une fois.
    final ids = {
      for (var j = 1; j <= 7; j++)
        Quete.pourLeJour('2026-09-0$j').map((q) => q.id).join(','),
    };
    expect(ids.length, greaterThan(1));
  });

  test('le récap de la semaine additionne les XP et les quiz par jour', () async {
    var maintenant = DateTime(2026, 9, 6); // un dimanche
    final etat = AppState(horloge: () => maintenant);
    await etat.charger();
    expect(etat.semaine.length, 7);
    expect(etat.semaine.last.date.day, 6);
    expect(etat.semaine.first.date.weekday, DateTime.monday);
    expect(etat.xpSemaine, 0);

    final module = etat.modules.first;
    Future<void> quiz() async {
      final session = QuizSession(module.questions, melanger: false);
      for (final q in module.questions) {
        session.repondre(q.bonne);
        session.suivante();
      }
      await etat.enregistrerResultat(session, moduleComplet: module);
    }

    await quiz(); // dimanche 6 : 200 XP
    maintenant = DateTime(2026, 9, 8); // mardi
    await quiz();
    await quiz(); // mardi 8 : 400 XP
    expect(etat.xpSemaine, 600);
    expect(etat.quizSemaine, 3);
    expect(etat.joursActifsSemaine, 2);
    expect(etat.semaine.last.xp, 400);

    // Huit jours plus tard, le quiz du 6 est sorti de la fenêtre.
    maintenant = DateTime(2026, 9, 14);
    expect(etat.xpSemaine, 400);
    expect(etat.joursActifsSemaine, 1);
  });

  test('les paramètres changent la séance, l\'examen et le parcours', () async {
    final etat = await etatCharge();
    expect(etat.parametres.tailleSeance, AppState.tailleSeance);
    final deuxieme = etat.modulesDuChapitre(etat.chapitres.first)[1];
    expect(etat.moduleDeverrouille(deuxieme), isFalse);

    await etat.modifierParametres(const Parametres(
      tailleSeance: 5,
      tailleExamen: 10,
      parcoursLibre: true,
    ));
    expect(etat.questionsDuJour().length, 5);
    expect(etat.questionsExamen().length, 10);
    expect(etat.moduleDeverrouille(deuxieme), isTrue);

    // Les paramètres sont relus au prochain démarrage.
    final etat2 = await etatCharge();
    expect(etat2.parametres.parcoursLibre, isTrue);
    expect(etat2.parametres.tailleSeance, 5);
  });

  test('export puis import restituent la progression', () async {
    final etat = await etatCharge();
    final module = etat.modules.first;
    final session = QuizSession(module.questions, melanger: false);
    for (final q in module.questions) {
      session.repondre(q.bonne);
      session.suivante();
    }
    await etat.enregistrerResultat(session, moduleComplet: module);
    final code = etat.exporterProgression();

    await etat.reinitialiser();
    expect(etat.questionsReussies(module), 0);
    expect(await etat.importerProgression('pas du json'), isFalse);
    expect(await etat.importerProgression('{"autre": 1}'), isFalse);
    expect(etat.questionsReussies(module), 0);

    expect(await etat.importerProgression(code), isTrue);
    expect(etat.questionsReussies(module), module.nombreQuestions);
    expect(etat.historique.length, 1);
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
