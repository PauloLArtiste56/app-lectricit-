/// Une tenue de la mascotte « pile », à acheter dans la boutique avec les
/// XP gagnés. L'image est un calque transparent superposé à la pile.
class Tenue {
  const Tenue({required this.id, required this.nom, required this.prix, required this.description});

  final String id;
  final String nom;

  /// Prix en XP.
  final int prix;
  final String description;

  /// Chemin de l'image dans `assets/images/`.
  String get image => 'decors/tenue_$id.png';

  static const List<Tenue> toutes = [
    Tenue(id: 'lunettes', nom: 'Lunettes de soleil', prix: 150, description: 'La classe, tout simplement.'),
    Tenue(id: 'noeud', nom: 'Nœud papillon', prix: 200, description: 'Pour les grandes occasions.'),
    Tenue(id: 'casque', nom: 'Casque de chantier', prix: 300, description: 'Sécurité avant tout.'),
    Tenue(id: 'cape', nom: 'Cape de héros', prix: 500, description: 'Plus rapide que le courant.'),
    Tenue(id: 'couronne', nom: 'Couronne', prix: 1000, description: 'Pour régner sur les électrons.'),
  ];

  static Tenue? parId(String? id) {
    for (final t in toutes) {
      if (t.id == id) return t;
    }
    return null;
  }
}
