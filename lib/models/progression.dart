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
    this.xpDepenses = 0,
    this.gels = 0,
    List<String>? gelsUtilises,
    List<String>? achats,
    this.tenue,
  })  : modules = modules ?? {},
        historique = historique ?? [],
        recompenses = recompenses ?? [],
        badges = badges ?? {},
        gelsUtilises = gelsUtilises ?? [],
        achats = achats ?? [];

  final Map<String, ProgressionModule> modules;
  final List<EntreeHistorique> historique;

  /// XP gagnés hors quiz (quêtes du jour…).
  final List<Recompense> recompenses;

  /// Badges obtenus : identifiant → date d'obtention.
  final Map<String, String> badges;

  /// Boutique : XP dépensés (le total gagné, lui, ne baisse jamais),
  /// gels de série en stock, jours sauvés par un gel, tenues achetées et
  /// tenue portée par la mascotte.
  int xpDepenses;
  int gels;
  final List<String> gelsUtilises;
  final List<String> achats;
  String? tenue;

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
      xpDepenses: json['xp_depenses'] as int? ?? 0,
      gels: json['gels'] as int? ?? 0,
      gelsUtilises: (json['gels_utilises'] as List<dynamic>? ?? []).cast<String>(),
      achats: (json['achats'] as List<dynamic>? ?? []).cast<String>(),
      tenue: json['tenue'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'progression': modules.map((id, p) => MapEntry(id, p.toJson())),
        'historique': historique.map((e) => e.toJson()).toList(),
        'recompenses': recompenses.map((r) => r.toJson()).toList(),
        'badges': badges,
        'xp_depenses': xpDepenses,
        'gels': gels,
        'gels_utilises': gelsUtilises,
        'achats': achats,
        if (tenue != null) 'tenue': tenue,
      };
}
