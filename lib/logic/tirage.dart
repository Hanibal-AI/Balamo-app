import 'dart:math';

import '../models/donnees_jeu.dart';
import '../models/niveau.dart';
import 'regles.dart';

/// Compose la pioche d'une partie : des mots de la réserve du [niveau], tirés
/// au hasard, dont [Niveau.pieges] mots pièges (sans anagramme).
///
/// La pioche se consomme par la fin (`removeLast`).
List<EntreePartie> composerPioche({
  required List<EntreePartie> partie,
  required Niveau niveau,
  required Random hasard,
}) {
  final lot = partie.where((p) => p.niveau == niveau).toList()..shuffle(hasard);
  final pieges = lot.where((p) => p.estPiege).take(niveau.pieges).toList();
  final series = lot
      .where((p) => !p.estPiege)
      .take(Regles.motsParPartie - pieges.length);
  final pioche = [...pieges, ...series]..shuffle(hasard);

  // Réserve trop pauvre pour remplir la partie : on complète au hasard.
  while (pioche.length < Regles.motsParPartie && lot.isNotEmpty) {
    pioche.add(lot[hasard.nextInt(lot.length)]);
  }
  return pioche;
}

/// Mélange les lettres d'un mot en évitant de redonner l'ordre d'origine.
List<String> melangerLettres(String tuiles, Random hasard) {
  final lettres = tuiles.split('');
  if (lettres.toSet().length < 2) return lettres;
  do {
    lettres.shuffle(hasard);
  } while (lettres.join() == tuiles);
  return lettres;
}
