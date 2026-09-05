# ElecApp — appli d'apprentissage de l'électricité

## Contexte
Projet perso d'apprentissage : le but premier est que je (Paulo) apprenne à faire une appli mobile.
L'appli sert à apprendre les bases de l'électricité (V1), puis à préparer l'habilitation
électrique NF C 18-510 (V2+).

**Important pour Claude Code :** je veux comprendre ce qui est fait.
- Explique brièvement chaque choix technique avant de coder.
- Reste au niveau de la structure et du fonctionnement général (quel fichier fait quoi,
  comment les pièces s'assemblent). Pas d'explication ligne par ligne du code.
- Avance par petites étapes, une feature à la fois, et attends ma validation entre chaque.
- Ne génère pas toute l'appli d'un coup.
- Quand une tâche que je t'ai confiée est terminée (fusionnée sur `main`), envoie-moi un mail
  de compte rendu via la connexion Gmail, à l'adresse de mon compte : ce qui a été fait, ce que
  je dois faire de mon côté, et le lien de la pull request. Court, en français.
- Commente le code en français quand ce n'est pas évident.

## Stack
- **Flutter** (Dart).
- Poste de développement : **Windows**. Cible finale : **iPhone (iOS)**.
- Contrainte : une appli iOS ne se compile que sur macOS. Stratégie :
  - au quotidien, on teste sur Windows avec `flutter run -d chrome` (ou un émulateur Android) ;
  - sur l'iPhone, on teste la version web ajoutée à l'écran d'accueil de Safari ;
  - la vraie appli iOS (TestFlight / App Store) sera compilée plus tard via GitHub Actions
    (machine macOS dans le cloud) + un compte développeur Apple.
- Pas de backend en V1 : contenu embarqué en JSON, progression stockée en local.
- Stockage local : `shared_preferences` pour la V1 (passer à `hive` si ça devient limitant).
- État : `provider` ou `riverpod`, au plus simple. Pas de bloc pour le moment.
- Pas d'authentification, pas de réseau, pas de notifications en V1.

## Périmètre V1 (à ne pas dépasser)
1. Accueil : liste des modules avec progression (ex. "3/10").
2. Fiche de cours : titre, texte court, image optionnelle, bouton "Passer au quiz".
3. Quiz : une question à la fois, 3-4 réponses, feedback immédiat (vert/rouge + explication), barre de progression.
4. Résultat : score, liste des questions ratées, bouton "Refaire les ratées".
5. Stats : score global, modules terminés, historique.

Navigation : barre du bas avec Accueil / Stats.
Accueil → Module → Fiche → Quiz → Résultat → Accueil.

Ajouts faits depuis : révision ciblée (les questions ratées reviennent jusqu'à être réussies),
mélange des questions et réponses, "Revoir la fiche" après une erreur, questions de type `ordre`,
vérification automatique par GitHub Actions.

Hors périmètre : comptes utilisateurs, notifications, backend, achats.

## Modèle de données

### Contenu (fichier `assets/content.json`, en lecture seule)
```json
{
  "modules": [
    {
      "id": "grandeurs",
      "titre": "Grandeurs électriques",
      "ordre": 1,
      "fiches": [
        { "id": "ohm", "titre": "Loi d'Ohm", "contenu": "U = R × I ...", "image": "ohm.png" }
      ],
      "questions": [
        {
          "id": "q001",
          "fiche_id": "ohm",
          "type": "qcm",
          "enonce": "Une résistance de 10 Ω traversée par 2 A : tension ?",
          "reponses": ["5 V", "20 V", "0,2 V", "12 V"],
          "bonne": 1,
          "explication": "U = R × I = 10 × 2 = 20 V"
        }
      ]
    }
  ]
}
```
Le champ `type` vaut `qcm` ou `ordre`. Pour `ordre`, les `reponses` sont les étapes dans
le bon ordre et `bonne` est absent. Prévoir de pouvoir ajouter `vrai_faux` et `image` plus
tard sans casser la structure.

### Progression utilisateur (stockage local)
```json
{
  "progression": {
    "grandeurs": {
      "fiches_lues": ["ohm"],
      "questions_reussies": ["q001"],
      "questions_a_revoir": ["q004"],
      "meilleur_score": 8
    }
  },
  "historique": [
    { "module": "grandeurs", "date": "2026-09-05", "score": 8, "total": 10 }
  ]
}
```

## Modules de contenu
Objectif de Paulo : beaucoup de modules (jusqu'à 100) pour ne jamais en faire le tour.
Chaque module : un `theme` (section de l'accueil), 3 fiches illustrées, 20 questions
(qcm et ordre). Les fiches sont illustrées par un schéma dessiné ou par une « carte résumé »
générée (`tools/schemas/generer_schemas.py`, fonction `carte_resume`).

Modules existants (par thème) :
1. Grandeurs (U, I, R, P) et loi d'Ohm
2. Courant continu / alternatif
3. Circuits série / parallèle
4. Symboles et schémas
5. Dangers et sécurité de base (contact direct/indirect, disjoncteur, différentiel)
6. Mesures et appareils (multimètre, pince ampèremétrique, VAT)
7. Installation domestique (tableau, sections et calibres, salle de bains)
8. Énergie et consommation (kWh, puissance souscrite, économies)
9. Habilitation électrique : premiers repères (NF C 18-510, symboles, consignation)
10. Moteurs et transformateurs
11. Éclairage et commandes
12. Prises, interrupteurs et câblage pratique
13. Le voisinage : zones et distances
14. EPI et outillage isolé
15. Parafoudre et surtensions
16. Extérieur, garage, piscine
17. Habilitations B0 et BS en détail
18. Habilitation BR : les interventions
19. Premiers secours et incendie électrique
20. B1V, B2V et le chargé de travaux
21. Chargé de consignation et documents
22. Magnétisme et induction
23. Électronique de base
24. Photovoltaïque

Sujets à venir : domotique, véhicule électrique, réseaux et distribution, chauffage
électrique, ventilation, batteries et stockage, éclairage extérieur, normes…

20 questions par module. Paulo fait confiance à Claude Code pour rédiger les
questions : s'appuyer sur les thèmes classiques des référentiels (programmes de formation,
NF C 18-510) pour choisir les sujets, mais ne jamais reprendre de QCM (questionnaires à
choix multiples) existants d'organismes de formation. Paulo relit et corrige si besoin.

## Structure du projet
```
lib/
  main.dart
  models/        # Module, Fiche, Question, Progression
  data/          # chargement du JSON, service de stockage local
  screens/       # accueil, module, fiche, quiz, resultat, stats
  widgets/       # composants réutilisables (carte module, bouton réponse, barre de progression)
assets/
  content.json
  images/
```

## Ordre de développement
1. Squelette Flutter + chargement de `content.json` + écran Accueil (liste des modules).
2. Écran Quiz avec feedback immédiat.
3. Écran Résultat.
4. Sauvegarde locale de la progression + affichage sur l'Accueil.
5. Fiches de cours.
6. Écran Stats.
7. Polish (thème, icônes, images).

## Conventions
- Noms de fichiers en `snake_case`, classes en `PascalCase`.
- Une classe = un fichier dans `models/`.
- Pas de logique métier dans les widgets : passer par `data/` ou un provider.
- Textes de l'interface en français.
- Garder les solutions minimales : pas de package en plus sans justification.

## Plus tard (V2/V3, ne pas anticiper dans le code sauf le champ `type`)
- Modules par niveau d'habilitation (B0, BS, BR, B1V, B2V…).
- Questions de type "ordre" (étapes de consignation), "image" (choisir les EPI, équipements de protection individuelle).
- Cible possible : organismes de formation comme outil de révision pour leurs stagiaires.
