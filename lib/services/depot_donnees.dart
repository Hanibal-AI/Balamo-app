import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/donnees_jeu.dart';

/// Charge les données du jeu embarquées dans l'application.
abstract final class DepotDonnees {
  static const String chemin = 'assets/donnees/balamo.json';

  static Future<DonneesJeu> charger({AssetBundle? bundle}) async {
    final brut = await (bundle ?? rootBundle).loadString(chemin);
    // Le fichier pèse ~600 Ko : on le décode hors du fil d'interface.
    return compute(_decoder, brut);
  }
}

DonneesJeu _decoder(String brut) =>
    DonneesJeu.fromJson(jsonDecode(brut) as Map<String, dynamic>);
