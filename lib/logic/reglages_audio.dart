import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/audio.dart';
import '../services/stockage.dart';
import 'partie_controller.dart';

/// Les deux interrupteurs sonores du joueur — bruitages et musique —,
/// mémorisés d'une session à l'autre et appliqués au moteur sonore.
class ReglagesAudio extends ChangeNotifier {
  ReglagesAudio({required Stockage stockage, required this._audio})
      : _stockage = stockage {
    _sons = stockage.lireReglage(_cleSons, parDefaut: true);
    _musique = stockage.lireReglage(_cleMusique, parDefaut: true);
    _audio
      ..reglerSons(actifs: _sons)
      ..reglerMusique(active: _musique);
  }

  /// Réglages sans son ni mémoire : pour les tests et les aperçus.
  factory ReglagesAudio.muets() =>
      ReglagesAudio(stockage: StockageMemoire(), audio: AudioMuet());

  static const _cleSons = 'sons';
  static const _cleMusique = 'musique';

  final Stockage _stockage;
  final Audio _audio;
  late bool _sons;
  late bool _musique;

  bool get sons => _sons;
  bool get musique => _musique;

  void basculerSons() {
    _sons = !_sons;
    _audio.reglerSons(actifs: _sons);
    // Un son de confirmation quand on les rallume.
    if (_sons) _audio.jouer(Retour.choix);
    unawaited(_stockage.ecrireReglage(_cleSons, _sons));
    notifyListeners();
  }

  void basculerMusique() {
    _musique = !_musique;
    _audio.reglerMusique(active: _musique);
    unawaited(_stockage.ecrireReglage(_cleMusique, _musique));
    notifyListeners();
  }
}
