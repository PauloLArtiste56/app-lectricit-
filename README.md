# ElecApp — appli d'apprentissage de l'électricité

Application mobile (Flutter) pour apprendre les bases de l'électricité, puis préparer
l'habilitation électrique NF C 18-510.

Projet personnel d'apprentissage : l'objectif premier est d'apprendre à faire une appli mobile,
une étape à la fois.

## État du projet

✅ V1 complète et enrichie : 9 modules, chacun avec 3 fiches illustrées et 10 questions
(90 questions au total, dont des questions « remettre dans l'ordre »). Révision ciblée des
points faibles, questions et réponses mélangées, bouton « Revoir la fiche » après une erreur. Le cadrage complet (périmètre, modèle de données,
conventions) est dans [`CLAUDE.md`](CLAUDE.md).

Parcours : Accueil → Module → Fiches → Quiz (feedback immédiat) → Résultat (« Refaire les
ratées ») → Accueil. La progression est sauvegardée sur l'appareil et l'onglet Stats montre
le score global, les modules terminés et l'historique. Le cadrage complet (périmètre, modèle de données, ordre de
développement, conventions) est dans [`CLAUDE.md`](CLAUDE.md).

## Stack

- Flutter (Dart). Développement sur Windows, cible finale iPhone.
- Une appli iOS ne se compile que sur macOS : au quotidien on teste sur Windows avec Chrome,
  et sur l'iPhone via la version web. La compilation iOS se fera plus tard dans le cloud (GitHub Actions).
- Pas de backend en V1 : contenu embarqué en JSON, progression stockée en local.
- Stockage local : `shared_preferences` (passer à `hive` si besoin).
- État : `provider` ou `riverpod`, au plus simple.

## Contenu

1. Grandeurs électriques et loi d'Ohm
2. Courant continu / alternatif
3. Circuits série / parallèle
4. Symboles et schémas
5. Dangers et sécurité de base
6. Mesures et appareils (multimètre, pince, VAT)
7. Installation domestique (tableau, sections, salle de bains)
8. Énergie et consommation
9. Habilitation électrique : premiers repères (NF C 18-510, symboles, consignation)

Tout le contenu est dans `assets/content.json` : pour ajouter ou corriger une fiche ou une
question, c'est le seul fichier à modifier. Les tests vérifient sa cohérence.

Deux types de question : `qcm` (une bonne réponse parmi 3 ou 4) et `ordre` (les `reponses`
sont écrites dans le bon ordre, l'appli les mélange et l'utilisateur les remet en place).

## Vérification automatique

À chaque pull request, GitHub Actions lance `flutter analyze`, `flutter test` et
`flutter build web` (fichier `.github/workflows/ci.yml`).

## Structure

```
lib/
  main.dart      # démarrage, thème, état partagé
  theme.dart     # couleurs et formes (clair / sombre)
  models/        # Module, Fiche, Question, Progression…
  data/          # chargement du JSON, stockage local, état partagé, déroulé du quiz
  screens/       # accueil, module, fiche, quiz, resultat, stats
  widgets/       # composants réutilisables (carte module, bouton réponse…)
assets/
  content.json   # tout le contenu pédagogique
  images/        # schémas des fiches (PNG)
test/            # tests automatiques (flutter test)
tools/schemas/   # source des schémas (script + SVG) pour les retoucher
```

Règle : les écrans ne font qu'afficher. La lecture du contenu, la sauvegarde et le calcul
des scores sont dans `data/`.

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
