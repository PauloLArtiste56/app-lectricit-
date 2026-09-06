import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/cas_pratique.dart';
import '../models/chapitre.dart';
import '../models/entree_historique.dart';
import '../models/fiche.dart';
import '../models/module.dart';
import '../models/parametres.dart';
import '../models/progression.dart';
import '../models/progression_module.dart';
import '../models/question.dart';
import '../models/recompense.dart';
import '../models/revision_question.dart';
import 'insignes.dart';
import 'content_loader.dart';
import 'progression_store.dart';
import 'quetes.dart';
import 'quiz_session.dart';
import 'sons.dart';

/// État partagé de l'appli : le contenu (modules) et la progression.
/// Les écrans lisent ici et appellent les méthodes ci-dessous ; ils ne
/// touchent jamais directement au stockage.
class AppState extends ChangeNotifier {
  AppState({
    ContentLoader? loader,
    ProgressionStore? store,
    DateTime Function()? horloge,
    Sons? sons,
  })  : _loader = loader ?? ContentLoader(),
        _store = store ?? ProgressionStore(),
        _horloge = horloge ?? DateTime.now,
        sons = sons ?? Sons();

  final ContentLoader _loader;
  final ProgressionStore _store;

  /// Injectable dans les tests pour simuler le passage des jours.
  final DateTime Function() _horloge;

  /// Lecteur de sons ; injectable dans les tests.
  final Sons sons;

  /// Joue un son si l'utilisateur ne les a pas coupés.
  void jouer(Son son) {
    if (_parametres.sons) sons.jouer(son);
  }

  /// Nombre de questions d'une séance du jour.
  static const int tailleSeance = 10;

  /// Identifiant utilisé dans l'historique pour une séance de révision
  /// (questions de plusieurs modules).
  static const String idRevision = 'revision';

  /// Nombre maximum de questions dans une séance de révision.
  static const int tailleRevision = 15;

  /// Identifiant utilisé dans l'historique pour un examen blanc.
  static const String idExamen = 'examen';

  /// Identifiant du mode éclair dans l'historique.
  static const String idEclair = 'eclair';

  /// Mode éclair : 10 questions, 10 secondes chacune.
  static const int questionsParEclair = 10;
  static const Duration dureeQuestionEclair = Duration(seconds: 10);

  /// Préfixe des cas pratiques dans l'historique : `cas:<id>`.
  static const String prefixeCas = 'cas:';

  /// Un examen blanc : [tailleExamen] questions en [dureeExamen].
  static const int tailleExamen = 20;
  static const Duration dureeExamen = Duration(minutes: 10);

  /// Points d'expérience gagnés par bonne réponse, dans n'importe quel quiz.
  static const int xpParBonneReponse = 10;

  /// XP rapportés par un quiz.
  static int xpPour(int score) => score * xpParBonneReponse;

  /// Niveau atteint avec [xp] points : 1 au départ, 2 à 100 XP, 3 à 400,
  /// 4 à 900… (100 × (niveau − 1)²). Chaque niveau demande un peu plus.
  static int niveauPour(int xp) => sqrt(xp / 100).floor() + 1;

  /// XP nécessaires pour entrer dans [niveau].
  static int xpDebutNiveau(int niveau) => 100 * (niveau - 1) * (niveau - 1);

  /// Part des questions à réussir pour qu'un module compte comme réussi
  /// sur le parcours (16 questions sur 20).
  static const double seuilReussite = 0.8;

  List<Module> _modules = [];
  List<Chapitre> _chapitres = [];

  /// Identifiants des modules dans l'ordre du chemin, tous chapitres
  /// confondus : c'est cet ordre qui déverrouille les modules un à un.
  List<String> _ordreParcours = [];
  final Map<String, Module> _moduleParQuestion = {};
  Progression _progression = Progression();
  Parametres _parametres = const Parametres();
  bool _pret = false;
  Object? _erreur;

  List<Module> get modules => _modules;

