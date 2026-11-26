/// Règles chiffrées du jeu : barème, coût des indices, valeur des jetons.
///
/// C'est LE fichier à modifier pour rééquilibrer le jeu. Tous les points sont
/// des valeurs « de base », multipliées par le multiplicateur du niveau. Ce qui
/// change d'un niveau à l'autre (indices, chrono, pièges…) est réglé dans
/// `lib/models/niveau.dart`.
abstract final class Regles {
  /// Bon pari « oui » sur un mot qui a des anagrammes.
  static const int pointsBonPari = 10;

  /// Bon pari « non » sur un mot piège (sans anagramme).
  static const int pointsBonPiege = 30;

  /// Bon nombre d'anagrammes (niveaux qui posent la question « Combien ? »).
  static const int pointsBonNombre = 20;

  /// Chaque anagramme trouvée.
  static const int pointsAnagramme = 15;

  /// Bonus quand toutes les anagrammes du mot sont trouvées.
  static const int pointsToutesTrouvees = 10;

  /// Choix proposés à la question « Combien ? ». Le dernier vaut « ou plus ».
  static const int nombreMax = 6;

  /// Nombre de mots (donc de manches) d'une partie.
  static const int motsParPartie = 5;

  /// Délai avant que les jetons d'un mot trouvé retournent au chevalet.
  static const Duration delaiRetourJetons = Duration(milliseconds: 900);

  /// En dessous de ce nombre de secondes, le chrono passe en rouge.
  static const int secondesUrgence = 15;

  /// Nombre de dernières secondes marquées par un « tic » sonore.
  static const int secondesTic = 10;

  /// Valeur inscrite sur chaque jeton (décorative, comme au Scrabble).
  static const Map<String, int> valeursLettres = {
    'A': 1, 'B': 3, 'C': 3, 'D': 2, 'E': 1, 'F': 4, 'G': 2, 'H': 4, 'I': 1,
    'J': 8, 'K': 10, 'L': 1, 'M': 2, 'N': 1, 'O': 1, 'P': 3, 'Q': 8, 'R': 1,
    'S': 1, 'T': 1, 'U': 1, 'V': 4, 'W': 10, 'X': 10, 'Y': 10, 'Z': 10,
  };

  /// Meilleur score possible, sans indice, sur un mot à [anagrammes] réponses
  /// (0 = piège), avant multiplicateur.
  static int pointsMaximum(int anagrammes, {required bool demandeCombien}) =>
      anagrammes == 0
          ? pointsBonPiege
          : pointsBonPari +
              (demandeCombien ? pointsBonNombre : 0) +
              anagrammes * pointsAnagramme +
              pointsToutesTrouvees;

  /// Le nombre parié correspond-il au nombre réel d'anagrammes ?
  static bool nombreJuste(int? parie, int reel) =>
      parie != null &&
      (parie == reel || (parie == nombreMax && reel >= nombreMax));
}
