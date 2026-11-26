import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/donnees_jeu.dart';

/// Charge les données du jeu embarquées dans l'application.
abstract final class DepotDonnees {
  /// Le dictionnaire : définitions et étymologies.
  static const String chemin = 'assets/donnees/balamo.json';

  /// Les mots des dix niveaux (voir `tool/importer_mastergrid.dart`).
  static const String cheminGrille = 'assets/donnees/mastergrid.json';

  /// Définitions et étymologies importées (voir
  /// `tool/importer_definitions.dart`).
  static const String cheminDefinitions = 'assets/donnees/definitions.json';

  static Future<DonneesJeu> charger({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final bruts = (
      await source.loadString(chemin),
      await source.loadString(cheminGrille),
      await source.loadString(cheminDefinitions),
    );
    // Le dictionnaire pèse ~600 Ko : on le décode hors du fil d'interface.
    return compute(_decoder, bruts);
  }
}

DonneesJeu _decoder((String, String, String) bruts) => DonneesJeu.fromJson(
      jsonDecode(bruts.$1) as Map<String, dynamic>,
      jsonDecode(bruts.$2) as Map<String, dynamic>,
      jsonDecode(bruts.$3) as Map<String, dynamic>,
    );
