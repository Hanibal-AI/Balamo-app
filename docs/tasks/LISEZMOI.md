# Remplir les définitions et étymologies

Fichier : `mots-sans-definition.csv`, séparé par des barres verticales `|`, en UTF-8.

```text
id|mot|categorie|definition|etymologie
```

## Règles

1. Un mot par ligne, toujours **5 colonnes**, donc exactement 4 barres `|`.
2. Remplir seulement `definition` et `etymologie`. Ne pas modifier `id`, `mot` ni `categorie`.
3. Virgules, points-virgules, apostrophes, guillemets et parenthèses sont libres : aucun guillemet à ajouter autour du texte.
4. Interdits dans le texte : la barre `|` et le retour à la ligne.
5. En cas de doute sur une étymologie, laisser la colonne vide. Ne rien inventer.
6. Forme conjuguée ou accordée : commencer la définition par « Forme de … : ».

## Exemple

Ligne à remplir :

```text
CAVE|cave|C1||
```

Ligne remplie :

```text
CAVE|cave|C1|Pièce située sous le rez-de-chaussée, souvent utilisée pour conserver le vin.|Du latin « cava », « creux, cavité ».
```

## Consigne à donner à une IA

> Complète les colonnes `definition` et `etymologie` des lignes ci-dessous en respectant les règles de ce document. Réponds uniquement avec les lignes complétées, dans le même ordre, dans un bloc de texte brut.

Envoyer les lignes par lots (50 à 100) avec la ligne d'en-tête, puis vérifier que le lot rendu contient le même nombre de lignes et les mêmes `id`.

## La colonne `categorie`

De `C1` (courant) à `C5` (très rare) : c'est le degré de la série dans laquelle le mot est joué. Elle sert à choisir quoi remplir en premier, par exemple les seules lignes `C1`.

## Importer dans le jeu

```bash
dart run tool/importer_definitions.dart
```

```bash
flutter test
```

- Seules les lignes qui ont une définition ou une étymologie sont importées : on peut importer au fur et à mesure.
- Les lignes fautives sont listées avec leur numéro et ne sont pas importées ; les autres le sont.
- `assets/donnees/definitions.json` est refait à chaque fois à partir du CSV : garder les textes déjà saisis dans le CSV.
- Le dictionnaire existant reste prioritaire : le CSV ne remplit que ses manques.
- Les définitions importées portent la mention « définition à relire ».

## Ouvrir dans un tableur

À l'import, choisir « autre séparateur » `|`, l'encodage UTF-8, et **aucun** délimiteur de texte.
