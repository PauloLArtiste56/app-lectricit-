import 'entree_historique.dart';
import 'progression_module.dart';

/// Toute la progression de l'utilisateur, telle qu'elle est stockée sur
/// l'appareil : une entrée par module + l'historique des quiz.
class Progression {
  Progression({
    Map<String, ProgressionModule>? modules,
    List<EntreeHistorique>? historique,
  })  : modules = modules ?? {},
        historique = historique ?? [];

  final Map<String, ProgressionModule> modules;
  final List<EntreeHistorique> historique;

  /// Renvoie la progression du module, en la créant si elle n'existe pas.
  ProgressionModule pour(String moduleId) {
    return modules.putIfAbsent(moduleId, ProgressionModule.new);
  }

  factory Progression.fromJson(Map<String, dynamic> json) {
    final modulesJson =
        (json['progression'] as Map<String, dynamic>? ?? {});
    final historiqueJson = (json['historique'] as List<dynamic>? ?? []);
    return Progression(
      modules: modulesJson.map(
        (id, valeur) => MapEntry(
          id,
          ProgressionModule.fromJson(valeur as Map<String, dynamic>),
        ),
      ),
      historique: historiqueJson
          .cast<Map<String, dynamic>>()
          .map(EntreeHistorique.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'progression': modules.map((id, p) => MapEntry(id, p.toJson())),
        'historique': historique.map((e) => e.toJson()).toList(),
      };
}
