import 'entree_historique.dart';
import 'progression_module.dart';
import 'recompense.dart';

/// Toute la progression de l'utilisateur, telle qu'elle est stockée sur
/// l'appareil : une entrée par module, l'historique des quiz, les
/// récompenses (quêtes) et les badges obtenus.
class Progression {
  Progression({
    Map<String, ProgressionModule>? modules,
    List<EntreeHistorique>? historique,
    List<Recompense>? recompenses,
    Map<String, String>? badges,
  })  : modules = modules ?? {},
        historique = historique ?? [],
        recompenses = recompenses ?? [],
        badges = badges ?? {};

  final Map<String, ProgressionModule> modules;
  final List<EntreeHistorique> historique;

  /// XP gagnés hors quiz (quêtes du jour…).
  final List<Recompense> recompenses;

  /// Badges obtenus : identifiant → date d'obtention.
  final Map<String, String> badges;

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
      recompenses: (json['recompenses'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Recompense.fromJson)
          .toList(),
      badges: (json['badges'] as Map<String, dynamic>? ?? {})
          .map((id, date) => MapEntry(id, date as String)),
    );
  }

  Map<String, dynamic> toJson() => {
        'progression': modules.map((id, p) => MapEntry(id, p.toJson())),
        'historique': historique.map((e) => e.toJson()).toList(),
        'recompenses': recompenses.map((r) => r.toJson()).toList(),
        'badges': badges,
      };
}
