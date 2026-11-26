// Fabrique les réserves de mots des dix niveaux à partir des CSV « base de
// production C1 à C5 » : seules les lignes avec un « Niveau attribué » sont
// retenues.
//
//     dart run tool/importer_mastergrid.dart [dossier des CSV]
//
// Ensuite : `flutter test` (test/donnees_et_tirage_test.dart contrôle le fichier).
import 'dart:convert';
import 'dart:io';

const _dossierParDefaut = 'docs/informations/C1-C5-words';
const _sortie = 'assets/donnees/mastergrid.json';

/// « Anagramme 1 » à « Anagramme 6 » : les réponses demandées au joueur.
const _anagrammesParLigne = 6;

/// Lettres accentuées et ligatures, ramenées à ce qui est écrit sur les jetons.
const _sansAccent = {
  'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ç': 'C', 'É': 'E', 'È': 'E', 'Ê': 'E',
  'Ë': 'E', 'Î': 'I', 'Ï': 'I', 'Ô': 'O', 'Ö': 'O', 'Ù': 'U', 'Û': 'U',
  'Ü': 'U', 'Ÿ': 'Y', 'Œ': 'OE', 'Æ': 'AE',
};

void main(List<String> arguments) {
  final dossier = Directory(arguments.isEmpty ? _dossierParDefaut : arguments.first);
  if (!dossier.existsSync()) {
    stderr.writeln('Dossier introuvable : ${dossier.path}');
    exitCode = 66;
    return;
  }

  final fichiers = dossier
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'C[1-5]\.csv$').hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final mots = <Map<String, Object>>[];
  for (final fichier in fichiers) {
    final lignes = _lireCsv(fichier.readAsStringSync());
    final colonnes = lignes.first;
    for (final valeurs in lignes.skip(1)) {
      final ligne = Map.fromIterables(colonnes, valeurs);
      final niveau = int.tryParse(ligne['Niveau attribué']!.trim());
      if (niveau == null) continue;

      final mot = ligne['Mot à afficher']!;
      final anagrammes = [
        for (var i = 1; i <= _anagrammesParLigne; i++)
          if (ligne['Anagramme $i']!.isNotEmpty) ligne['Anagramme $i']!,
      ];
      mots.add({
        'niveau': niveau,
        'tuiles': _tuiles(mot),
        'anagrammes': anagrammes.map(_tuiles).toList(),
        // Orthographe accentuée de chaque jeu de jetons.
        'formes': {for (final forme in [mot, ...anagrammes]) _tuiles(forme): forme},
      });
    }
  }
  if (mots.isEmpty) {
    stderr.writeln('Aucun mot avec un « Niveau attribué » dans ${dossier.path}.');
    exitCode = 65;
    return;
  }
  mots.sort((a, b) => (a['niveau']! as int).compareTo(b['niveau']! as int));

  File(_sortie).writeAsStringSync(jsonEncode({'mots': mots}));
  stdout.writeln('$_sortie : ${mots.length} mots. Lance maintenant « flutter test ».');
}

String _tuiles(String mot) =>
    mot.toUpperCase().split('').map((l) => _sansAccent[l] ?? l).join();

/// Lecture d'un CSV : champs entre guillemets, virgules et retours à la ligne.
List<List<String>> _lireCsv(String texte) {
  final lignes = <List<String>>[];
  var ligne = <String>[];
  final champ = StringBuffer();
  var entreGuillemets = false;

  void finirChamp() {
    ligne.add(champ.toString());
    champ.clear();
  }

  void finirLigne() {
    finirChamp();
    lignes.add(ligne);
    ligne = <String>[];
  }

  final source = texte.replaceFirst('﻿', '').replaceAll('\r\n', '\n');
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    if (entreGuillemets) {
      if (c != '"') {
        champ.write(c);
      } else if (i + 1 < source.length && source[i + 1] == '"') {
        champ.write('"');
        i++;
      } else {
        entreGuillemets = false;
      }
    } else if (c == '"') {
      entreGuillemets = true;
    } else if (c == ',') {
      finirChamp();
    } else if (c == '\n') {
      finirLigne();
    } else {
      champ.write(c);
    }
  }
  if (champ.isNotEmpty || ligne.isNotEmpty) finirLigne();
  return lignes;
}
