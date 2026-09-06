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
6. Paramètres (roue crantée sur le parcours) : thème, taille de la séance, parcours libre,
   mélange, vibrations, examen (questions, durée), export / import / réinitialisation de la
   progression, à propos. Stockés en local (`models/parametres.dart`, clé `parametres`).

Navigation : barre du bas avec Parcours / Modules / Stats.
Parcours → Module → Fiche → Quiz → Résultat → Parcours.

Parcours (inspiré de Duolingo) : les 100 modules sont rangés en 10 chapitres dans
`assets/parcours.json` (titre, couleur, illustrations, ordre des modules). L'écran
Parcours affiche la séance du jour puis un chemin en serpentin sur fond teinté par
chapitre, avec un bouton en relief par module : cadenas si verrouillé, couleur du
chapitre à faire ou en cours (bulle « Commencer » sur le module courant), vert avec
coche dès 80 % des questions réussies. Les modules se déverrouillent un à un dans
l'ordre du chemin. Une mascotte « pile » se pose en face du module courant et se
charge avec l'avancement du chapitre ; des illustrations plates (générées par
`tools/schemas/generer_decors.py`, PNG dans `assets/images/decors/`) jalonnent le
chemin. À l'ouverture, l'écran défile jusqu'au module en cours (bouton flottant pour y
revenir). Quand un quiz fait passer le seuil, l'écran Résultat fête le module (ou le
chapitre) et propose directement le module suivant. L'onglet Modules garde la liste
complète par thème, sans verrou.

Ajouts faits depuis : révision ciblée (les questions ratées reviennent jusqu'à être réussies),
mélange des questions et réponses, "Revoir la fiche" après une erreur, questions de type `ordre`,
vérification automatique par GitHub Actions, examen blanc (20 questions tirées dans les
modules déjà abordés, 10 minutes au chrono, pas de correction avant la fin, corrigé sur
l'écran Résultat, historique à part), points d'expérience (10 XP par bonne réponse, niveaux
de plus en plus longs, affichés sur la carte d'entraînement, le résultat et les stats), récap
de la semaine dans les stats (XP, quiz, jours actifs, colonnes par jour).

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
Le champ `type` vaut `qcm`, `ordre` ou `image`. Pour `ordre`, les `reponses` sont les étapes
dans le bon ordre et `bonne` est absent. Pour `image`, c'est un QCM dont l'énoncé est
illustré : le champ `image` donne le chemin relatif à `assets/images/` (ex.
`questions/sym_lampe.png`, symboles générés par `tools/schemas/generer_questions.py`, ou
`decors/gants.png` pour réutiliser les dessins du parcours). Prévoir de pouvoir ajouter
`vrai_faux` plus tard sans casser la structure.

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
Objectif de Paulo : beaucoup de modules (100 atteints) pour ne jamais en faire le tour.
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
25. Réseaux et distribution
26. Chauffage électrique et eau chaude
27. Domotique et maison connectée
28. Véhicule électrique : la recharge
29. Batteries et stockage
30. Unités et préfixes
31. Lire une plaque signalétique
32. Ventilation et climatisation
33. Outillage électroportatif et chantier
34. Normes et diagnostic électrique
35. Lire et repérer un tableau
36. Dépannage pas à pas
37. Courants faibles : téléphone, réseau, TV
38. Éclairage extérieur et jardin
39. Alarme et vidéosurveillance
40. Le triphasé en pratique
41. Mesures avancées : isolement et terre
42. Rénover une installation ancienne
43. Groupes électrogènes et alimentation de secours
44. Énergie réactive et cos φ
45. Histoire de l'électricité
46. Électricité en camping-car et bateau
47. Autoconsommation avancée et stockage
48. Électricité statique et atmosphères explosives
49. Arc électrique et travail sous tension
50. Tertiaire et ERP
51. Industrie : armoires, automates, capteurs
52. Variateurs et harmoniques
53. Haute tension : premiers repères
54. Électricité et enfants
55. Éclairage public et voirie
56. Portails, volets et ascenseurs
57. Pompes, puits et arrosage
58. Énergie éolienne
59. Hydrogène et piles à combustible
60. Nucléaire et centrales thermiques
61. Énergie hydraulique
62. Réseaux intelligents et flexibilité
63. Câbler un tableau pas à pas
64. Lire un schéma industriel
65. Moteurs pas à pas et servomoteurs
66. Soudure à l'arc et sécurité
67. Foudre et paratonnerre
68. Électricité ferroviaire
69. Électricité en agriculture
70. Électricité médicale et hôpitaux
71. Électricité en aéronautique et spatial
72. Télécoms, antennes et radio
73. Induction, fours et procédés thermiques
74. Électrochimie et galvanoplastie
75. Data centers et informatique
76. Postes HTB et transport de l'énergie
77. Maintenance préventive et thermographie
78. Champs électromagnétiques et santé
79. Les métiers de l'électricité
80. Factures et contrats professionnels
81. Pompes à chaleur
82. Sécurité incendie : le SSI
83. Courant continu haute tension et interconnexions
84. Condensateurs et bobines
85. Sélectivité et coordination des protections
86. Régimes de neutre TT, TN, IT
87. Sécurité des machines
88. Compatibilité électromagnétique (CEM)
89. Cuisines professionnelles
90. Vélos, trottinettes et mobilité légère
91. Spectacle et événementiel
92. Effets du courant sur le corps
93. Réseau de bord automobile
94. Conducteurs, isolants et matériaux
95. Calculs de circuits : Kirchhoff et diviseurs
96. Oscilloscope et signaux
97. GTB et bâtiment intelligent
98. Recyclage et fin de vie des équipements
99. Devis, documents et réception
100. Géothermie, biomasse et énergies marines

Objectif des 100 modules atteint. Les modules Symboles, EPI et Sécurité de base ont en plus
des questions `image` (20 au total). Idées pour la suite : approfondir les modules existants
(nouvelles questions, plus de questions `image`).

Au moins 20 questions par module. Paulo fait confiance à Claude Code pour rédiger les
questions : s'appuyer sur les thèmes classiques des référentiels (programmes de formation,
NF C 18-510) pour choisir les sujets, mais ne jamais reprendre de QCM (questionnaires à
choix multiples) existants d'organismes de formation. Paulo relit et corrige si besoin.

## Structure du projet
```
lib/
  main.dart
  models/        # Module, Fiche, Question, Progression
  data/          # chargement du JSON, service de stockage local
  screens/       # parcours, accueil (onglet Modules), module, fiche, quiz, resultat, stats,
                 # parametres
  widgets/       # composants réutilisables (carte module, bouton réponse, bouton en relief,
                 # nœud et bannière du parcours, carte d'entraînement)
assets/
  content.json    # modules, fiches, questions
  parcours.json   # chapitres du parcours et ordre des modules
  images/         # schémas des fiches ; decors/ : illustrations et mascotte du parcours
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
