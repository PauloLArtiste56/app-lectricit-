import 'dart:math';

import '../models/question.dart';

/// Déroulé d'un quiz : quelle question est en cours, ce qui a été répondu,
/// le score. Toute la logique du quiz est ici, l'écran ne fait qu'afficher.
///
/// Les questions et leurs réponses sont mélangées ([melanger]) pour ne pas
/// mémoriser "c'est toujours la deuxième". Les index manipulés par l'écran
/// sont ceux de l'ordre affiché ; la conversion vers l'ordre d'origine se
/// fait ici.
class QuizSession {
  QuizSession(List<Question> questions, {bool melanger = true, Random? random})
      : assert(questions.isNotEmpty),
        questions = List.of(questions) {
    final rng = random ?? Random();
    if (melanger) this.questions.shuffle(rng);
    for (final q in this.questions) {
      final ordre = List.generate(q.reponses.length, (i) => i);
      if (melanger) ordre.shuffle(rng);
      _ordreAffichage.add(ordre);
    }
  }

  final List<Question> questions;

  /// Pour chaque question, `ordreAffichage[i]` = index d'origine de la
  /// i-ème réponse affichée.
  final List<List<int>> _ordreAffichage = [];

  int _index = 0;
  int? _choix;
  List<int>? _choixOrdre;
  int _score = 0;
  bool _terminee = false;
  final List<Question> _ratees = [];

  Question get questionCourante => questions[_index];

  /// Réponses de la question courante, dans l'ordre affiché.
  List<String> get reponsesAffichees =>
      [for (final i in _ordreAffichage[_index]) questionCourante.reponses[i]];

  /// Numéro affiché à l'utilisateur (commence à 1).
  int get numero => _index + 1;
  int get total => questions.length;

  /// Entre 0 et 1, pour la barre de progression.
  double get progression => numero / total;

  /// QCM : index affiché de la réponse choisie, `null` tant qu'on n'a pas
  /// répondu.
  int? get choix => _choix;

  /// Ordre : index affichés dans l'ordre choisi par l'utilisateur.
  List<int>? get choixOrdre => _choixOrdre;

  bool get aRepondu => _choix != null || _choixOrdre != null;
  bool get estDerniere => _index == total - 1;
  bool get estTerminee => _terminee;
  int get score => _score;
  List<Question> get questionsRatees => List.unmodifiable(_ratees);

  /// Vrai si la question courante a été réussie (après réponse).
  bool get derniereReussie =>
      aRepondu && !_ratees.contains(questionCourante);

  /// QCM : vrai si la réponse affichée à cet index est la bonne.
  bool estBonneAffichee(int indexAffiche) =>
      questionCourante.estBonne(_ordreAffichage[_index][indexAffiche]);

  /// Ordre : vrai si la réponse affichée à cet index est à sa bonne place
  /// dans l'ordre choisi par l'utilisateur.
  bool estBienPlacee(int position) =>
      _choixOrdre != null && _ordreAffichage[_index][_choixOrdre![position]] == position;

  /// QCM : enregistre la réponse. Une seule réponse par question.
  void repondre(int indexAffiche) {
    if (aRepondu || _terminee) return;
    _choix = indexAffiche;
    _compter(estBonneAffichee(indexAffiche));
  }

  /// Ordre : enregistre l'ordre choisi (index affichés). Correct si, remis
  /// dans l'ordre d'origine, on obtient 0, 1, 2…
  void repondreOrdre(List<int> ordreChoisi) {
    if (aRepondu || _terminee) return;
    _choixOrdre = List.of(ordreChoisi);
    final origine = [for (final i in ordreChoisi) _ordreAffichage[_index][i]];
    var correct = origine.length == questionCourante.reponses.length;
    for (var i = 0; correct && i < origine.length; i++) {
      correct = origine[i] == i;
    }
    _compter(correct);
  }

  void _compter(bool reussie) {
    if (reussie) {
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
      _choixOrdre = null;
    }
  }
}
