import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../logic/partie_controller.dart';
import 'audio.dart';

/// Un bruitage : un ou plusieurs fichiers interchangeables, et son volume.
///
/// Quand il y a plusieurs variantes, on en tire une au hasard — jamais deux
/// fois la même de suite — pour qu'un geste répété cent fois (poser un jeton)
/// ne sonne pas comme une machine.
class _Bruitage {
  const _Bruitage(this.fichiers, {this.volume = 1.0});

  final List<String> fichiers;
  final double volume;
}

/// QUEL SON POUR QUELLE ACTION : c'est ici que ça se règle.
///
/// Les fichiers sont dans `assets/sons/` ; ils sont fabriqués par
/// `tool/generer_sons.py` (pour changer un timbre, c'est là-bas).
const Map<Retour, _Bruitage> _bruitages = {
  Retour.choix: _Bruitage(['choix'], volume: 0.7),
  Retour.bouton: _Bruitage(['bouton'], volume: 0.6),
  Retour.debutDePartie: _Bruitage(['debut'], volume: 0.8),
  Retour.pariJuste: _Bruitage(['pari_juste'], volume: 0.85),
  Retour.pariRate: _Bruitage(['pari_rate'], volume: 0.75),
  Retour.jetonSaisi: _Bruitage(['saisie'], volume: 0.8),
  Retour.jetonPose: _Bruitage(
    ['pose_1', 'pose_2', 'pose_3', 'pose_4', 'pose_5'],
    volume: 0.8,
  ),
  Retour.jetonRepris: _Bruitage(['retour_1', 'retour_2', 'retour_3'], volume: 0.8),
  Retour.melange: _Bruitage(['melanger'], volume: 0.8),
  Retour.toutRamene: _Bruitage(['ramener'], volume: 0.8),
  Retour.indice: _Bruitage(['indice'], volume: 0.8),
  Retour.indiceRefuse: _Bruitage(['indice_refuse'], volume: 0.7),
  Retour.motTrouve: _Bruitage(['mot_trouve'], volume: 0.9),
  Retour.toutesTrouvees: _Bruitage(['toutes_trouvees'], volume: 0.95),
  Retour.motRefuse: _Bruitage(['mot_refuse'], volume: 0.75),
  Retour.motNeutre: _Bruitage(['mot_neutre'], volume: 0.7),
  Retour.tic: _Bruitage(['tic'], volume: 0.8),
  Retour.tempsEcoule: _Bruitage(['temps_ecoule'], volume: 0.85),
  Retour.reponses: _Bruitage(['reponses'], volume: 0.75),
  Retour.motSuivant: _Bruitage(['suivant'], volume: 0.75),
  Retour.bilan: _Bruitage(['bilan'], volume: 0.85),
  Retour.nouveauRecord: _Bruitage(['record'], volume: 0.95),
  Retour.quitter: _Bruitage(['quitter'], volume: 0.7),
};

/// Le moteur sonore de Balamo (paquet `audioplayers`, Android et iOS).
///
/// - Les bruitages sont préchargés et joués en mode « faible latence » : le
///   son part au moment où le doigt touche le jeton.
/// - La musique tourne en boucle, en fond, à volume réduit.
/// - Le jeu ne confisque pas le son du téléphone : si un podcast ou une
///   musique jouent déjà, ils continuent.
/// - Une panne de son ne doit jamais gêner la partie : toutes les erreurs
///   sont absorbées.
class AudioBalamo implements Audio {
  AudioBalamo({Random? hasard}) : _hasard = hasard ?? Random();

  /// Volume de la musique d'ambiance (0 à 1). C'est un fond, pas un concert.
  static const double volumeMusique = 0.55;

  final Random _hasard;
  final Map<String, AudioPlayer> _lecteurs = {};
  final Map<Retour, String> _derniereVariante = {};
  AudioPlayer? _musique;

  bool _pret = false;
  bool _sons = true;
  bool _musiqueVoulue = true;
  bool _enArrierePlan = false;
  bool _musiqueEnCours = false;

  @override
  Future<void> preparer() async {
    await _sansEchec(() async {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
    });

    // La musique d'abord : c'est elle qu'on entend en arrivant sur l'accueil.
    await _sansEchec(() async {
      final lecteur = AudioPlayer(playerId: 'balamo-musique');
      await lecteur.setReleaseMode(ReleaseMode.loop);
      await lecteur.setVolume(volumeMusique);
      await lecteur.setSource(AssetSource('sons/musique.m4a'));
      _musique = lecteur;
    });
    _pret = true;
    _accorderMusique();

    for (final bruitage in _bruitages.values) {
      for (final fichier in bruitage.fichiers) {
        await _sansEchec(() async {
          final lecteur = AudioPlayer(playerId: 'balamo-$fichier');
          await lecteur.setPlayerMode(PlayerMode.lowLatency);
          await lecteur.setReleaseMode(ReleaseMode.stop);
          await lecteur.setVolume(bruitage.volume);
          await lecteur.setSource(AssetSource('sons/$fichier.wav'));
          _lecteurs[fichier] = lecteur;
        });
      }
    }
  }

  @override
  void jouer(Retour retour) {
    if (!_sons || _enArrierePlan) return;
    final bruitage = _bruitages[retour];
    if (bruitage == null) return;

    var fichier = bruitage.fichiers.first;
    if (bruitage.fichiers.length > 1) {
      final autres = bruitage.fichiers
          .where((f) => f != _derniereVariante[retour])
          .toList();
      fichier = autres[_hasard.nextInt(autres.length)];
      _derniereVariante[retour] = fichier;
    }

    final lecteur = _lecteurs[fichier];
    if (lecteur == null) return; // pas encore chargé
    unawaited(_sansEchec(() async {
      // En faible latence, il faut arrêter le son précédent pour le rejouer.
      await lecteur.stop();
      await lecteur.resume();
    }));
  }

  @override
  void reglerSons({required bool actifs}) => _sons = actifs;

  @override
  void reglerMusique({required bool active}) {
    _musiqueVoulue = active;
    _accorderMusique();
  }

  @override
  void suspendre() {
    _enArrierePlan = true;
    _accorderMusique();
  }

  @override
  void reprendre() {
    _enArrierePlan = false;
    _accorderMusique();
  }

  /// Met la musique dans l'état voulu : elle joue si elle est activée et que
  /// l'application est à l'écran.
  void _accorderMusique() {
    final lecteur = _musique;
    if (!_pret || lecteur == null) return;
    final doitJouer = _musiqueVoulue && !_enArrierePlan;
    if (doitJouer == _musiqueEnCours) return;
    _musiqueEnCours = doitJouer;
    unawaited(_sansEchec(() => doitJouer ? lecteur.resume() : lecteur.pause()));
  }

  @override
  Future<void> liberer() async {
    final lecteurs = [..._lecteurs.values, ?_musique];
    _lecteurs.clear();
    _musique = null;
    _pret = false;
    for (final lecteur in lecteurs) {
      await _sansEchec(lecteur.dispose);
    }
  }

  Future<void> _sansEchec(Future<void> Function() action) async {
    try {
      await action();
    } catch (erreur) {
      debugPrint('Audio indisponible : $erreur');
    }
  }
}
