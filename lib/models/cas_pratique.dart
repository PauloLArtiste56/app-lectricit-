import 'question.dart';

/// Un cas pratique : une situation concrète (contexte) et une suite
/// d'étapes à résoudre dans l'ordre, chacune posée comme un QCM.
class CasPratique {
  const CasPratique({
    required this.id,
    required this.titre,
    required this.contexte,
    required this.moduleId,
    required this.etapes,
  });

  final String id;
  final String titre;

  /// La situation de départ, affichée au-dessus de chaque étape.
  final String contexte;

  /// Module de rattachement (pour l'icône et le thème).
  final String moduleId;

  /// Les étapes, réutilisant le modèle Question (type QCM).
  final List<Question> etapes;

  factory CasPratique.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final etapes = (json['etapes'] as List<dynamic>).cast<Map<String, dynamic>>();
    return CasPratique(
      id: id,
      titre: json['titre'] as String,
      contexte: json['contexte'] as String,
      moduleId: json['module'] as String,
      etapes: [
        for (var i = 0; i < etapes.length; i++)
          Question(
            id: 'cas_${id}_${i + 1}',
            ficheId: '',
            type: TypeQuestion.qcm,
            enonce: etapes[i]['enonce'] as String,
            reponses: (etapes[i]['reponses'] as List<dynamic>).cast<String>(),
            bonne: etapes[i]['bonne'] as int,
            explication: etapes[i]['explication'] as String,
          ),
      ],
    );
  }
}
