# 04 · Architecture

Où se trouve quoi dans le projet, et quel fichier ouvrir pour changer une règle ou un écran.

## Le principe

Le code est séparé en deux mondes qui ne se mélangent pas :

- **La logique du jeu** (`lib/logic/`, `lib/models/`) : du Dart pur, sans aucun widget. Elle connaît les règles, le score, le chrono, l'état de la partie.
- **L'interface** (`lib/screens/`, `lib/widgets/`, `lib/theme/`) : elle *affiche* l'état de la partie et *transmet* les gestes du joueur. Elle ne décide de rien.

Le lien entre les deux est un seul objet, `PartieController` (un `ChangeNotifier`, exposé aux écrans avec le paquet `provider`) :

```
 geste du joueur                         notifyListeners()
┌──────────────┐  partie.validerPari()  ┌──────────────────┐  context.watch()  ┌─────────────┐
│   Widgets    │ ─────────────────────▶ │ PartieController │ ────────────────▶ │   Widgets   │
│ (interface)  │                        │   (état + règles)│                   │ redessinés  │
└──────────────┘                        └──────────────────┘                   └─────────────┘
```

Conséquence pratique : on peut changer tout le design sans risquer de casser une règle, et tester toutes les règles sans écran (`flutter test`).

## Les dossiers

```
lib/
├── main.dart                 Démarrage : portrait, chargement des données, vibrations
├── app.dart                  MaterialApp, thème clair/sombre, aiguillage entre les 3 écrans
│
├── models/                   LES DONNÉES (aucune logique d'affichage)
│   ├── niveau.dart             Les 10 niveaux et leurs réglages (catégorie, pièges, indices, chrono…)
│   ├── mot.dart                Entrée de dictionnaire : définition, racines, fiche étymologique
│   ├── donnees_jeu.dart        Le fichier de mots une fois chargé (mots jouables, anagrammes, sens)
│   └── etat_manche.dart        Petits types d'état : phase, jeton, verdict, ligne du bilan
│
├── logic/                    LES RÈGLES DU JEU
│   ├── regles.dart             Barème, mots par partie, valeur des jetons, durées
│   ├── tirage.dart             Composition d'une partie (pioche, pièges) et mélange des lettres
│   ├── partie_controller.dart  Déroulé d'une partie : pari → recherche → révélation → bilan
│   └── reglages_audio.dart     Interrupteurs « Sons » et « Musique » du joueur
│
├── services/                 L'EXTÉRIEUR
│   ├── depot_donnees.dart      Lecture des fichiers de assets/donnees/
│   ├── stockage.dart           Records et réglages mémorisés (SharedPreferences)
│   ├── audio.dart              Ce que le jeu attend d'un moteur sonore (+ version muette)
│   └── audio_balamo.dart       Le moteur sonore réel : quel son pour quelle action
│
├── theme/                    L'IDENTITÉ VISUELLE
│   ├── couleurs.dart           Palette claire et sombre (papier, encre, violette, bois…)
│   ├── typo.dart               Les 4 polices et leurs styles
│   └── theme.dart              Thème Material 3 construit à partir de la palette
│
├── screens/                  LES ÉCRANS
│   ├── mise_en_page.dart       Gabarit commun : contenu + panneau d'action en bas (zone du pouce)
│   ├── ecran_accueil.dart      Choix du niveau et de la longueur de partie
│   ├── ecran_jeu.dart          La manche : pari, table de jeu, révélation
│   └── ecran_bilan.dart        Score final, record, détail des manches
│
└── widgets/                  LES BRIQUES RÉUTILISABLES
    ├── table_jeu.dart          Plateau + chevalet, appui et glisser-déposer des jetons
    ├── jeton_widget.dart       Un jeton en bois
    ├── cases_anagrammes.dart   Les cases « ····· » des anagrammes à trouver
    ├── revelation.dart         Sens et étymologie d'un mot
    ├── mini_markdown.dart      Rendu du texte des fiches (gras, italique, liens, listes)
    ├── en_tete.dart            Marque, compteurs, barre des 3 étapes
    ├── boutons.dart            Boutons, étiquettes, pastilles
    └── regles_feuille.dart     La feuille « Règles et points »

assets/
├── donnees/balamo.json       Dictionnaire : définitions et étymologies
├── donnees/mastergrid.json     Mots et anagrammes des 10 niveaux
├── fonts/                    Alegreya, Alegreya Sans, Alegreya Sans SC, Archivo (licence OFL)
├── sons/                     Bruitages (.wav) et musique d'ambiance (musique.m4a)
└── icone/                    Sources de l'icône de l'application

test/                         Tests automatiques (voir 02-developpement-et-test.md)
tool/                         Outils : captures d'écran, icône, sons, import des données
android/  ios/                Projets natifs générés par Flutter
```

