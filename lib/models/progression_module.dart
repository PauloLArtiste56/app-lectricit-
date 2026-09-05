/// Progression de l'utilisateur sur un module : fiches lues, questions
/// réussies (cumulées au fil des tentatives) et meilleur score.
class ProgressionModule {
  ProgressionModule({
    Set<String>? fichesLues,
    Set<String>? questionsReussies,
    this.meilleurScore = 0,
  })  : fichesLues = fichesLues ?? {},
        questionsReussies = questionsReussies ?? {};

  final Set<String> fichesLues;
  final Set<String> questionsReussies;
  int meilleurScore;

  factory ProgressionModule.fromJson(Map<String, dynamic> json) {
    return ProgressionModule(
      fichesLues: (json['fiches_lues'] as List<dynamic>? ?? []).cast<String>().toSet(),
      questionsReussies:
          (json['questions_reussies'] as List<dynamic>? ?? []).cast<String>().toSet(),
      meilleurScore: json['meilleur_score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fiches_lues': fichesLues.toList()..sort(),
        'questions_reussies': questionsReussies.toList()..sort(),
        'meilleur_score': meilleurScore,
      };
}
