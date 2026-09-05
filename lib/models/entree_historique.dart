/// Une ligne de l'historique : un quiz fait tel jour, avec son score.
class EntreeHistorique {
  const EntreeHistorique({
    required this.moduleId,
    required this.date,
    required this.score,
    required this.total,
  });

  final String moduleId;

  /// Date au format `AAAA-MM-JJ`.
  final String date;
  final int score;
  final int total;

  factory EntreeHistorique.fromJson(Map<String, dynamic> json) {
    return EntreeHistorique(
      moduleId: json['module'] as String,
      date: json['date'] as String,
      score: json['score'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'module': moduleId,
        'date': date,
        'score': score,
        'total': total,
      };
}
