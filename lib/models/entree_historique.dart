/// Une ligne de l'historique : un quiz fait tel jour, avec son score.
class EntreeHistorique {
  const EntreeHistorique({
    required this.moduleId,
    required this.date,
    required this.score,
    required this.total,
    this.ratees = const [],
  });

  final String moduleId;

  /// Date au format `AAAA-MM-JJ`.
  final String date;
  final int score;
  final int total;

  /// Identifiants des questions ratées, pour pouvoir revoir ce quiz.
  /// Vide sur les quiz enregistrés avant l'ajout de cette liste.
  final List<String> ratees;

  factory EntreeHistorique.fromJson(Map<String, dynamic> json) {
    return EntreeHistorique(
      moduleId: json['module'] as String,
      date: json['date'] as String,
      score: json['score'] as int,
      total: json['total'] as int,
      ratees: (json['ratees'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'module': moduleId,
        'date': date,
        'score': score,
        'total': total,
        // Absente quand il n'y a rien à revoir : le fichier reste petit.
        if (ratees.isNotEmpty) 'ratees': ratees,
      };
}
