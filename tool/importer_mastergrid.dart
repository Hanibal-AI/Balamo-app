// Fabrique le fichier des mots joués à partir des CSV « base de production
// C1 à C5 ». Sont retenus tous les mots qu'au moins un niveau admet (voir
// `Niveau.admet`), sauf les « séries avec bonus » (la Mastergrid ne retient que
// des séries pures), les mots sensibles et les lignes au statut « Rejeté ».
//
//     dart run tool/importer_mastergrid.dart [dossier des CSV]
//
// Ensuite : `flutter test` (test/donnees_et_tirage_test.dart contrôle le fichier).
import 'dart:convert';
import 'dart:io';

import 'package:balamo/models/niveau.dart';
import 'package:balamo/models/tuiles.dart';

const _dossierParDefaut = 'docs/informations/C1-C5-words';
const _sortie = 'assets/donnees/mastergrid.json';

/// « Anagramme 1 » à « Anagramme 6 » : les réponses demandées au joueur.
const _anagrammesParLigne = 6;

final _nomDeFichier = RegExp(r'C([1-5])\.csv$');

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
      .where((f) => _nomDeFichier.hasMatch(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  // Les mots par degré, chacun suivi de ses anagrammes.
  final degres = <String, List<List<String>>>{};
  final parNiveau = {for (final n in Niveau.values) n: (series: 0, pieges: 0)};
  for (final fichier in fichiers) {
    final degre = int.parse(_nomDeFichier.firstMatch(fichier.path)!.group(1)!);
    final lignes = _lireCsv(fichier.readAsStringSync());
    final colonnes = lignes.first;
    for (final valeurs in lignes.skip(1)) {
      final ligne = Map.fromIterables(colonnes, valeurs);
      if (_ecartee(ligne)) continue;

      final mot = ligne['Mot à afficher']!;
      final anagrammes = int.tryParse(ligne['Nb d\'anagrammes']!) ?? 0;
      final niveaux = Niveau.values.where((n) => n.admet(
            lettres: enTuiles(mot).length,
            degre: degre,
            anagrammes: anagrammes,
          ));
      if (niveaux.isEmpty) continue;

      for (final n in niveaux) {
        final (:series, :pieges) = parNiveau[n]!;
        parNiveau[n] = anagrammes == 0
            ? (series: series, pieges: pieges + 1)
            : (series: series + 1, pieges: pieges);
      }
      degres.putIfAbsent('$degre', () => []).add([
        mot,
        for (var i = 1; i <= _anagrammesParLigne; i++)
          if (ligne['Anagramme $i']!.isNotEmpty) ligne['Anagramme $i']!,
      ]);
    }
  }
  if (degres.isEmpty) {
    stderr.writeln('Aucun mot jouable dans ${dossier.path}.');
    exitCode = 65;
    return;
  }

  File(_sortie).writeAsStringSync(jsonEncode({'degres': degres}));
  final total = degres.values.fold(0, (somme, lot) => somme + lot.length);
  stdout.writeln('$_sortie : $total mots différents.');
  for (final MapEntry(key: n, value: lot) in parNiveau.entries) {
    stdout.writeln('Niveau ${n.numero} : ${lot.series} à anagrammes, '
        '${lot.pieges} pièges, ${lot.series + lot.pieges} au total.');
  }
  stdout.writeln('Lance maintenant « flutter test ».');
}

bool _ecartee(Map<String, String> ligne) =>
    ligne['Catégorie'] == 'Série avec bonus' ||
    ligne['Mot sensible']!.isNotEmpty ||
    ligne['Statut'] == 'Rejeté';

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
