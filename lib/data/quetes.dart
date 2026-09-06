import 'package:flutter/material.dart';

import '../models/entree_historique.dart';
import 'app_state.dart';

/// Une quête du jour : un petit défi renouvelé chaque jour, avec une
/// récompense en XP quand la cible est atteinte.
class Quete {
  const Quete({
    required this.id,
    required this.titre,
    required this.icone,
    required this.cible,
    required this.xp,
    required this.mesurer,
  });

  final String id;
  final String titre;
  final IconData icone;

  /// Valeur à atteindre.
  final int cible;

  /// XP versés quand la quête est accomplie.
  final int xp;

  /// Avancement du jour, à partir des quiz du jour et de l'état.
  final int Function(List<EntreeHistorique> quizDuJour, AppState etat) mesurer;

  /// Toutes les quêtes possibles ; trois sont tirées chaque jour.
  static final List<Quete> toutes = [
    Quete(
      id: 'deux_quiz',
      titre: 'Termine 2 quiz',
      icone: Icons.quiz,
      cible: 2,
      xp: 20,
      mesurer: (quiz, _) => quiz.length,
    ),
    Quete(
      id: 'sans_faute',
      titre: 'Fais un sans-faute',
      icone: Icons.star,
      cible: 1,
      xp: 30,
      mesurer: (quiz, _) =>
          quiz.where((e) => e.total >= 5 && e.score == e.total).length,
    ),
    Quete(
      id: 'revision',
      titre: 'Fais une séance de révision',
      icone: Icons.psychology,
      cible: 1,
      xp: 20,
      mesurer: (quiz, _) =>
          quiz.where((e) => e.moduleId == AppState.idRevision).length,
    ),
    Quete(
      id: 'cent_xp',
      titre: 'Gagne 100 XP en quiz',
      icone: Icons.bolt,
      cible: 100,
      xp: 30,
      mesurer: (quiz, _) =>
          quiz.fold(0, (somme, e) => somme + AppState.xpPour(e.score)),
    ),
    Quete(
      id: 'module',
      titre: 'Réussis un module à 80 %',
      icone: Icons.emoji_events,
      cible: 1,
      xp: 40,
      mesurer: (quiz, etat) => quiz
          .where((e) =>
              etat.moduleParId(e.moduleId) != null &&
              e.total >= 10 &&
              e.score >= e.total * AppState.seuilReussite)
          .length,
    ),
    Quete(
      id: 'examen',
      titre: 'Fais un examen blanc',
      icone: Icons.timer_outlined,
      cible: 1,
      xp: 40,
      mesurer: (quiz, _) =>
          quiz.where((e) => e.moduleId == AppState.idExamen).length,
    ),
    Quete(
      id: 'eclair',
      titre: 'Fais un mode éclair',
      icone: Icons.bolt,
      cible: 1,
      xp: 20,
      mesurer: (quiz, _) =>
          quiz.where((e) => e.moduleId == AppState.idEclair).length,
    ),
    Quete(
      id: 'fiches',
      titre: 'Lis 3 fiches',
      icone: Icons.menu_book,
      cible: 3,
      xp: 20,
      mesurer: (_, etat) => etat.fichesLuesAujourdhui,
    ),
  ];

  /// Les trois quêtes d'un jour donné, toujours les mêmes pour une même
  /// date : on mélange la liste avec la date comme graine.
  static List<Quete> pourLeJour(String date) {
    final graine = date.codeUnits.fold(0, (a, c) => a * 31 + c);
    final liste = List.of(toutes);
    // Mélange déterministe (Fisher-Yates avec un générateur maison).
    var g = graine;
    for (var i = liste.length - 1; i > 0; i--) {
      g = (g * 1103515245 + 12345) & 0x7fffffff;
      final j = g % (i + 1);
      final t = liste[i];
      liste[i] = liste[j];
      liste[j] = t;
    }
    return liste.take(3).toList();
  }
}

/// État d'une quête pour aujourd'hui.
class EtatQuete {
  const EtatQuete({required this.quete, required this.avancement, required this.accomplie});

  final Quete quete;
  final int avancement;
  final bool accomplie;

  double get progression => (avancement / quete.cible).clamp(0.0, 1.0);
}
