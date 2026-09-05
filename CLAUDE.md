# ElecApp — appli d'apprentissage de l'électricité

## Contexte
Projet perso d'apprentissage : le but premier est que je (Paulo) apprenne à faire une appli mobile.
L'appli sert à apprendre les bases de l'électricité (V1), puis à préparer l'habilitation
électrique NF C 18-510 (V2+).

**Important pour Claude Code :** je veux comprendre ce qui est fait.
- Explique brièvement chaque choix technique avant de coder.
- Avance par petites étapes, une feature à la fois, et attends ma validation entre chaque.
- Ne génère pas toute l'appli d'un coup.
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

Hors périmètre V1 : comptes utilisateurs, répétition espacée, notifications, backend, achats.

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
Le champ `type` vaut `qcm` en V1. Prévoir dans les classes Dart de pouvoir ajouter
`vrai_faux`, `ordre` et `image` plus tard sans casser la structure.

### Progression utilisateur (stockage local)
```json
{
  "progression": {
    "grandeurs": {
      "fiches_lues": ["ohm"],
      "questions_reussies": ["q001"],
      "meilleur_score": 8
    }
  },
  "historique": [
    { "module": "grandeurs", "date": "2026-09-05", "score": 8, "total": 10 }
  ]
}
```

## Modules de contenu V1
1. Grandeurs (U, I, R, P) et loi d'Ohm
2. Courant continu / alternatif
3. Circuits série / parallèle
4. Symboles et schémas
5. Dangers et sécurité de base (contact direct/indirect, disjoncteur, différentiel)

Environ 10 questions par module. Le contenu est rédigé par moi ; Claude Code peut
proposer des questions mais je valide chaque module. Ne jamais reprendre de QCM
(questionnaires à choix multiples) existants d'organismes de formation.

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
