# Balamo

**Le jeu où chaque mot en cache un autre.**

*Parier, chercher, découvrir : des anagrammes, et l'histoire des mots qui va avec.*

## En bref

| | |
| --- | --- |
| **Genre** | Jeu de lettres : anagrammes et étymologie |
| **Plateformes** | Android (7.0 et plus) ; iOS prévu |
| **Langue** | Français |
| **Durée d'une partie** | 5 ou 10 mots, soit quelques minutes |
| **Joueurs** | 1 |
| **Connexion** | Aucune : le jeu fonctionne hors ligne, sans compte et sans publicité |
| **Contenu** | 104 mots à jouer, chacun avec sa définition et son histoire |
| **Version** | 1.0.1, en phase de test (Android, publication sur le Play Store en cours) |

## Le principe

Un mot du dictionnaire s'affiche. A-t-il une anagramme ? Deux ? Aucune ? Avant de toucher la moindre lettre, il faut parier. Et attention : certains mots sont des pièges, ils n'en ont aucune.

Vient ensuite la recherche. Les lettres attendent sur le chevalet, sous forme de jetons de bois. On les fait glisser sur le plateau, on les mélange, on recommence, jusqu'à voir apparaître le mot caché.

Chaque mot trouvé livre alors son sens et son histoire : d'où il vient, par quelles langues il est passé, ce qu'il voulait dire autrefois. On vient pour le jeu de lettres, on repart avec l'étymologie.

## Une manche en trois temps

| 1 · Le pari | 2 · La recherche | 3 · La révélation |
| --- | --- | --- |
| ![Le pari](docs/captures/07-pari-combien.png) | ![La recherche](docs/captures/03-recherche.png) | ![La révélation](docs/captures/06-revelation.png) |
| Ce mot a-t-il une anagramme ? Et combien ? | Déplacer les jetons du chevalet vers le plateau pour former les mots cachés. | Le sens et l'histoire de chaque mot trouvé. |

## Trois niveaux

| Niveau | Le pari | Particularité | Points |
| --- | --- | --- | --- |
| **Facile** | Oui ou non | Indices disponibles (−5 points chacun) | × 1 |
| **Intermédiaire** | Oui ou non, puis combien | Indices disponibles (−10 points chacun) | × 2 |
| **Expert** | Oui ou non, puis combien | 90 secondes pour tout trouver, indices disponibles (−15 points chacun) | × 3 |

## Le score

| Action | Points de base |
| --- | --- |
| Bon pari oui / non | +10 |
| Bon « non » sur un mot piège | +30 |
| Bon nombre d'anagrammes | +20 |
| Chaque anagramme trouvée | +15 |
| Toutes les anagrammes trouvées | +10 |
| Chaque indice demandé | −5 |

Les points sont multipliés selon le niveau. Un indice dévoile une lettre mais se paie tout de suite : il faut avoir assez de points pour se l'offrir.

## Les points forts

- **Un jeu de lettres qui apprend quelque chose** : chaque mot trouvé raconte son origine.
- **Le pari avant la recherche** : une part de flair et de risque, pas seulement de la manipulation de lettres.
- **Des mots pièges** qui obligent à réfléchir avant de répondre « oui ».
- **Des parties courtes**, pensées pour le téléphone et pour une main : jetons à toucher ou à glisser, boutons sous le pouce.
- **Un record à battre** pour chaque niveau et chaque longueur de partie.
- **Une ambiance calme** : papier, encre et bois, sons de marimba, musique douce, thème clair ou sombre. Sons et musique se coupent séparément.

## Quelques écrans

| Accueil | Mot piège | Niveau expert, thème sombre | Bilan |
| --- | --- | --- | --- |
| ![Accueil](docs/captures/01-accueil.png) | ![Mot piège](docs/captures/09-piege.png) | ![Expert](docs/captures/08-expert-sombre.png) | ![Bilan](docs/captures/10-bilan.png) |

## Fiche technique

| | |
| --- | --- |
| **Technologie** | Flutter (Dart), interface Material 3, un seul code pour Android et iOS |
| **Android** | 7.0 (API 24) au minimum |
| **Taille de l'APK** | Environ 53 Mo |
| **Orientation** | Portrait |
| **Données** | Mots, définitions et étymologies embarqués dans l'application |
| **Sauvegarde** | Records et réglages conservés sur l'appareil |
| **Polices** | Alegreya, Alegreya Sans, Alegreya Sans SC, Archivo (licence SIL Open Font) |

Pour installer, compiler ou modifier le jeu, voir le [README](README.md) et les guides du dossier [`docs/`](docs/).
