import 'package:flutter/foundation.dart';

import '../models/entree_historique.dart';
import '../models/fiche.dart';
import '../models/module.dart';
import '../models/progression.dart';
import '../models/progression_module.dart';
import '../models/question.dart';
import 'content_loader.dart';
import 'progression_store.dart';
import 'quiz_session.dart';

/// État partagé de l'appli : le contenu (modules) et la progression.
/// Les écrans lisent ici et appellent les méthodes ci-dessous ; ils ne
/// touchent jamais directement au stockage.
class AppState extends ChangeNotifier {
  AppState({ContentLoader? loader, ProgressionStore? store})
      : _loader = loader ?? ContentLoader(),
        _store = store ?? ProgressionStore();

  final ContentLoader _loader;
  final ProgressionStore _store;

  /// Identifiant utilisé dans l'historique pour une séance de révision
  /// (questions de plusieurs modules).
  static const String idRevision = 'revision';

  /// Nombre maximum de questions dans une séance de révision.
  static const int tailleRevision = 15;

  List<Module> _modules = [];
  final Map<String, Module> _moduleParQuestion = {};
  Progression _progression = Progression();
  bool _pret = false;
  Object? _erreur;

  List<Module> get modules => _modules;
  bool get pret => _pret;
  Object? get erreur => _erreur;
  List<EntreeHistorique> get historique => _progression.historique;

  /// À appeler une fois au démarrage.
  Future<void> charger() async {
    try {
      _modules = await _loader.chargerModules();
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

  bool moduleTermine(Module module) =>
      module.nombreQuestions > 0 &&
      questionsReussies(module) == module.nombreQuestions;

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
      if (ratees.contains(q.id)) {
        p.questionsARevoir.add(q.id);
      } else {
        p.questionsReussies.add(q.id);
        p.questionsARevoir.remove(q.id);
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

  static String _aujourdhui() {
    final d = DateTime.now();
    String deux(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${deux(d.month)}-${deux(d.day)}';
  }
}
