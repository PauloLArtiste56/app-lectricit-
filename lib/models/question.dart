/// Types de question.
/// Pour en ajouter un (vrai_faux, image…), ajouter une valeur ici puis
/// gérer son affichage dans l'écran Quiz.
enum TypeQuestion {
  /// Choix multiple : une seule bonne réponse parmi 3 ou 4.
  qcm('qcm'),

  /// Remettre des étapes dans le bon ordre. Dans `content.json`, les
  /// `reponses` sont écrites dans le bon ordre ; l'appli les mélange.
  ordre('ordre'),

  /// Comme un QCM, mais une image accompagne l'énoncé (« Quel est ce
  /// symbole ? »). Le champ [Question.image] est obligatoire.
  image('image'),

  /// Une affirmation à juger : les `reponses` sont toujours
  /// `["Vrai", "Faux"]`, dans cet ordre, et ne sont jamais mélangées.
  vraiFaux('vrai_faux');

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
    this.bonne = 0,
    required this.explication,
    this.image,
  });

  final String id;

  /// Identifiant de la [Fiche] à laquelle la question se rapporte.
  final String ficheId;
  final TypeQuestion type;
  final String enonce;
  final List<String> reponses;

  /// QCM : index (à partir de 0) de la bonne réponse dans [reponses].
  /// Ignoré pour le type `ordre`.
  final int bonne;
  final String explication;

  /// Illustration de l'énoncé, chemin relatif à `assets/images/`
  /// (ex. `questions/sym_lampe.png`). Utilisé par le type `image`.
  final String? image;

  /// Vrai pour les types à réponse unique parmi plusieurs (qcm, image).
  bool get estChoixUnique => type != TypeQuestion.ordre;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      ficheId: json['fiche_id'] as String,
      type: TypeQuestion.fromCode(json['type'] as String),
      enonce: json['enonce'] as String,
      reponses: (json['reponses'] as List<dynamic>).cast<String>(),
      bonne: json['bonne'] as int? ?? 0,
      explication: json['explication'] as String,
      image: json['image'] as String?,
    );
  }

  /// QCM : vrai si la réponse choisie (par son index) est la bonne.
  bool estBonne(int indexChoisi) => indexChoisi == bonne;
}
