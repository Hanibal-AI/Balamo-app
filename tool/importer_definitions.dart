// Importe les définitions et étymologies remplies dans le CSV (séparé par des
// barres verticales, voir docs/tasks/LISEZMOI.md) vers
// assets/donnees/definitions.json. Le fichier produit est entièrement refait à
// partir du CSV : relancer l'outil donne le même résultat.
//
//     dart run tool/importer_definitions.dart [fichier.csv]
//
// Ensuite : `flutter test`.
import 'dart:convert';
import 'dart:io';

import 'package:balamo/models/donnees_jeu.dart';

const _csvParDefaut = 'docs/tasks/mots-sans-definition.csv';
const _dossier = 'assets/donnees';
const _sortie = '$_dossier/definitions.json';
const _entete = 'id|mot|categorie|definition|etymologie';

/// Au-delà, les erreurs suivantes sont seulement comptées.
const _erreursAffichees = 20;

void main(List<String> arguments) {
  final source = File(arguments.isEmpty ? _csvParDefaut : arguments.first);
  if (!source.existsSync()) {
    stderr.writeln('Fichier introuvable : ${source.path}');
    exitCode = 66;
    return;
  }

  Map<String, dynamic> lire(String nom) =>
      jsonDecode(File('$_dossier/$nom.json').readAsStringSync())
          as Map<String, dynamic>;
  final donnees = DonneesJeu.fromJson(lire('balamo'), lire('mastergrid'));

  final Import resultat;
  try {
    resultat = importer(source.readAsLinesSync(), donnees);
  } on FormatException catch (e) {
    stderr.writeln('${source.path} : ${e.message}');
    exitCode = 65;
    return;
  }

  File(_sortie).writeAsStringSync(jsonEncode(resultat.complements));

  for (final erreur in resultat.erreurs.take(_erreursAffichees)) {
    stderr.writeln(erreur);
  }
  final autres = resultat.erreurs.length - _erreursAffichees;
  if (autres > 0) stderr.writeln('… et $autres autres erreurs.');

  stdout.writeln('$_sortie : ${resultat.complements.length} mots complétés, '
      '${resultat.erreurs.length} lignes refusées.');
  stdout.writeln('Mots encore sans définition ou sans étymologie :');
  for (final MapEntry(key: categorie, value: nombre)
      in resultat.restants.entries) {
    stdout.writeln('  $categorie : $nombre');
  }
  // Les lignes valides sont importées ; le code signale qu'il en reste à corriger.
  if (resultat.erreurs.isNotEmpty) exitCode = 65;
}

/// Résultat de la lecture du CSV.
typedef Import = ({
  /// Textes ajoutés au dictionnaire, par jetons (« DEJA »).
  Map<String, Map<String, String>> complements,

  /// Une phrase par ligne refusée, avec son numéro.
  List<String> erreurs,

  /// Nombre de mots encore incomplets, par catégorie (« C1 »…).
  Map<String, int> restants,
});

/// Contrôle les [lignes] du CSV et retient ce qu'elles ajoutent aux [donnees].
///
/// Lève une [FormatException] si l'en-tête n'est pas celui attendu.
Import importer(List<String> lignes, DonneesJeu donnees) {
  if (lignes.isEmpty || lignes.first.replaceFirst('﻿', '') != _entete) {
    throw const FormatException('la première ligne doit être « $_entete ».');
  }

  final mots = _motsDuJeu(donnees);
  final vus = <String>{};
  final complements = <String, Map<String, String>>{};
  final erreurs = <String>[];

  for (var i = 1; i < lignes.length; i++) {
    if (lignes[i].trim().isEmpty) continue;
    void refuser(String raison) => erreurs.add('Ligne ${i + 1} : $raison');

    final colonnes = lignes[i].split('|').map((c) => c.trim()).toList();
    if (colonnes.length != 5) {
      refuser('${colonnes.length} colonnes au lieu de 5.');
      continue;
    }
    final [id, mot, categorie, definition, etymologie] = colonnes;
    final attendu = mots[id];
    if (attendu == null) {
      refuser('id « $id » inconnu dans le jeu.');
    } else if (mot != attendu.mot || categorie != attendu.categorie) {
      refuser('« $id » doit avoir le mot « ${attendu.mot} » '
          'et la catégorie ${attendu.categorie}.');
    } else if (!vus.add(id)) {
      refuser('id « $id » en double.');
    } else {
      // Le dictionnaire du jeu reste prioritaire : on ne garde que les manques.
      final ajout = {
        if (definition.isNotEmpty && !attendu.aDefinition)
          'definition': definition,
        if (etymologie.isNotEmpty && !attendu.aEtymologie)
          'etymologie': etymologie,
      };
      if (ajout.isNotEmpty) complements[id] = ajout;
    }
  }

  final restants = <String, int>{};
  for (final MapEntry(key: id, value: mot) in mots.entries) {
    final ajout = complements[id];
    final complet =
        (mot.aDefinition || (ajout?.containsKey('definition') ?? false)) &&
            (mot.aEtymologie || (ajout?.containsKey('etymologie') ?? false));
    if (!complet) restants.update(mot.categorie, (n) => n + 1, ifAbsent: () => 1);
  }

  return (complements: complements, erreurs: erreurs, restants: restants);
}

typedef _Mot = ({
  String mot,
  String categorie,
  bool aDefinition,
  bool aEtymologie,
});

/// Chaque mot et anagramme du jeu, avec ce que le dictionnaire en dit déjà.
Map<String, _Mot> _motsDuJeu(DonneesJeu donnees) {
  final mots = <String, _Mot>{};
  for (final entree in donnees.partie) {
    final jetons = [entree.tuiles, ...entree.anagrammes];
    for (final (i, id) in jetons.indexed) {
      final sens = donnees.sensDe(id);
      mots[id] = (
        mot: entree.formes[i],
        categorie: 'C${entree.degre}',
        aDefinition: sens.any((s) => s.mot.definition.isNotEmpty),
        aEtymologie: sens.any((s) => s.mot.aEtymologie),
      );
    }
  }
  return mots;
}
