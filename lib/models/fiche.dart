/// Une fiche de cours : un titre, un texte court et une image optionnelle.
class Fiche {
  const Fiche({
    required this.id,
    required this.titre,
    required this.contenu,
    this.image,
  });

  final String id;
  final String titre;
  final String contenu;

  /// Nom du fichier dans `assets/images/`, ou `null` s'il n'y a pas d'image.
  final String? image;

  factory Fiche.fromJson(Map<String, dynamic> json) {
    return Fiche(
      id: json['id'] as String,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      image: json['image'] as String?,
    );
  }
}
