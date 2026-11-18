import '../logic/partie_controller.dart';

/// Ce que le jeu attend d'un moteur sonore.
///
/// L'implémentation réelle est [AudioBalamo] (`audio_balamo.dart`) ;
/// [AudioMuet] sert aux tests et de repli si le son est indisponible.
abstract class Audio {
  /// Charge les sons en mémoire. À appeler une fois, au démarrage.
  Future<void> preparer();

  /// Joue le son associé à un événement du jeu.
  void jouer(Retour retour);

  /// Active ou coupe les bruitages.
  void reglerSons({required bool actifs});

  /// Lance ou arrête la musique d'ambiance.
  void reglerMusique({required bool active});

  /// L'application passe en arrière-plan : la musique se tait.
  void suspendre();

  /// L'application revient au premier plan.
  void reprendre();

  Future<void> liberer();
}

/// Moteur sonore qui ne fait rien.
class AudioMuet implements Audio {
  /// Événements reçus, pour les tests.
  final List<Retour> joues = [];
  bool sons = true;
  bool musique = true;

  @override
  Future<void> preparer() async {}

  @override
  void jouer(Retour retour) => joues.add(retour);

  @override
  void reglerSons({required bool actifs}) => sons = actifs;

  @override
  void reglerMusique({required bool active}) => musique = active;

  @override
  void suspendre() {}

  @override
  void reprendre() {}

  @override
  Future<void> liberer() async {}
}
