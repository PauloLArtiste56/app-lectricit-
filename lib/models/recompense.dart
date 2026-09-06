/// Une récompense en XP hors quiz : quête du jour accomplie, objectif
/// atteint… Stockée pour ne jamais être versée deux fois.
class Recompense {
  const Recompense({required this.id, required this.date, required this.xp});

  /// Identifiant unique, par exemple `quete:deux_quiz:2026-09-06`.
  final String id;

  /// Date au format `AAAA-MM-JJ`.
  final String date;
  final int xp;

  factory Recompense.fromJson(Map<String, dynamic> json) => Recompense(
        id: json['id'] as String,
        date: json['date'] as String,
        xp: json['xp'] as int,
      );

  Map<String, dynamic> toJson() => {'id': id, 'date': date, 'xp': xp};
}
