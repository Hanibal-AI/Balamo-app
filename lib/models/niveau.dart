/// Les trois niveaux de difficulté et leurs réglages.
///
/// Pour ajuster un niveau (multiplicateur, chrono, indice…), il suffit de
/// modifier les valeurs ci-dessous : toute l'application s'y adapte.
enum Niveau {
  facile(
    cle: 'facile',
    libelle: 'Facile',
    multiplicateur: 1,
    demandeCombien: false,
    indiceDisponible: true,
    chronoSecondes: 0,
  ),
  intermediaire(
    cle: 'intermédiaire',
    libelle: 'Intermédiaire',
    multiplicateur: 2,
    demandeCombien: true,
    indiceDisponible: true,
    chronoSecondes: 0,
  ),
  expert(
    cle: 'expert',
    libelle: 'Expert',
    multiplicateur: 3,
    demandeCombien: true,
    indiceDisponible: true,
    chronoSecondes: 90,
  );

  const Niveau({
    required this.cle,
    required this.libelle,
    required this.multiplicateur,
    required this.demandeCombien,
    required this.indiceDisponible,
    required this.chronoSecondes,
  });

  /// Identifiant utilisé dans le fichier de données (`"niveau": "facile"`).
  final String cle;

  /// Nom affiché à l'écran.
  final String libelle;

  /// Tous les points du barème sont multipliés par cette valeur.
  final int multiplicateur;

  /// Après un pari « oui », demande-t-on aussi le nombre d'anagrammes ?
  final bool demandeCombien;

  /// Le bouton « Indice » est-il proposé pendant la recherche ?
  final bool indiceDisponible;

  /// Durée de la recherche en secondes (0 = pas de chrono).
  final int chronoSecondes;

  bool get aChrono => chronoSecondes > 0;

  static Niveau depuisCle(String cle) => Niveau.values.firstWhere(
        (n) => n.cle == cle,
        orElse: () => Niveau.facile,
      );
}
