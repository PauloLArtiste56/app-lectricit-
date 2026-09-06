/// Un chapitre du parcours : un titre et la liste ordonnée des modules
/// qu'il regroupe (par identifiant, le contenu reste dans `content.json`).
class Chapitre {
  const Chapitre({
    required this.id,
    required this.titre,
    this.description = '',
    required this.modulesIds,
  });

  final String id;
  final String titre;
  final String description;

  /// Identifiants des modules, dans l'ordre du chemin.
  final List<String> modulesIds;

  factory Chapitre.fromJson(Map<String, dynamic> json) {
    return Chapitre(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      modulesIds: (json['modules'] as List<dynamic>).cast<String>(),
    );
  }
}
