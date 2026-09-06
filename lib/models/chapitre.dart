/// Un chapitre du parcours : un titre, une couleur, des illustrations et la
/// liste ordonnée des modules qu'il regroupe (par identifiant, le contenu
/// reste dans `content.json`).
class Chapitre {
  const Chapitre({
    required this.id,
    required this.titre,
    this.description = '',
    this.couleur = '#1565C0',
    this.decors = const [],
    required this.modulesIds,
  });

  final String id;
  final String titre;
  final String description;

  /// Couleur du chapitre au format `#RRGGBB` : bannière, boutons, fond.
  final String couleur;

  /// Noms des illustrations posées le long du chemin
  /// (fichiers `assets/images/decors/<nom>.png`).
  final List<String> decors;

  /// Identifiants des modules, dans l'ordre du chemin.
  final List<String> modulesIds;

  factory Chapitre.fromJson(Map<String, dynamic> json) {
    return Chapitre(
      id: json['id'] as String,
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      couleur: json['couleur'] as String? ?? '#1565C0',
      decors: (json['decors'] as List<dynamic>? ?? []).cast<String>(),
      modulesIds: (json['modules'] as List<dynamic>).cast<String>(),
    );
  }
}
