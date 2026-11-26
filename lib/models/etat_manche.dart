/// Petits types décrivant l'état d'une partie en cours.
library;

/// Écran affiché.
enum Vue { accueil, jeu, bilan }

/// Les trois temps d'une manche.
enum Phase { pari, recherche, terminee }

/// Où se trouve un jeton.
enum Zone { plateau, chevalet }

/// Aspect du plateau après un coup.
enum EtatPlateau { neutre, gagne, refuse }

/// Couleur du message affiché sous le plateau.
enum TonMessage { neutre, ok, non }

/// Un jeton de lettre. L'identifiant distingue deux jetons de même lettre.
class Jeton {
  const Jeton({required this.id, required this.lettre});

  final int id;
  final String lettre;
}

/// Résultat du pari, affiché en tête de la recherche.
class Verdict {
  const Verdict({required this.juste, required this.texte});

  final bool juste;

  /// Texte en mini-markdown (`**gras**` pour les points gagnés).
  final String texte;
}

/// Ligne du journal de partie : ce qui s'est passé pendant une manche.
class BilanManche {
  BilanManche({
    required this.lemme,
    required this.tuiles,
    required this.total,
  });

  final String lemme;
  final String tuiles;

  /// Nombre d'anagrammes à trouver (0 = piège).
  final int total;

  /// Le pari était-il juste ? (`null` tant qu'il n'est pas validé.)
  bool? pariJuste;

  int trouvees = 0;

  /// Nombre d'indices demandés pendant la manche.
  int indices = 0;

  /// Points de la manche, indices déduits (peut être négatif).
  int points = 0;

  /// Temps de recherche, mesuré dans les niveaux de compétition (`null` en
  /// entraînement et sur un mot piège).
  Duration? duree;
}
