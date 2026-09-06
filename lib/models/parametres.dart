/// Réglages de l'utilisateur, sauvegardés sur l'appareil.
/// Les valeurs par défaut sont celles de l'appli d'origine.
class Parametres {
  const Parametres({
    this.theme = 'systeme',
    this.tailleSeance = 10,
    this.parcoursLibre = false,
    this.melanger = true,
    this.vibrations = true,
    this.tailleExamen = 20,
    this.dureeExamenMinutes = 10,
    this.objectifXpJour = 50,
  });

  /// `systeme`, `clair` ou `sombre`.
  final String theme;

  /// Nombre de questions de la séance du jour.
  final int tailleSeance;

  /// Tous les modules ouverts, sans cadenas sur le parcours.
  final bool parcoursLibre;

  /// Mélanger l'ordre des questions et des réponses.
  final bool melanger;

  /// Retour haptique après une réponse (téléphone uniquement).
  final bool vibrations;

  final int tailleExamen;
  final int dureeExamenMinutes;

  /// XP à gagner chaque jour pour remplir l'anneau de l'objectif.
  final int objectifXpJour;

  Duration get dureeExamen => Duration(minutes: dureeExamenMinutes);

  Parametres copyWith({
    String? theme,
    int? tailleSeance,
    bool? parcoursLibre,
    bool? melanger,
    bool? vibrations,
    int? tailleExamen,
    int? dureeExamenMinutes,
    int? objectifXpJour,
  }) {
    return Parametres(
      theme: theme ?? this.theme,
      tailleSeance: tailleSeance ?? this.tailleSeance,
      parcoursLibre: parcoursLibre ?? this.parcoursLibre,
      melanger: melanger ?? this.melanger,
      vibrations: vibrations ?? this.vibrations,
      tailleExamen: tailleExamen ?? this.tailleExamen,
      dureeExamenMinutes: dureeExamenMinutes ?? this.dureeExamenMinutes,
      objectifXpJour: objectifXpJour ?? this.objectifXpJour,
    );
  }

  factory Parametres.fromJson(Map<String, dynamic> json) {
    const defaut = Parametres();
    return Parametres(
      theme: json['theme'] as String? ?? defaut.theme,
      tailleSeance: json['taille_seance'] as int? ?? defaut.tailleSeance,
      parcoursLibre: json['parcours_libre'] as bool? ?? defaut.parcoursLibre,
      melanger: json['melanger'] as bool? ?? defaut.melanger,
      vibrations: json['vibrations'] as bool? ?? defaut.vibrations,
      tailleExamen: json['taille_examen'] as int? ?? defaut.tailleExamen,
      dureeExamenMinutes:
          json['duree_examen_minutes'] as int? ?? defaut.dureeExamenMinutes,
      objectifXpJour: json['objectif_xp_jour'] as int? ?? defaut.objectifXpJour,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'taille_seance': tailleSeance,
        'parcours_libre': parcoursLibre,
        'melanger': melanger,
        'vibrations': vibrations,
        'taille_examen': tailleExamen,
        'duree_examen_minutes': dureeExamenMinutes,
        'objectif_xp_jour': objectifXpJour,
      };
}