  /// Chapitres du parcours, dans l'ordre du chemin.
  List<Chapitre> get chapitres => _chapitres;
  bool get pret => _pret;
  Object? get erreur => _erreur;
  Parametres get parametres => _parametres;
  List<EntreeHistorique> get historique => _progression.historique;

  /// À appeler une fois au démarrage.
  Future<void> charger() async {
    try {
      _modules = await _loader.chargerModules();
      _chapitres = await _loader.chargerParcours();
      _casPratiques = await _loader.chargerCasPratiques();
      _ordreParcours = [for (final c in _chapitres) ...c.modulesIds];
      for (final m in _modules) {
        for (final q in m.questions) {
          _moduleParQuestion[q.id] = m;
        }
      }
      _progression = await _store.charger();
      _parametres = await _store.chargerParametres();
      _pret = true;
    } catch (e) {
      _erreur = e;
    }
    notifyListeners();
  }

  ProgressionModule progressionDe(Module module) => _progression.pour(module.id);

  Future<void> modifierParametres(Parametres nouveaux) async {
    _parametres = nouveaux;
    await _store.sauvegarderParametres(nouveaux);
    notifyListeners();
  }

  /// La progression en JSON, à copier pour la transférer sur un autre
  /// appareil.
  String exporterProgression() => jsonEncode(_progression.toJson());

  /// Remplace la progression par celle d'un export. Faux si le texte n'est
  /// pas un export valide (rien n'est modifié dans ce cas).
  Future<bool> importerProgression(String texte) async {
    try {
      final decode = jsonDecode(texte);
      if (decode is! Map<String, dynamic> || !decode.containsKey('progression')) {
        return false;
      }
      _progression = Progression.fromJson(decode);
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
    await _sauvegarder();
    return true;
  }

  Module? moduleParId(String id) {
    for (final m in _modules) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Module auquel appartient une question.
  Module? moduleDe(Question question) => _moduleParQuestion[question.id];

  /// Modules d'un chapitre, dans l'ordre du parcours. Un identifiant inconnu
  /// est ignoré plutôt que de faire planter l'écran.
  List<Module> modulesDuChapitre(Chapitre chapitre) =>
      [for (final id in chapitre.modulesIds) ?moduleParId(id)];

  /// Fiche à laquelle se rapporte une question, et son module.
  ({Module module, Fiche fiche, int index})? ficheDe(Question question) {
    final module = moduleDe(question);
    if (module == null) return null;
    final index = module.fiches.indexWhere((f) => f.id == question.ficheId);
    if (index < 0) return null;
    return (module: module, fiche: module.fiches[index], index: index);
  }

  /// Nombre de questions du module déjà réussies au moins une fois.
  int questionsReussies(Module module) {
    final reussies = progressionDe(module).questionsReussies;
    return module.questions.where((q) => reussies.contains(q.id)).length;
  }

  /// Questions du module à retravailler : jamais réussies, ou ratées à la
  /// dernière tentative.
  List<Question> questionsARevoir(Module module) {
    final p = progressionDe(module);
    return module.questions
        .where((q) =>
            !p.questionsReussies.contains(q.id) ||
            p.questionsARevoir.contains(q.id))
        .toList();
  }

  /// Points faibles tous modules confondus, pour la révision ciblée.
  /// Priorité aux questions ratées récemment, puis à celles jamais faites.
  List<Question> questionsPourRevision() {
    final ratees = <Question>[];
    final jamaisFaites = <Question>[];
    for (final m in modulesAvecContenu) {
      final p = progressionDe(m);
      for (final q in m.questions) {
        if (p.questionsARevoir.contains(q.id)) {
          ratees.add(q);
        } else if (!p.questionsReussies.contains(q.id)) {
          jamaisFaites.add(q);
        }
      }
    }
    ratees.shuffle();
    jamaisFaites.shuffle();
    return [...ratees, ...jamaisFaites].take(tailleRevision).toList();
  }

  /// Nombre de questions actuellement ratées (à revoir), tous modules.
  int get nombreARevoir => modulesAvecContenu.fold(
      0, (n, m) => n + progressionDe(m).questionsARevoir.length);

  // --- Séance du jour (révision espacée) --------------------------------

  /// Questions dont la date de révision est arrivée (ou dépassée).
  List<Question> questionsDues() {
    final aujourdhui = _aujourdhui();
    final dues = <(String, Question)>[];
    for (final m in modulesAvecContenu) {
      final p = progressionDe(m);
      for (final q in m.questions) {
        final r = p.revisions[q.id];
        if (r != null && r.prochaine.compareTo(aujourdhui) <= 0) {
          dues.add((r.prochaine, q));
        }
      }
    }
    // Les plus en retard d'abord.
    dues.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final d in dues) d.$2];
  }

