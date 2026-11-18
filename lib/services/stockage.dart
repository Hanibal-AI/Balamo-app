import 'package:shared_preferences/shared_preferences.dart';

import '../models/niveau.dart';

/// Ce que l'application garde d'une session à l'autre : les records
/// (un par niveau et par longueur de partie) et les derniers réglages choisis.
abstract class Stockage {
  int lireRecord(Niveau niveau, int manches);
  Future<void> ecrireRecord(Niveau niveau, int manches, int valeur);

  Niveau? get dernierNiveau;
  int? get dernieresManches;
  Future<void> memoriserChoix(Niveau niveau, int manches);

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

  static String _cle(Niveau niveau, int manches) =>
      'balamo-record-${niveau.name}-$manches';

  @override
  int lireRecord(Niveau niveau, int manches) =>
      _prefs.getInt(_cle(niveau, manches)) ?? 0;

  @override
  Future<void> ecrireRecord(Niveau niveau, int manches, int valeur) =>
      _prefs.setInt(_cle(niveau, manches), valeur);

  @override
  Niveau? get dernierNiveau {
    final nom = _prefs.getString('balamo-niveau');
    for (final n in Niveau.values) {
      if (n.name == nom) return n;
    }
    return null;
  }

  @override
  int? get dernieresManches => _prefs.getInt('balamo-manches');

  @override
  Future<void> memoriserChoix(Niveau niveau, int manches) async {
    await _prefs.setString('balamo-niveau', niveau.name);
    await _prefs.setInt('balamo-manches', manches);
  }

  @override
  bool lireReglage(String cle, {required bool parDefaut}) =>
      _prefs.getBool('balamo-$cle') ?? parDefaut;

  @override
  Future<void> ecrireReglage(String cle, bool valeur) =>
      _prefs.setBool('balamo-$cle', valeur);
}

/// Stockage en mémoire, pour les tests (rien n'est conservé).
class StockageMemoire implements Stockage {
  final Map<String, int> _records = {};

  @override
  Niveau? dernierNiveau;

  @override
  int? dernieresManches;

  @override
  int lireRecord(Niveau niveau, int manches) =>
      _records['${niveau.name}-$manches'] ?? 0;

  @override
  Future<void> ecrireRecord(Niveau niveau, int manches, int valeur) async {
    _records['${niveau.name}-$manches'] = valeur;
  }

  @override
  Future<void> memoriserChoix(Niveau niveau, int manches) async {
    dernierNiveau = niveau;
    dernieresManches = manches;
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
