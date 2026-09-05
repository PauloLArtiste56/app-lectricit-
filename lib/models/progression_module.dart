import 'revision_question.dart';

/// Progression de l'utilisateur sur un module : fiches lues, questions
/// réussies (cumulées au fil des tentatives), questions à revoir (ratées
/// à la dernière tentative), suivi de révision espacée et meilleur score.
class ProgressionModule {
  ProgressionModule({
    Set<String>? fichesLues,
    Set<String>? questionsReussies,
    Set<String>? questionsARevoir,
    Map<String, RevisionQuestion>? revisions,
    this.meilleurScore = 0,
  })  : fichesLues = fichesLues ?? {},
        questionsReussies = questionsReussies ?? {},
        questionsARevoir = questionsARevoir ?? {},
        revisions = revisions ?? {};

  final Set<String> fichesLues;
  final Set<String> questionsReussies;

  /// Ratées lors de la dernière tentative : elles reviennent en révision
  /// jusqu'à être réussies.
  final Set<String> questionsARevoir;

  /// Par identifiant de question : niveau et date de prochaine révision.
  final Map<String, RevisionQuestion> revisions;
  int meilleurScore;

  factory ProgressionModule.fromJson(Map<String, dynamic> json) {
    return ProgressionModule(
      fichesLues: (json['fiches_lues'] as List<dynamic>? ?? []).cast<String>().toSet(),
      questionsReussies:
          (json['questions_reussies'] as List<dynamic>? ?? []).cast<String>().toSet(),
      questionsARevoir:
          (json['questions_a_revoir'] as List<dynamic>? ?? []).cast<String>().toSet(),
      revisions: (json['revisions'] as Map<String, dynamic>? ?? {}).map(
        (id, v) => MapEntry(id, RevisionQuestion.fromJson(v as Map<String, dynamic>)),
      ),
      meilleurScore: json['meilleur_score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'fiches_lues': fichesLues.toList()..sort(),
        'questions_reussies': questionsReussies.toList()..sort(),
        'questions_a_revoir': questionsARevoir.toList()..sort(),
        'revisions': revisions.map((id, r) => MapEntry(id, r.toJson())),
        'meilleur_score': meilleurScore,
      };
}
