/// Types de question. Seul `qcm` existe en V1.
/// Pour en ajouter un plus tard (vrai_faux, ordre, image), il suffit
/// d'ajouter une valeur ici : le reste du code ne change pas.
enum TypeQuestion {
  qcm('qcm');

  const TypeQuestion(this.code);

  /// Valeur telle qu'écrite dans `content.json`.
  final String code;

  static TypeQuestion fromCode(String code) {
    return values.firstWhere(
      (type) => type.code == code,
      orElse: () => throw FormatException('Type de question inconnu : $code'),
    );
  }
}

/// Une question de quiz rattachée à une fiche.
class Question {
  const Question({
    required this.id,
    required this.ficheId,
    required this.type,
    required this.enonce,
    required this.reponses,
    required this.bonne,
    required this.explication,
  });

  final String id;

  /// Identifiant de la [Fiche] à laquelle la question se rapporte.
  final String ficheId;
  final TypeQuestion type;
  final String enonce;
  final List<String> reponses;

  /// Index (à partir de 0) de la bonne réponse dans [reponses].
  final int bonne;
  final String explication;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      ficheId: json['fiche_id'] as String,
      type: TypeQuestion.fromCode(json['type'] as String),
      enonce: json['enonce'] as String,
      reponses: (json['reponses'] as List<dynamic>).cast<String>(),
      bonne: json['bonne'] as int,
      explication: json['explication'] as String,
    );
  }

  /// Vrai si la réponse choisie (par son index) est la bonne.
  bool estBonne(int indexChoisi) => indexChoisi == bonne;
}
