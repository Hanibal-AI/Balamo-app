# Remplir les définitions et étymologies

Fichier : `mots-sans-definition.csv`, séparé par des barres verticales `|`, en UTF-8.

```text
id|mot|definition|etymologie
```

## Règles

1. Un mot par ligne, toujours **4 colonnes**, donc exactement 3 barres `|`.
2. Remplir seulement `definition` et `etymologie`. Ne pas modifier `id` ni `mot`, ni l'ordre des lignes.
3. Virgules, points-virgules, apostrophes, guillemets et parenthèses sont libres : aucun guillemet à ajouter autour du texte.
4. Interdits dans le texte : la barre `|` et le retour à la ligne.
5. En cas de doute sur une étymologie, laisser la colonne vide. Ne rien inventer.
6. Forme conjuguée ou accordée : commencer la définition par « Forme de … : ».

## Exemple

Ligne à remplir :

```text
CAVE|cave||
```

Ligne remplie :

```text
CAVE|cave|Pièce située sous le rez-de-chaussée, souvent utilisée pour conserver le vin.|Du latin « cava », « creux, cavité ».
```

## Consigne à donner à une IA

> Complète les colonnes `definition` et `etymologie` des lignes ci-dessous en respectant les règles de ce document. Réponds uniquement avec les lignes complétées, dans le même ordre, dans un bloc de texte brut.

Envoyer les lignes par lots (50 à 100) avec la ligne d'en-tête, puis vérifier que le lot rendu contient le même nombre de lignes et les mêmes `id`.

## Ouvrir dans un tableur

À l'import, choisir « autre séparateur » `|`, l'encodage UTF-8, et **aucun** délimiteur de texte.
