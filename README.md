# ElecApp — appli d'apprentissage de l'électricité

Application mobile (Flutter) pour apprendre les bases de l'électricité, puis préparer
l'habilitation électrique NF C 18-510.

Projet personnel d'apprentissage : l'objectif premier est d'apprendre à faire une appli mobile,
une étape à la fois.

## État du projet

✅ V1 complète et enrichie : 100 modules regroupés par thème, chacun avec 3 fiches illustrées
et 20 questions (2 020 questions, dont des questions « remettre dans l'ordre » et des questions illustrées). Séance du jour
avec révision espacée, examen blanc chronométré, écran Paramètres (thème, parcours libre,
export / import de la progression), série de jours, parcours en 10 chapitres façon Duolingo, révision des points faibles, questions et réponses
mélangées, bouton « Revoir la fiche » après une erreur. Objectif : continuer à ajouter des
modules pour ne jamais en faire le tour. Le cadrage complet (périmètre, modèle de données,
conventions) est dans [`CLAUDE.md`](CLAUDE.md).

Navigation : Parcours (chemin en 10 chapitres façon Duolingo, modules déverrouillés un à un, mascotte pile) → Module → Fiches → Quiz
(feedback immédiat) → Résultat (« Refaire les ratées ») → Parcours. L'onglet Modules liste
tout par thème pour aller droit sur un sujet. La progression est sauvegardée sur l'appareil et l'onglet Stats montre
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

Les bases : grandeurs et loi d'Ohm · continu / alternatif · série / parallèle · symboles et
schémas · énergie et consommation · moteurs et transformateurs.

Installation et pratique : mesures et appareils · installation domestique · éclairage et
commandes · prises, interrupteurs et câblage · parafoudre et surtensions · extérieur, garage,
piscine.

Sécurité et habilitation : dangers et sécurité de base · habilitation (premiers repères) ·
voisinage (zones et distances) · EPI et outillage isolé · B0 et BS en détail · BR ·
premiers secours et incendie électrique.

Tout le contenu est dans `assets/content.json` : pour ajouter ou corriger une fiche ou une
question, c'est le seul fichier à modifier. Les tests vérifient sa cohérence.

Deux types de question : `qcm` (une bonne réponse parmi 3 ou 4) et `ordre` (les `reponses`
sont écrites dans le bon ordre, l'appli les mélange et l'utilisateur les remet en place).
Chaque module a un `theme` qui sert de section sur l'accueil. Les fiches sont illustrées soit
par un schéma dessiné, soit par une « carte résumé » générée à partir de points clés
(`tools/schemas/generer_schemas.py`).

## Vérification automatique

À chaque pull request, GitHub Actions lance `flutter analyze`, `flutter test` et
`flutter build web` (fichier `.github/workflows/ci.yml`).

## Sur l'iPhone (version web)

À chaque fusion sur `main`, l'appli est mise en ligne automatiquement :
<https://paulolartiste56.github.io/app-lectricit-/>

Pour l'installer comme une appli :
1. Ouvrir l'adresse dans **Safari** sur l'iPhone.
2. Toucher le bouton Partager, puis « Sur l'écran d'accueil ».
3. L'icône ElecApp apparaît ; l'appli s'ouvre en plein écran et fonctionne
   hors ligne après le premier chargement. La progression reste dans le téléphone.

La vraie appli iOS (TestFlight / App Store) viendra plus tard : elle demande une
compilation sur macOS et un compte développeur Apple.

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