## Je veux modifier…

### …les règles et les points

| Pour changer | Ouvre | Et modifie |
| --- | --- | --- |
| Les points d'un bon pari, d'une anagramme, du bonus | `lib/logic/regles.dart` | `pointsBonPari`, `pointsBonPiege`, `pointsBonNombre`, `pointsAnagramme`, `pointsToutesTrouvees` |
| Le multiplicateur, le chrono, les pièges, le prix et le nombre d'indices, l'objectif d'un niveau | `lib/models/niveau.dart` | les valeurs de `n1` à `n10` |
| Le nombre de mots d'une partie | `lib/logic/regles.dart` | `motsParPartie` |
| La façon de composer une partie | `lib/logic/tirage.dart` | `composerPioche` |
| Ce qui se passe quand un mot est posé, quand le temps est écoulé, etc. | `lib/logic/partie_controller.dart` | `_apresCoup`, `validerPari`, `demanderIndice`, `abandonner`… |

L'accueil et la feuille « Règles et points » lisent ces valeurs : ils se mettent à jour tout seuls. Après un changement de règle, lance `flutter test` : les tests de `test/partie_controller_test.dart` qui décrivent l'ancienne règle échoueront, c'est le moment de les ajuster.

#### Comment fonctionnent les indices

Le bouton **Indice** dévoile une lettre de plus de chaque anagramme restante (jamais la dernière). Son prix (`prixIndice`, de 5 à 100 points) et le nombre autorisé par mot (`indicesMax`) dépendent du niveau :

- l'indice **s'achète** : sans assez de points pour son coût, il est refusé (le score ne devient jamais négatif, et on ne peut pas se servir gratuitement en début de partie) ;
- le bilan indique le nombre d'indices utilisés et les points de la manche, indices déduits ;
- le record retient le meilleur score atteint.

### …l'apparence

| Pour changer | Ouvre |
| --- | --- |
| Une couleur (clair ou sombre) | `lib/theme/couleurs.dart` |
| Une police, une taille de texte récurrente | `lib/theme/typo.dart` (et `pubspec.yaml` pour ajouter un fichier de police) |
| La forme des boutons | `lib/widgets/boutons.dart` |
| L'aspect des jetons, du plateau, du chevalet | `lib/widgets/jeton_widget.dart`, `lib/widgets/table_jeu.dart` |
| La disposition d'un écran | le fichier correspondant dans `lib/screens/` |
| L'affichage des définitions et de l'étymologie | `lib/widgets/revelation.dart` |
| Les textes affichés au joueur | à l'endroit où ils apparaissent : messages du jeu dans `partie_controller.dart`, libellés dans les écrans |
| L'icône | `python3 tool/generer_icone.py` puis `dart run flutter_launcher_icons` |

### …les sons et la musique

Chaque action du jeu signale un événement (`Retour`, défini en tête de `lib/logic/partie_controller.dart`) : jeton posé, mélange, indice, mot trouvé… L'application traduit chaque événement en son et en vibration.

| Pour changer | Ouvre |
| --- | --- |
| Le son associé à une action, ou son volume | `lib/services/audio_balamo.dart`, la table `_bruitages` |
| Le volume de la musique | `lib/services/audio_balamo.dart`, `volumeMusique` |
| La vibration associée à une action | `lib/main.dart`, `_vibrer` |
| Le moment où un événement est signalé | `lib/logic/partie_controller.dart` (cherche `surRetour`) |
| Le timbre d'un son, la mélodie, le tempo de la musique | `tool/generer_sons.py`, puis relance-le |
| Remplacer un son par un fichier à toi | dépose-le dans `assets/sons/` sous le même nom (WAV pour un bruitage, `musique.m4a` pour la musique) |

Tous les sons sont **fabriqués par synthèse** par `tool/generer_sons.py` (aucun échantillon extérieur, donc aucun droit à régler) :

