import 'package:flutter/material.dart';

import 'app_state.dart';

/// Un insigne (badge) : une médaille à débloquer en remplissant une condition.
class Insigne {
  const Insigne({
    required this.id,
    required this.titre,
    required this.description,
    required this.icone,
    required this.condition,
  });

  final String id;
  final String titre;
  final String description;
  final IconData icone;
  final bool Function(AppState etat) condition;

  static final List<Insigne> tous = [
    Insigne(
      id: 'premier_quiz',
      titre: 'Premier pas',
      description: 'Terminer un premier quiz.',
      icone: Icons.flag,
      condition: (e) => e.historique.isNotEmpty,
    ),
    Insigne(
      id: 'premier_module',
      titre: 'Module réussi',
      description: 'Réussir un module à 80 %.',
      icone: Icons.check_circle,
      condition: (e) => e.modulesReussisTotal >= 1,
    ),
    Insigne(
      id: 'sans_faute',
      titre: 'Sans faute',
      description: 'Un quiz complet de module sans aucune erreur.',
      icone: Icons.star,
      condition: (e) => e.historique.any((h) =>
          h.total >= 20 && h.score == h.total && e.moduleParId(h.moduleId) != null),
    ),
    Insigne(
      id: 'serie_7',
      titre: 'Une semaine',
      description: 'Sept jours d\'affilée avec au moins un quiz.',
      icone: Icons.local_fire_department,
      condition: (e) => e.serieJours >= 7,
    ),
    Insigne(
      id: 'serie_30',
      titre: 'Un mois',
      description: 'Trente jours d\'affilée.',
      icone: Icons.whatshot,
      condition: (e) => e.serieJours >= 30,
    ),
    Insigne(
      id: 'chapitre',
      titre: 'Chapitre bouclé',
      description: 'Réussir tous les modules d\'un chapitre.',
      icone: Icons.emoji_events,
      condition: (e) => e.chapitres.any(e.chapitreComplet),
    ),
    Insigne(
      id: 'cent_questions',
      titre: '100 questions',
      description: 'Cent questions réussies au total.',
      icone: Icons.looks_one,
      condition: (e) => e.totalReussies >= 100,
    ),
    Insigne(
      id: 'cinq_cents_questions',
      titre: '500 questions',
      description: 'Cinq cents questions réussies au total.',
      icone: Icons.military_tech,
      condition: (e) => e.totalReussies >= 500,
    ),
    Insigne(
      id: 'mille_questions',
      titre: '1 000 questions',
      description: 'Mille questions réussies. La moitié du chemin.',
      icone: Icons.workspace_premium,
      condition: (e) => e.totalReussies >= 1000,
    ),
    Insigne(
      id: 'examen',
      titre: 'Examen réussi',
      description: 'Un examen blanc avec au moins 80 % de bonnes réponses.',
      icone: Icons.timer,
      condition: (e) => e.historique.any((h) =>
          h.moduleId == AppState.idExamen && h.score >= h.total * AppState.seuilReussite),
    ),
    Insigne(
      id: 'niveau_5',
      titre: 'Niveau 5',
      description: 'Atteindre le niveau 5.',
      icone: Icons.stars,
      condition: (e) => e.niveau >= 5,
    ),
    Insigne(
      id: 'niveau_10',
      titre: 'Niveau 10',
      description: 'Atteindre le niveau 10.',
      icone: Icons.auto_awesome,
      condition: (e) => e.niveau >= 10,
    ),
    Insigne(
      id: 'dix_modules',
      titre: '10 modules',
      description: 'Dix modules réussis.',
      icone: Icons.grid_view,
      condition: (e) => e.modulesReussisTotal >= 10,
    ),
    Insigne(
      id: 'cinquante_modules',
      titre: '50 modules',
      description: 'Cinquante modules réussis.',
      icone: Icons.apps,
      condition: (e) => e.modulesReussisTotal >= 50,
    ),
    Insigne(
      id: 'parcours',
      titre: 'Parcours complet',
      description: 'Les 100 modules réussis.',
      icone: Icons.electric_bolt,
      condition: (e) => e.modulesAvecContenu.isNotEmpty &&
          e.modulesReussisTotal == e.modulesAvecContenu.length,
    ),
    Insigne(
      id: 'quetes_10',
      titre: 'Chasseur de quêtes',
      description: 'Dix quêtes du jour accomplies.',
      icone: Icons.task_alt,
      condition: (e) => e.quetesAccomplies >= 10,
    ),
  ];
}
