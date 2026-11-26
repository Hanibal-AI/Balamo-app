import 'dart:math';

import '../models/donnees_jeu.dart';
import '../models/niveau.dart';
import 'regles.dart';

/// Compose la pioche d'une partie à partir du [lot] de mots du [niveau] :
/// [Niveau.pieges] mots pièges (sans anagramme), puis des mots à anagrammes
/// dont le degré est tiré selon [Niveau.partDegres].
///
/// La pioche se consomme par la fin (`removeLast`).
List<EntreePartie> composerPioche({
  required List<EntreePartie> lot,
  required Niveau niveau,
  required Random hasard,
}) {
  final melange = [...lot]..shuffle(hasard);
  final pioche = melange.where((p) => p.estPiege).take(niveau.pieges).toList();

  final series = <int, List<EntreePartie>>{};
  for (final mot in melange.where((p) => !p.estPiege)) {
    series.putIfAbsent(mot.degre, () => []).add(mot);
  }
  while (pioche.length < Regles.motsParPartie && series.isNotEmpty) {
    final degre = _tirerDegre(niveau, series.keys, hasard);
    pioche.add(series[degre]!.removeLast());
    if (series[degre]!.isEmpty) series.remove(degre);
  }

  // Réserve trop pauvre pour remplir la partie : on complète au hasard.
  while (pioche.length < Regles.motsParPartie && lot.isNotEmpty) {
    pioche.add(lot[hasard.nextInt(lot.length)]);
  }
  return pioche..shuffle(hasard);
}

/// Un degré parmi les [disponibles], selon sa part au [niveau].
int _tirerDegre(Niveau niveau, Iterable<int> disponibles, Random hasard) {
  int part(int degre) => niveau.partDegres[degre] ?? 1;
  var reste =
      hasard.nextInt(disponibles.fold(0, (total, d) => total + part(d)));
  return disponibles.firstWhere((d) => (reste -= part(d)) < 0);
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