  int get nombreDues => questionsDues().length;

  /// Questions jamais faites, tous modules, dans l'ordre des modules.
  List<Question> questionsJamaisFaites() {
    return [
      for (final m in modulesAvecContenu)
        for (final q in m.questions)
          if (!progressionDe(m).revisions.containsKey(q.id)) q,
    ];
  }

  /// La séance du jour : d'abord ce qui est à revoir aujourd'hui, puis des
  /// questions jamais faites, jusqu'à [tailleSeance].
  List<Question> questionsDuJour() {
    final taille = _parametres.tailleSeance;
    final dues = questionsDues().take(taille).toList();
    final nouvelles = questionsJamaisFaites()..shuffle();
    return [...dues, ...nouvelles.take(taille - dues.length)];
  }

  /// Modules déjà abordés : déverrouillés sur le parcours, ou commencés
  /// depuis l'onglet Modules.
  List<Module> get modulesVus => [
        for (final m in modulesAvecContenu)
          if (moduleDeverrouille(m) || questionsReussies(m) > 0) m,
      ];

  /// Questions d'un examen blanc : tirées au hasard dans les modules déjà
  /// abordés, sans correction immédiate. [random] est injectable pour les
  /// tests.
  List<Question> questionsExamen({Random? random}) {
    final toutes = [for (final m in modulesVus) ...m.questions]
      ..shuffle(random ?? Random());
    return toutes.take(_parametres.tailleExamen).toList();
  }

  /// Questions d'un mode éclair : tirées dans les modules déjà abordés,
  /// sans les questions « ordre » (trop longues en 10 secondes).
  List<Question> questionsEclair({Random? random}) {
    final toutes = [
      for (final m in modulesVus)
        for (final q in m.questions)
          if (q.type != TypeQuestion.ordre) q,
    ]..shuffle(random ?? Random());
    return toutes.take(questionsParEclair).toList();
  }

  /// Meilleur score obtenu en mode éclair (0 si jamais joué).
  int get meilleurEclair => _progression.historique
      .where((e) => e.moduleId == idEclair)
      .fold(0, (m, e) => e.score > m ? e.score : m);

  // --- Cas pratiques --------------------------------------------------------

  List<CasPratique> _casPratiques = [];
  List<CasPratique> get casPratiques => List.unmodifiable(_casPratiques);

