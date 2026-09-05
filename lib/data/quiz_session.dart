import '../models/question.dart';

/// Déroulé d'un quiz : quelle question est en cours, ce qui a été répondu,
/// le score. Toute la logique du quiz est ici, l'écran ne fait qu'afficher.
class QuizSession {
  QuizSession(this.questions) : assert(questions.isNotEmpty);

  final List<Question> questions;

  int _index = 0;
  int? _choix;
  int _score = 0;
  bool _terminee = false;
  final List<Question> _ratees = [];

  Question get questionCourante => questions[_index];

  /// Numéro affiché à l'utilisateur (commence à 1).
  int get numero => _index + 1;
  int get total => questions.length;

  /// Entre 0 et 1, pour la barre de progression.
  double get progression => numero / total;

  /// Index de la réponse choisie pour la question en cours, `null` tant
  /// que l'utilisateur n'a pas répondu.
  int? get choix => _choix;
  bool get aRepondu => _choix != null;
  bool get estDerniere => _index == total - 1;
  bool get estTerminee => _terminee;
  int get score => _score;
  List<Question> get questionsRatees => List.unmodifiable(_ratees);

  /// Enregistre la réponse. Une seule réponse par question : les appels
  /// suivants sont ignorés.
  void repondre(int indexReponse) {
    if (aRepondu || _terminee) return;
    _choix = indexReponse;
    if (questionCourante.estBonne(indexReponse)) {
      _score++;
    } else {
      _ratees.add(questionCourante);
    }
  }

  /// Passe à la question suivante, ou termine le quiz après la dernière.
  void suivante() {
    if (!aRepondu || _terminee) return;
    if (estDerniere) {
      _terminee = true;
    } else {
      _index++;
      _choix = null;
    }
  }
}
