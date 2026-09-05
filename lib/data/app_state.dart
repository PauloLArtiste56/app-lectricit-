import 'package:flutter/foundation.dart';

import '../models/entree_historique.dart';
import '../models/module.dart';
import '../models/progression.dart';
import '../models/progression_module.dart';
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

  List<Module> _modules = [];
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
      _progression = await _store.charger();
      _pret = true;
    } catch (e) {
      _erreur = e;
    }
    notifyListeners();
  }

  ProgressionModule progressionDe(Module module) => _progression.pour(module.id);

  /// Nombre de questions du module déjà réussies au moins une fois.
  int questionsReussies(Module module) {
    final reussies = progressionDe(module).questionsReussies;
    return module.questions.where((q) => reussies.contains(q.id)).length;
  }

  bool moduleTermine(Module module) =>
      module.nombreQuestions > 0 &&
      questionsReussies(module) == module.nombreQuestions;

  bool ficheLue(Module module, String ficheId) =>
      progressionDe(module).fichesLues.contains(ficheId);

  Future<void> marquerFicheLue(Module module, String ficheId) async {
    if (!progressionDe(module).fichesLues.add(ficheId)) return;
    await _sauvegarder();
  }

  /// Enregistre la fin d'un quiz : questions réussies, meilleur score
  /// (seulement pour un quiz complet du module) et ligne d'historique.
  Future<void> enregistrerResultat(Module module, QuizSession session) async {
    final p = progressionDe(module);
    final ratees = session.questionsRatees.map((q) => q.id).toSet();
    for (final q in session.questions) {
      if (!ratees.contains(q.id)) p.questionsReussies.add(q.id);
    }
    final quizComplet = session.total == module.nombreQuestions;
    if (quizComplet && session.score > p.meilleurScore) {
      p.meilleurScore = session.score;
    }
    _progression.historique.add(EntreeHistorique(
      moduleId: module.id,
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

  Module? moduleParId(String id) {
    for (final m in _modules) {
      if (m.id == id) return m;
    }
    return null;
  }

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