  CasPratique? casParId(String id) {
    for (final c in _casPratiques) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Un cas est résolu dès qu'une tentative atteint le seuil de réussite.
  bool casResolu(CasPratique cas) => _progression.historique.any((e) =>
      e.moduleId == '$prefixeCas${cas.id}' &&
      e.score >= e.total * seuilReussite);

  int get casResolus => _casPratiques.where(casResolu).length;

  /// Cartes à retourner : « À revoir » remet la question dans les points
  /// faibles et la programme pour demain.
  Future<void> marquerARevoir(Question question) async {
    final module = moduleDe(question);
    if (module == null) return;
    final p = progressionDe(module);
    p.questionsARevoir.add(question.id);
    p.revisions[question.id] = RevisionQuestion(niveau: 0, prochaine: _dansJours(1));
    await _sauvegarder();
  }

  /// Total des XP : les quiz de l'historique plus les récompenses.
  int get xpTotal =>
      _progression.historique.fold(0, (somme, e) => somme + xpPour(e.score)) +
      _progression.recompenses.fold(0, (somme, r) => somme + r.xp);

  List<Recompense> get recompenses => List.unmodifiable(_progression.recompenses);

  /// Récompenses et badges gagnés lors du dernier enregistrement, pour
  /// les afficher sur l'écran Résultat. Vidés à chaque nouveau quiz.
  List<Recompense> recompensesRecentes = [];
  List<Insigne> badgesRecents = [];

  // --- Objectif du jour ---------------------------------------------------

  /// XP gagnés aujourd'hui, quiz et récompenses compris.
  int get xpDuJour {
    final jour = _aujourdhui();
    return _progression.historique
            .where((e) => e.date == jour)
            .fold(0, (somme, e) => somme + xpPour(e.score)) +
        _progression.recompenses
            .where((r) => r.date == jour)
            .fold(0, (somme, r) => somme + r.xp);
  }

  int get objectifJour => _parametres.objectifXpJour;
  bool get objectifAtteint => xpDuJour >= objectifJour;
  double get progressionObjectif => (xpDuJour / objectifJour).clamp(0.0, 1.0);

  // --- Quêtes du jour ------------------------------------------------------

  /// Fiches marquées lues aujourd'hui (pour la quête « Lis 3 fiches »).
  final Set<String> _fichesLuesCeJour = {};
  String _jourFiches = '';

  int get fichesLuesAujourdhui =>
      _jourFiches == _aujourdhui() ? _fichesLuesCeJour.length : 0;

  List<EntreeHistorique> get _quizDuJour {
    final jour = _aujourdhui();
    return _progression.historique.where((e) => e.date == jour).toList();
  }

  /// Les trois quêtes d'aujourd'hui, avec leur avancement.
  List<EtatQuete> get quetesDuJour {
    final jour = _aujourdhui();
    final quiz = _quizDuJour;
    return [
      for (final q in Quete.pourLeJour(jour))
        () {
          final avancement = q.mesurer(quiz, this);
          final accomplie = _progression.recompenses
              .any((r) => r.id == 'quete:${q.id}:$jour');
          return EtatQuete(
            quete: q,
            avancement: accomplie ? q.cible : avancement,
            accomplie: accomplie,
          );
        }(),
    ];
  }

  /// Nombre total de quêtes accomplies depuis le début.
  int get quetesAccomplies =>
      _progression.recompenses.where((r) => r.id.startsWith('quete:')).length;

  // --- Badges --------------------------------------------------------------

  /// Badges obtenus : identifiant → date.
  Map<String, String> get badgesObtenus => Map.unmodifiable(_progression.badges);

  int get modulesReussisTotal => modulesAvecContenu.where(moduleReussi).length;

  /// Verse les récompenses des quêtes accomplies et débloque les badges
  /// dont la condition vient d'être remplie. Appelé après chaque
  /// enregistrement ; ne verse jamais deux fois la même récompense.
  void _verifierQuetesEtBadges() {
    final jour = _aujourdhui();
    recompensesRecentes = [];
    badgesRecents = [];
    final quiz = _quizDuJour;
    for (final q in Quete.pourLeJour(jour)) {
      final id = 'quete:${q.id}:$jour';
      if (_progression.recompenses.any((r) => r.id == id)) continue;
      if (q.mesurer(quiz, this) >= q.cible) {
        final r = Recompense(id: id, date: jour, xp: q.xp);
        _progression.recompenses.add(r);
        recompensesRecentes.add(r);
      }
    }
    for (final b in Insigne.tous) {
      if (_progression.badges.containsKey(b.id)) continue;
      if (b.condition(this)) {
        _progression.badges[b.id] = jour;
        badgesRecents.add(b);
      }
    }
  }


  int get niveau => niveauPour(xpTotal);

  /// XP qu'il manque pour le niveau suivant.
  int get xpManquants => xpDebutNiveau(niveau + 1) - xpTotal;

  /// Avancement dans le niveau en cours, entre 0 et 1.
  double get progressionNiveau {
    final debut = xpDebutNiveau(niveau);
    final fin = xpDebutNiveau(niveau + 1);
    return (xpTotal - debut) / (fin - debut);
  }

  /// Les 7 derniers jours (aujourd'hui en dernier) : XP gagnés et nombre
  /// de quiz chaque jour, pour le récap hebdomadaire des stats.
  List<JourActivite> get semaine {
    final parDate = <String, List<EntreeHistorique>>{};
    for (final e in _progression.historique) {
      parDate.putIfAbsent(e.date, () => []).add(e);
    }
    return [
      for (var i = 6; i >= 0; i--)
        () {
          final jour = _horloge().subtract(Duration(days: i));
          final entrees = parDate[_formater(jour)] ?? const [];
          return JourActivite(
            date: jour,
            xp: entrees.fold(0, (somme, e) => somme + xpPour(e.score)),
            quiz: entrees.length,
          );
        }(),
    ];
  }

  int get xpSemaine => semaine.fold(0, (somme, j) => somme + j.xp);
  int get quizSemaine => semaine.fold(0, (somme, j) => somme + j.quiz);
  int get joursActifsSemaine => semaine.where((j) => j.quiz > 0).length;

  /// Nombre de jours consécutifs (jusqu'à aujourd'hui ou hier) avec au moins
  /// un quiz. 0 si la série est cassée.
  int get serieJours {
    final jours = _progression.historique.map((e) => e.date).toSet();
    var jour = _horloge();
    if (!jours.contains(_formater(jour))) {
      jour = jour.subtract(const Duration(days: 1));
      if (!jours.contains(_formater(jour))) return 0;
    }
    var serie = 0;
    while (jours.contains(_formater(jour))) {
      serie++;
      jour = jour.subtract(const Duration(days: 1));
    }
    return serie;
  }

  bool moduleTermine(Module module) =>
      module.nombreQuestions > 0 &&
      questionsReussies(module) == module.nombreQuestions;

  /// Réussi au sens du parcours : au moins [seuilReussite] des questions.
  bool moduleReussi(Module module) =>
      module.nombreQuestions > 0 &&
      questionsReussies(module) >= module.nombreQuestions * seuilReussite;

  /// Nombre de modules réussis dans un chapitre.
  int modulesReussisDans(Chapitre chapitre) =>
      modulesDuChapitre(chapitre).where(moduleReussi).length;

  /// Module qui précède [module] sur le chemin, ou null pour le premier
  /// (et pour un module absent du parcours).
  Module? moduleAvant(Module module) {
    final i = _ordreParcours.indexOf(module.id);
    if (i <= 0) return null;
    return moduleParId(_ordreParcours[i - 1]);
  }

  /// Module qui suit [module] sur le chemin, ou null pour le dernier.
  Module? moduleSuivant(Module module) {
    final i = _ordreParcours.indexOf(module.id);
    if (i < 0 || i + 1 >= _ordreParcours.length) return null;
    return moduleParId(_ordreParcours[i + 1]);
  }

  /// Chapitre du parcours qui contient [module].
  Chapitre? chapitreDe(Module module) {
    for (final c in _chapitres) {
      if (c.modulesIds.contains(module.id)) return c;
    }
    return null;
  }

  bool chapitreComplet(Chapitre chapitre) {
    final modules = modulesDuChapitre(chapitre);
    return modules.isNotEmpty && modules.every(moduleReussi);
  }

  /// Déverrouillé quand le module précédent du chemin est réussi.
  /// Le premier module, et tout module hors parcours, sont toujours ouverts.
  bool moduleDeverrouille(Module module) {
    if (_parametres.parcoursLibre) return true;
    final avant = moduleAvant(module);
    return avant == null || moduleReussi(avant);
  }

  /// Module « en cours » du parcours : le premier déverrouillé mais pas
  /// encore réussi. Null quand tout le chemin est réussi.
  Module? get moduleCourant {
    for (final id in _ordreParcours) {
      final m = moduleParId(id);
      if (m == null) continue;
      if (!moduleReussi(m)) return moduleDeverrouille(m) ? m : null;
    }
    return null;
  }

  bool ficheLue(Module module, String ficheId) =>
      progressionDe(module).fichesLues.contains(ficheId);

  Future<void> marquerFicheLue(Module module, String ficheId) async {
    final jour = _aujourdhui();
    if (_jourFiches != jour) {
      _jourFiches = jour;
      _fichesLuesCeJour.clear();
    }
    final nouvelleCeJour = _fichesLuesCeJour.add('${module.id}/$ficheId');
    final jamaisLue = progressionDe(module).fichesLues.add(ficheId);
    if (!nouvelleCeJour && !jamaisLue) return;
    _verifierQuetesEtBadges();
    await _sauvegarder();
  }

  /// Enregistre la fin d'un quiz. Chaque question met à jour son propre
  /// module (réussie / à revoir). Le meilleur score n'est mis à jour que
  /// pour un quiz complet d'un module ([moduleComplet]).
  /// [examen] : le quiz était un examen blanc (historique à part).
  Future<void> enregistrerResultat(QuizSession session,
      {Module? moduleComplet,
      bool examen = false,
      bool eclair = false,
      CasPratique? cas}) async {
    final ratees = session.questionsRatees.map((q) => q.id).toSet();
    for (final q in session.questions) {
      // Une question inconnue de l'index (contenu de test) est rattachée
      // au module du quiz.
      final module = moduleDe(q) ?? moduleComplet;
      if (module == null) continue;
      final p = progressionDe(module);
      final niveauActuel = p.revisions[q.id]?.niveau ?? 0;
      if (ratees.contains(q.id)) {
        p.questionsARevoir.add(q.id);
        // Retour au niveau 0 : à revoir dès demain.
        p.revisions[q.id] = RevisionQuestion(niveau: 0, prochaine: _dansJours(1));
      } else {
        p.questionsReussies.add(q.id);
        p.questionsARevoir.remove(q.id);
        final niveau = niveauActuel + 1;
        p.revisions[q.id] = RevisionQuestion(
          niveau: niveau,
          prochaine: _dansJours(RevisionQuestion.intervallePour(niveau)),
        );
      }
    }
    if (moduleComplet != null &&
        session.total == moduleComplet.nombreQuestions) {
      final p = progressionDe(moduleComplet);
      if (session.score > p.meilleurScore) p.meilleurScore = session.score;
    }
    _progression.historique.add(EntreeHistorique(
      moduleId: moduleComplet?.id ??
          (cas != null
              ? '$prefixeCas${cas.id}'
              : examen
                  ? idExamen
                  : eclair
                      ? idEclair
                      : idRevision),
      date: _aujourdhui(),
      score: session.score,
      total: session.total,
    ));
    _verifierQuetesEtBadges();
    await _sauvegarder();
  }

  Future<void> reinitialiser() async {
    _progression = Progression();
    await _store.effacer();
    notifyListeners();
  }

  // --- Statistiques globales -------------------------------------------

  /// Modules qui ont du contenu (les modules vides ne comptent pas).
  List<Module> get modulesAvecContenu =>
      _modules.where((m) => m.nombreQuestions > 0).toList();

  int get totalQuestions =>
      modulesAvecContenu.fold(0, (somme, m) => somme + m.nombreQuestions);

  int get totalReussies =>
      modulesAvecContenu.fold(0, (somme, m) => somme + questionsReussies(m));

  /// Entre 0 et 1.
  double get scoreGlobal =>
      totalQuestions == 0 ? 0 : totalReussies / totalQuestions;

  int get modulesTermines => modulesAvecContenu.where(moduleTermine).length;

  Future<void> _sauvegarder() async {
    await _store.sauvegarder(_progression);
    notifyListeners();
  }

  String _aujourdhui() => _formater(_horloge());

  String _dansJours(int n) => _formater(_horloge().add(Duration(days: n)));

  static String _formater(DateTime d) {
    String deux(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${deux(d.month)}-${deux(d.day)}';
  }
}

/// Activité d'une journée, pour le récap hebdomadaire.
class JourActivite {
  const JourActivite({required this.date, required this.xp, required this.quiz});

  final DateTime date;
  final int xp;
  final int quiz;
}
