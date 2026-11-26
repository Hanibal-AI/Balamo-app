/// Les deux familles de niveaux proposées à l'accueil.
enum Categorie {
  entrainement('Entraînement'),
  competition('Compétition');

  const Categorie(this.libelle);

  final String libelle;
}

/// Les paliers de difficulté, qui regroupent les niveaux.
enum Palier {
  facile('Facile'),
  intermediaire('Intermédiaire'),
  difficile('Difficile'),
  hard('Hard');

  const Palier(this.libelle);

  final String libelle;
}

/// Les dix niveaux et leurs réglages : la « Mastergrid ».
///
/// Pour ajuster un niveau (multiplicateur, chrono, indices…), il suffit de
/// modifier les valeurs ci-dessous : toute l'application s'y adapte. Les mots
/// de chaque niveau viennent de `assets/donnees/mastergrid.json`.
enum Niveau {
  n1(1, 'Premiers pas', Categorie.entrainement, Palier.facile,
      pieges: 0, multiplicateur: 1, demandeCombien: false, prixIndice: 5),
  n2(2, 'Premiers pièges', Categorie.entrainement, Palier.facile,
      pieges: 1, multiplicateur: 1, demandeCombien: false, prixIndice: 5),
  n3(3, 'Championship I', Categorie.competition, Palier.facile,
      pieges: 1,
      multiplicateur: 1,
      demandeCombien: false,
      prixIndice: 5,
      chronoSecondes: 90),
  n4(4, 'Combien ?', Categorie.entrainement, Palier.intermediaire,
      pieges: 1, multiplicateur: 2, indicesMax: 3, prixIndice: 10),
  n5(5, "L'indice se paie", Categorie.entrainement, Palier.intermediaire,
      pieges: 1, multiplicateur: 2, indicesMax: 3, prixIndice: 20),
  n6(6, 'Championship II', Categorie.competition, Palier.intermediaire,
      pieges: 1,
      multiplicateur: 2,
      indicesMax: 3,
      prixIndice: 20,
      chronoSecondes: 90),
  n7(7, 'Grand format', Categorie.entrainement, Palier.difficile,
      pieges: 1, multiplicateur: 3, indicesMax: 2, prixIndice: 45),
  n8(8, 'Très grand format', Categorie.entrainement, Palier.difficile,
      pieges: 2, multiplicateur: 3, indicesMax: 2, prixIndice: 45),
  n9(9, 'Championship III', Categorie.competition, Palier.difficile,
      pieges: 2,
      multiplicateur: 3,
      indicesMax: 2,
      prixIndice: 45,
      chronoSecondes: 75,
      objectifPourcent: 60),
  n10(10, 'Battle royale extrême', Categorie.competition, Palier.hard,
      pieges: 2,
      multiplicateur: 5,
      indicesMax: 1,
      prixIndice: 100,
      chronoSecondes: 60,
      objectifPourcent: 60);

  const Niveau(
    this.numero,
    this.titre,
    this.categorie,
    this.palier, {
    required this.pieges,
    required this.multiplicateur,
    required this.prixIndice,
    this.demandeCombien = true,
    this.indicesMax,
    this.chronoSecondes = 0,
    this.objectifPourcent = 50,
  });

  final int numero;
  final String titre;
  final Categorie categorie;
  final Palier palier;

  /// Nombre de mots pièges (sans anagramme) dans une partie.
  final int pieges;

  /// Tous les points du barème sont multipliés par cette valeur.
  final int multiplicateur;

  /// Prix d'un indice, en points (prix final, non multiplié).
  final int prixIndice;

  /// Après un pari « oui », demande-t-on aussi le nombre d'anagrammes ?
  final bool demandeCombien;

  /// Indices autorisés par mot (`null` = toutes les lettres sauf la dernière).
  final int? indicesMax;

  /// Durée de la recherche en secondes (0 = pas de chrono).
  final int chronoSecondes;

  /// Part du score maximal à atteindre pour débloquer le niveau suivant.
  final int objectifPourcent;

  bool get aChrono => chronoSecondes > 0;

  /// Par exemple « Compétition facile ».
  String get famille => '${categorie.libelle} ${palier.libelle.toLowerCase()}';

  static Niveau depuisNumero(int numero) =>
      Niveau.values.firstWhere((n) => n.numero == numero);
}
