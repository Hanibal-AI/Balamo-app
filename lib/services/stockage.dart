import 'package:shared_preferences/shared_preferences.dart';

import '../models/niveau.dart';

/// Ce que l'application garde d'une session à l'autre : les records (un par
/// niveau), le plus haut niveau débloqué et les derniers réglages choisis.
abstract class Stockage {
  int lireRecord(Niveau niveau);
  Future<void> ecrireRecord(Niveau niveau, int valeur);

  Niveau? get dernierNiveau;
  Future<void> memoriserNiveau(Niveau niveau);

  /// Numéro du plus haut niveau accessible (1 au départ).
  int get niveauDebloque;
  Future<void> ecrireNiveauDebloque(int numero);

  /// Réglages oui / non (sons, musique…).
  bool lireReglage(String cle, {required bool parDefaut});
  Future<void> ecrireReglage(String cle, bool valeur);
}

/// Stockage persistant (SharedPreferences : Android et iOS).
class StockagePreferences implements Stockage {
  StockagePreferences(this._prefs);

  final SharedPreferences _prefs;

  static Future<StockagePreferences> ouvrir() async =>
      StockagePreferences(await SharedPreferences.getInstance());

  static String _cle(Niveau niveau) => 'balamo-record-${niveau.name}';

  @override
  int lireRecord(Niveau niveau) => _prefs.getInt(_cle(niveau)) ?? 0;

  @override
  Future<void> ecrireRecord(Niveau niveau, int valeur) =>
      _prefs.setInt(_cle(niveau), valeur);

  @override
  Niveau? get dernierNiveau {
    final nom = _prefs.getString('balamo-niveau');
    for (final n in Niveau.values) {
      if (n.name == nom) return n;
    }
    return null;
  }

  @override
  Future<void> memoriserNiveau(Niveau niveau) =>
      _prefs.setString('balamo-niveau', niveau.name);

  @override
  int get niveauDebloque => _prefs.getInt('balamo-niveau-debloque') ?? 1;

  @override
  Future<void> ecrireNiveauDebloque(int numero) =>
      _prefs.setInt('balamo-niveau-debloque', numero);

  @override
  bool lireReglage(String cle, {required bool parDefaut}) =>
      _prefs.getBool('balamo-$cle') ?? parDefaut;

  @override
  Future<void> ecrireReglage(String cle, bool valeur) =>
      _prefs.setBool('balamo-$cle', valeur);
}

/// Stockage en mémoire, pour les tests (rien n'est conservé).
class StockageMemoire implements Stockage {
  StockageMemoire({this.niveauDebloque = 1});

  final Map<Niveau, int> _records = {};

  @override
  Niveau? dernierNiveau;

  @override
  int niveauDebloque;

  @override
  int lireRecord(Niveau niveau) => _records[niveau] ?? 0;

  @override
  Future<void> ecrireRecord(Niveau niveau, int valeur) async {
    _records[niveau] = valeur;
  }

  @override
  Future<void> memoriserNiveau(Niveau niveau) async {
    dernierNiveau = niveau;
  }

  @override
  Future<void> ecrireNiveauDebloque(int numero) async {
    niveauDebloque = numero;
  }

  final Map<String, bool> _reglages = {};

  @override
  bool lireReglage(String cle, {required bool parDefaut}) =>
      _reglages[cle] ?? parDefaut;

  @override
  Future<void> ecrireReglage(String cle, bool valeur) async {
    _reglages[cle] = valeur;
  }
}