```bash
python3 tool/generer_sons.py
```

Les choix faits pour que le son reste agréable sur la durée :

- un timbre de bois et de marimba, des attaques douces, presque rien au-dessus de 6 kHz ;
- le geste le plus fréquent — poser un jeton — a cinq variantes tirées au hasard, jamais deux fois la même de suite ;
- pas de buzzer : un mot refusé fait deux petits coups de bois ;
- bruitages et musique sont dans la même gamme (do majeur pentatonique), ils ne « frottent » jamais ;
- la musique est une boucle calme d'environ 1 min 30 qui s'éteint puis revient en douceur, jouée en fond à volume réduit ;
- le jeu ne coupe pas le son des autres applications (podcast, musique), et la musique se tait dès que Balamo passe en arrière-plan ;
- le joueur garde la main : deux interrupteurs **Sons** et **Musique** sur l'accueil, mémorisés.

### …les mots du jeu

Les mots joués sont dans `assets/donnees/mastergrid.json`, fabriqué par `dart run tool/importer_mastergrid.dart` à partir des CSV « base de production C1 à C5 » (lignes avec un « Niveau attribué »).

Le dictionnaire (définitions et étymologies) est dans `assets/donnees/balamo.json`. Un mot sans entrée reste jouable : la révélation indique qu'il n'en a pas encore. La rubrique `partie` de ce fichier n'est plus jouée.


Le dictionnaire contient :

- `mots` : les entrées de dictionnaire (définition, racines, fiche étymologique en mini-markdown) ;
- `orthographes` : pour chaque suite de lettres, la ou les formes accentuées et le mot auquel elles renvoient.

Si tu régénères le prototype HTML depuis ta base de notes, l'outil d'import en extrait directement ce fichier :

```bash
dart run tool/importer_donnees.dart "chemin/vers/Le ForMika, anagrammes.html"
```

Puis `flutter test` : `test/donnees_et_tirage_test.dart` vérifie la cohérence des deux fichiers (anagrammes valides, réserve de chaque niveau).

## Le trajet d'un geste, pas à pas

Exemple : le joueur fait glisser le dernier jeton sur le plateau et forme « NICHE ».

1. `TableJeu` (`widgets/table_jeu.dart`) suit le doigt. Elle calcule sous quel emplacement il se trouve et appelle `partie.deplacerJeton(id, zone, index)` : les autres jetons s'écartent.
2. Au lâcher, elle appelle `partie.relacherJeton()`.
3. `PartieController._apresCoup()` lit le mot posé, le compare aux anagrammes, ajoute les points (`Regles.pointsAnagramme` × multiplicateur), met à jour le message, l'état du plateau et la révélation, puis appelle `notifyListeners()`.
4. Les widgets abonnés (`context.watch<PartieController>()`) se redessinent : le score monte, la case passe au vert, l'étymologie apparaît.

L'écran affiché suit la même logique : `PartieController.vue` vaut `accueil`, `jeu` ou `bilan`, et `app.dart` montre l'écran correspondant. Il n'y a pas de pile de navigation à gérer.

## Compatibilité Android / iOS

- Aucune dépendance propre à une plateforme : `provider` (état), `shared_preferences` (records, réglages), `url_launcher` (liens des sources) et `audioplayers` (sons) fonctionnent à l'identique sur Android et iOS.
- Polices, données et sons sont embarqués : le jeu fonctionne hors ligne. Seuls les liens « Sources » ouvrent le navigateur.
- Orientation portrait imposée à trois endroits cohérents : `main.dart`, `android/app/src/main/AndroidManifest.xml` et `ios/Runner/Info.plist`.
- Mise en page : `SafeArea` et marges système pour les encoches et la barre de gestes, tailles calculées à partir de la largeur d'écran (les jetons rétrécissent pour les mots longs), colonne limitée à 620 px sur tablette, taille de texte du système respectée dans une limite raisonnable.

## À propos de `material_ui`

Depuis Flutter 3.50, les widgets Material ne sont plus dans le SDK mais dans le paquet `material_ui` (dépendance déclarée dans `pubspec.yaml`). C'est pourquoi les fichiers importent `package:material_ui/material_ui.dart` et non plus `package:flutter/material.dart`. Les widgets eux-mêmes (`Scaffold`, `MaterialApp`, `ThemeData`…) sont inchangés.
