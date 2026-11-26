# Journal des versions

Les versions de Balamo, de la plus récente à la plus ancienne.

- **Nom de version** : le numéro affiché aux joueurs (`versionName`).
- **Code de version** : le numéro de build, unique à chaque envoi sur le Play Store (`versionCode`).

Les deux se règlent dans `pubspec.yaml` (`version: nom+code`).

| Nom | Code | Envoi sur le Play Store | État sur le Play Store |
| --- | --- | --- | --- |
| 1.0.1 | 3 | Pas encore envoyé | À publier |
| 1.0.1 | 2 | 20 novembre 2026 | Inactif |
| 1.0.0 | 1 | 19 novembre 2026 | Actif |

États relevés dans la Play Console le 26 novembre 2026.

## 1.0.1 (code 3)

Pas encore envoyé.

### Modifié

- Les trois niveaux (facile, intermédiaire, expert) laissent place à 10 niveaux, en deux catégories : entraînement (1, 2, 4, 5, 7, 8) et compétition (3, 6, 9, 10).
- Nouvel accueil : deux carrés Entraînement et Compétition, et une barre des niveaux.
- Une partie compte toujours 5 mots (le choix 5 ou 10 manches disparaît).
- Nouveaux mots : environ 69 000 mots issus des listes C1 à C5 remplacent les 104 précédents. La plupart n'ont pas encore de définition ni d'étymologie.
- Le tirage respecte les longueurs, les degrés et le nombre d'anagrammes de chaque niveau.
- Pièges, prix et nombre d'indices, chrono et multiplicateur propres à chaque niveau.
- Les records des anciens niveaux ne sont pas repris.

### Ajouté

- Import des définitions et étymologies depuis un fichier CSV, pour compléter le dictionnaire.
- Déblocage du niveau suivant en atteignant un objectif de score.
- En compétition, temps de recherche mesuré par manche et affiché au bilan.

### Compilation et diffusion

- Ajout du workflow GitHub Actions **Build AAB**, à lancer à la main, qui compile et signe l'App Bundle.
- Le workflow contrôle le keystore (lisibilité, alias, empreinte) et affiche un message clair en cas d'erreur.
- Code de version porté à 3.

## 1.0.1 (code 2)

Envoyé le 20 novembre 2026.

### Modifié

- Les indices sont désormais disponibles aux trois niveaux, et non plus seulement en facile. Un indice coûte 5 points en facile, 10 en intermédiaire et 15 en expert.
- En expert, la carte du niveau affiche à la fois le chrono et le coût d'un indice.
- La feuille des règles ne précise plus les niveaux sur la ligne des indices.

### Corrigé

- L'application n'est plus réservée par le Play Store aux appareils qui déclarent un écran portrait : elle reste proposée sur les tablettes et les Chromebooks.

## 1.0.0 (code 1)

Envoyé le 19 novembre 2026. Première version.

### Ajouté

- Jeu d'anagrammes et d'étymologie en trois temps : le pari, la recherche, la révélation.
- Trois niveaux : facile, intermédiaire et expert (chrono de 90 secondes).
- Indices en facile, score et record.
- Bruitages et musique d'ambiance, désactivables depuis l'accueil.
- Fonctionnement hors ligne, sans compte ni publicité.
- Identifiant Android `fr.balamo.game` et signature avec la clé d'envoi.
