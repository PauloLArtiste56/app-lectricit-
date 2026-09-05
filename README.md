# ElecApp — appli d'apprentissage de l'électricité

Application mobile (Flutter) pour apprendre les bases de l'électricité, puis préparer
l'habilitation électrique NF C 18-510.

Projet personnel d'apprentissage : l'objectif premier est d'apprendre à faire une appli mobile,
une étape à la fois.

## État du projet

🚧 Démarrage — aucun code Flutter pour l'instant. Le cadrage complet (périmètre, modèle de
données, ordre de développement, conventions) est dans [`CLAUDE.md`](CLAUDE.md).

## Stack prévue

- Flutter (Dart), Android en priorité, iOS plus tard.
- Pas de backend en V1 : contenu embarqué en JSON, progression stockée en local.
- Stockage local : `shared_preferences` (passer à `hive` si besoin).
- État : `provider` ou `riverpod`, au plus simple.

## Périmètre V1

1. Accueil : liste des modules avec progression.
2. Fiche de cours : titre, texte court, image optionnelle, bouton "Passer au quiz".
3. Quiz : une question à la fois, feedback immédiat, barre de progression.
4. Résultat : score, questions ratées, bouton "Refaire les ratées".
5. Stats : score global, modules terminés, historique.

Modules de contenu V1 : grandeurs électriques et loi d'Ohm, courant continu / alternatif,
circuits série / parallèle, symboles et schémas, dangers et sécurité de base.

## Structure cible

```
lib/
  main.dart
  models/        # Module, Fiche, Question, Progression
  data/          # chargement du JSON, service de stockage local
  screens/       # accueil, module, fiche, quiz, resultat, stats
  widgets/       # composants réutilisables
assets/
  content.json
  images/
```

## Ordre de développement

1. Squelette Flutter + chargement de `content.json` + écran Accueil.
2. Écran Quiz avec feedback immédiat.
3. Écran Résultat.
4. Sauvegarde locale de la progression + affichage sur l'Accueil.
5. Fiches de cours.
6. Écran Stats.
7. Polish (thème, icônes, images).

## Lancer le projet (une fois le squelette créé)

```bash
flutter pub get
flutter run
```

## Organisation du dépôt

- Branche par défaut : `Main`.
- Une branche par fonctionnalité, fusionnée via pull request.
- Textes de l'interface et commentaires en français.
