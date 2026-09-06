/// Une entrée du glossaire : un terme et sa définition courte.
class Terme {
  const Terme({required this.terme, required this.definition});

  final String terme;
  final String definition;

  factory Terme.fromJson(Map<String, dynamic> json) => Terme(
        terme: json['terme'] as String,
        definition: json['definition'] as String,
      );
}
