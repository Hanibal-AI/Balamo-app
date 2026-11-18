import 'dart:math';

import '../models/donnees_jeu.dart';
import '../models/niveau.dart';
import 'regles.dart';

/// Compose la pioche d'une partie : [total] mots du [niveau], tirés au hasard.
///
/// - Un seul mot par groupe d'anagrammes : sinon le second livrerait la
///   réponse du premier.
/// - Environ un mot piège (sans anagramme) sur quatre, quand le niveau en a.
///
/// La pioche se consomme par la fin (`removeLast`).
List<EntreePartie> composerPioche({
  required List<EntreePartie> partie,
  required Niveau niveau,
  required int total,
  required Random hasard,
}) {
  final vus = <String>{};
  final lot = (partie.where((p) => p.niveau == niveau).toList()..shuffle(hasard))
      .where((p) => vus.add(p.cleAnagramme))
      .toList();

  final avec = lot.where((p) => !p.estPiege).toList()..shuffle(hasard);
  final sans = lot.where((p) => p.estPiege).toList()..shuffle(hasard);

  final nbSans = min(sans.length, (total / Regles.unPiegeSur).round());
  final pioche = [...sans.take(nbSans), ...avec.take(total - nbSans)]
    ..shuffle(hasard);

  // Niveau trop pauvre pour remplir la partie : on complète au hasard.
  while (pioche.length < total && lot.isNotEmpty) {
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
