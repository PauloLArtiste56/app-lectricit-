import 'fiche.dart';
import 'question.dart';

/// Un module de cours : des fiches à lire puis des questions de quiz.
class Module {
  const Module({
    required this.id,
    required this.titre,
    required this.ordre,
    this.theme = '',
    required this.fiches,
    required this.questions,
  });

  final String id;
  final String titre;

  /// Regroupement sur l'accueil (ex. "Les bases"). Vide = sans section.
  final String theme;

  /// Position d'affichage sur l'écran d'accueil (1 = premier).
  final int ordre;
  final List<Fiche> fiches;
  final List<Question> questions;

  int get nombreQuestions => questions.length;

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      titre: json['titre'] as String,
      ordre: json['ordre'] as int,
      theme: json['theme'] as String? ?? '',
      fiches: (json['fiches'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Fiche.fromJson)
          .toList(),
      questions: (json['questions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Question.fromJson)
          .toList(),
    );
  }
}
