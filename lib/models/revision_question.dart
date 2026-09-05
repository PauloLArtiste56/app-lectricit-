/// Suivi d'une question pour la révision espacée : à quel niveau elle est
/// (nombre de réussites d'affilée) et quand la revoir.
class RevisionQuestion {
  const RevisionQuestion({required this.niveau, required this.prochaine});

  /// 0 après un échec, +1 à chaque réussite.
  final int niveau;

  /// Date `AAAA-MM-JJ` à partir de laquelle la question est à revoir.
  final String prochaine;

  /// Jours d'attente avant la prochaine révision, selon le niveau atteint.
  /// Réussie une fois : revoir dans 1 jour ; deux fois : 3 jours ; puis 7, 15, 30.
  static const List<int> intervalles = [1, 1, 3, 7, 15, 30];

  static int intervallePour(int niveau) =>
      intervalles[niveau.clamp(0, intervalles.length - 1)];

  factory RevisionQuestion.fromJson(Map<String, dynamic> json) {
    return RevisionQuestion(
      niveau: json['niveau'] as int? ?? 0,
      prochaine: json['prochaine'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'niveau': niveau, 'prochaine': prochaine};
}
