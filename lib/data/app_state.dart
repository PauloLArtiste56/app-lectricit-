import 'package:flutter/foundation.dart';

import '../models/chapitre.dart';
import '../models/entree_historique.dart';
import '../models/fiche.dart';
import '../models/module.dart';
import '../models/progression.dart';
import '../models/progression_module.dart';
import '../models/question.dart';
import '../models/revision_question.dart';
import 'content_loader.dart';
import 'progression_store.dart';
import 'quiz_session.dart';

/// État partagé de l'appli : le contenu (modules) et la progression.
/// Les écrans lisent ici et appellent les méthodes ci-dessous ; ils ne
/// touchent jamais directement au stockage.
class AppState extends ChangeNotifier {
  AppState({
    ContentLoader? loader,
    ProgressionStore? store,
    DateTime Function()? horloge,
  })  : _loader = loader ?? ContentLoader(),
        _store = store ?? ProgressionStore(),
        _horloge = horloge ?? DateTime.now;

  final ContentLoader _loader;
  final ProgressionStore _store;

  /// Injectable dans les tests pour simuler le passage des jours.
  final DateTime Function() _horloge;

  /// Nombre de questions d'une séance du jour.
  static const int tailleSeance = 10;

  /// Identifiant utilisé dans l'historique pour une séance de révision
  /// (questions de plusieurs modules).
  static const String idRevision = 'revision';

  /// Nombre maximum de questions dans une séance de révision.
  static const int tailleRevision = 15;

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
  bool _pret = false;
  Object? _erreur;

  List<Module> get modules => _modules;

  /// Chapitres du parcours, dans l'ordre du chemin.
  List<Chapitre> get chapitres => _chapitres;
  bool get pret => _pret;
  Object? get erreur => _erreur;
  List<EntreeHistorique> get historique => _progression.historique;

  /// À appeler une fois au démarrage.
  Future<void> charger() async {
    try {
      _modules = await _loader.chargerModules();
      _chapitres = await _loader.chargerParcours();
      _ordreParcours = [for (final c in _chapitres) ...c.modulesIds];
      for (final m in _modules) {
        for (final q in m.questions) {
          _moduleParQuestion[q.id] = m;
        }
      }
      _progression = await _store.charger();
      _pret = true;
    } catch (e) {
      _erreur = e;
    }
    notifyListeners();
  }

  ProgressionModule progressionDe(Module module) => _progression.pour(module.id);

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
    final dues = questionsDues().take(tailleSeance).toList();
    final nouvelles = questionsJamaisFaites()..shuffle();
    return [...dues, ...nouvelles.take(tailleSeance - dues.length)];
  }

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

  /// Déverrouillé quand le module précédent du chemin est réussi.
  /// Le premier module, et tout module hors parcours, sont toujours ouverts.
  bool moduleDeverrouille(Module module) {
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
    if (!progressionDe(module).fichesLues.add(ficheId)) return;
    await _sauvegarder();
  }

  /// Enregistre la fin d'un quiz. Chaque question met à jour son propre
  /// module (réussie / à revoir). Le meilleur score n'est mis à jour que
  /// pour un quiz complet d'un module ([moduleComplet]).
  Future<void> enregistrerResultat(QuizSession session,
      {Module? moduleComplet}) async {
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
      moduleId: moduleComplet?.id ?? idRevision,
      date: _aujourdhui(),
      score: session.score,
      total: session.total,
    ));
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
