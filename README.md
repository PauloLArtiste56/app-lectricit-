# ElecApp — appli d'apprentissage de l'électricité

Application mobile (Flutter) pour apprendre les bases de l'électricité, puis préparer
l'habilitation électrique NF C 18-510.

Projet personnel d'apprentissage : l'objectif premier est d'apprendre à faire une appli mobile,
une étape à la fois.

## État du projet

🚧 Étapes 1 à 3 faites : squelette Flutter, chargement de `assets/content.json`, écran
Accueil avec la liste des modules, écran Quiz avec feedback immédiat, écran Résultat avec
« Refaire les ratées ». Le cadrage complet (périmètre, modèle de données, ordre de
développement, conventions) est dans [`CLAUDE.md`](CLAUDE.md).

## Stack prévue

- Flutter (Dart). Développement sur Windows, cible finale iPhone.
- Une appli iOS ne se compile que sur macOS : au quotidien on teste sur Windows avec Chrome,
  et sur l'iPhone via la version web. La compilation iOS se fera plus tard dans le cloud (GitHub Actions).
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

## Lancer le projet sur Windows

Prérequis : [installer Flutter](https://docs.flutter.dev/get-started/install/windows) et Google Chrome.

```bash
flutter pub get
flutter run -d chrome
```

Pour vérifier le code et lancer les tests :

```bash
flutter analyze
flutter test
```

### Et sur l'iPhone ?

Une appli iOS ne se compile que sur un Mac. En attendant, l'appli sera publiée en version web
et s'ajoutera à l'écran d'accueil de l'iPhone depuis Safari (« Partager » puis « Sur l'écran
d'accueil »). La compilation iOS native viendra plus tard via GitHub Actions et un compte
développeur Apple.

## Organisation du dépôt

- Branche par défaut : `main`.
- Une branche par fonctionnalité, fusionnée via pull request.
- Textes de l'interface et commentaires en français.
