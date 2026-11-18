import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'logic/partie_controller.dart';
import 'logic/reglages_audio.dart';
import 'services/audio.dart';
import 'services/audio_balamo.dart';
import 'services/depot_donnees.dart';
import 'services/stockage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Balamo se joue à une main, téléphone tenu droit : portrait uniquement.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const Demarrage());
}

/// Charge les données, les records et les sons, puis lance l'application.
class Demarrage extends StatefulWidget {
  const Demarrage({super.key});

  @override
  State<Demarrage> createState() => _DemarrageState();
}

class _DemarrageState extends State<Demarrage> with WidgetsBindingObserver {
  final Audio _audio = AudioBalamo();
  PartieController? _partie;
  ReglagesAudio? _reglagesAudio;
  Object? _erreur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final donnees = await DepotDonnees.charger();
      final stockage = await StockagePreferences.ouvrir();
      final reglages = ReglagesAudio(stockage: stockage, audio: _audio);
      final partie = PartieController(donnees: donnees, stockage: stockage)
        ..surRetour = _signaler;
      if (!mounted) {
        partie.dispose();
        reglages.dispose();
        return;
      }
      setState(() {
        _partie = partie;
        _reglagesAudio = reglages;
      });
      // Les sons se chargent pendant que l'accueil s'affiche.
      unawaited(_audio.preparer());
    } catch (e) {
      if (mounted) setState(() => _erreur = e);
    }
  }

  /// Chaque événement du jeu s'entend et se sent sous le doigt.
  void _signaler(Retour retour) {
    _audio.jouer(retour);
    _vibrer(retour);
  }

  /// La vibration qui accompagne chaque événement (aucune pour les plus
  /// discrets : le tic du chrono, un jeton qu'on soulève…).
  static void _vibrer(Retour retour) {
    switch (retour) {
      case Retour.choix:
      case Retour.jetonPose:
      case Retour.jetonRepris:
      case Retour.melange:
      case Retour.toutRamene:
      case Retour.indice:
        HapticFeedback.selectionClick();
      case Retour.pariJuste:
      case Retour.motTrouve:
        HapticFeedback.mediumImpact();
      case Retour.pariRate:
      case Retour.motRefuse:
      case Retour.indiceRefuse:
        HapticFeedback.heavyImpact();
      case Retour.toutesTrouvees:
      case Retour.tempsEcoule:
      case Retour.nouveauRecord:
        HapticFeedback.vibrate();
      case Retour.bouton:
      case Retour.debutDePartie:
      case Retour.jetonSaisi:
      case Retour.motNeutre:
      case Retour.tic:
      case Retour.reponses:
      case Retour.motSuivant:
      case Retour.bilan:
      case Retour.quitter:
        break;
    }
  }

  /// La musique s'arrête quand on quitte l'application, et reprend au retour.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audio.reprendre();
    } else {
      _audio.suspendre();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _partie?.dispose();
    _reglagesAudio?.dispose();
    unawaited(_audio.liberer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partie = _partie;
    if (partie == null) {
      return EcranDemarrage(erreur: _erreur, onReessayer: _charger);
    }
    return BalamoApp(partie: partie, reglagesAudio: _reglagesAudio);
  }
}
