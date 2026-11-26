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
/// modifier les valeurs ci-dessous : toute l'application s'y adapte. Chaque mot
/// de `assets/donnees/mastergrid.json` est proposé aux niveaux qui l'admettent
/// (voir [Niveau.admet]). Après avoir élargi un critère, relancer
/// `dart run tool/importer_mastergrid.dart`.
enum Niveau {
  n1(1, 'Premiers pas', Categorie.entrainement, Palier.facile,
      lettresMin: 3,
      lettresMax: 5,
      partDegres: {1: 100},
      anagrammesMax: 1,
      pieges: 0, multiplicateur: 1, demandeCombien: false, prixIndice: 5),
  n2(2, 'Premiers pièges', Categorie.entrainement, Palier.facile,
      lettresMin: 3,
      lettresMax: 5,
      partDegres: {1: 10, 2: 90},
      anagrammesMax: 2,
      pieges: 1, multiplicateur: 1, demandeCombien: false, prixIndice: 5),
  n3(3, 'Championship I', Categorie.competition, Palier.facile,
      lettresMin: 3,
      lettresMax: 5,
      partDegres: {1: 2, 2: 98},
      anagrammesMax: 2,
      pieges: 1,
      multiplicateur: 1,
      demandeCombien: false,
      prixIndice: 5,
      chronoSecondes: 90),
  n4(4, 'Combien ?', Categorie.entrainement, Palier.intermediaire,
      lettresMin: 5,
      lettresMax: 6,
      partDegres: {1: 30, 2: 70},
      anagrammesMax: 3,
      pieges: 1, multiplicateur: 2, indicesMax: 3, prixIndice: 10),
  n5(5, "L'indice se paie", Categorie.entrainement, Palier.intermediaire,
      lettresMin: 5,
      lettresMax: 7,
      partDegres: {1: 10, 2: 40, 3: 50},
      anagrammesMax: 3,
      pieges: 1, multiplicateur: 2, indicesMax: 3, prixIndice: 20),
  n6(6, 'Championship II', Categorie.competition, Palier.intermediaire,
      lettresMin: 5,
      lettresMax: 7,
      partDegres: {2: 50, 3: 50},
      anagrammesMax: 3,
      pieges: 1,
      multiplicateur: 2,
      indicesMax: 3,
      prixIndice: 20,
      chronoSecondes: 90),
  n7(7, 'Grand format', Categorie.entrainement, Palier.difficile,
      lettresMin: 5,
      lettresMax: 8,
      partDegres: {3: 50, 4: 50},
      anagrammesMax: 3,
      pieges: 1, multiplicateur: 3, indicesMax: 2, prixIndice: 45),
  n8(8, 'Très grand format', Categorie.entrainement, Palier.difficile,
      lettresMin: 5,
      lettresMax: 10,
      partDegres: {3: 40, 4: 60},
      anagrammesMax: 2,
      pieges: 2, multiplicateur: 3, indicesMax: 2, prixIndice: 45),
  n9(9, 'Championship III', Categorie.competition, Palier.difficile,
      lettresMin: 5,
      lettresMax: 10,
      partDegres: {4: 70, 5: 30},
      anagrammesMax: 3,
      pieges: 2,
      multiplicateur: 3,
      indicesMax: 2,
      prixIndice: 45,
      chronoSecondes: 75,
      objectifPourcent: 60),
  n10(10, 'Battle royale extrême', Categorie.competition, Palier.hard,
      lettresMin: 8,
      lettresMax: 11,
      partDegres: {4: 60, 5: 40},
      anagrammesMax: 3,
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
    required this.lettresMin,
    required this.lettresMax,
    required this.partDegres,
    required this.anagrammesMax,
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

  final int lettresMin;
  final int lettresMax;

  /// Degrés de mots admis (1 = C1 … 5 = C5) et part de chacun, en pourcentage,
  /// dans le tirage des mots à anagrammes. Reproduit le degré moyen de la
  /// Mastergrid.
  final Map<int, int> partDegres;

  /// Nombre maximal d'anagrammes à trouver pour un mot.
  final int anagrammesMax;

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

  /// Un mot de [lettres] lettres, de degré [degre], avec [anagrammes] réponses
  /// (0 = piège) peut-il être proposé à ce niveau ?
  bool admet({required int lettres, required int degre, required int anagrammes}) =>
      lettres >= lettresMin &&
      lettres <= lettresMax &&
      partDegres.containsKey(degre) &&
      (anagrammes == 0 ? pieges > 0 : anagrammes <= anagrammesMax);

  static Niveau depuisNumero(int numero) =>
      Niveau.values.firstWhere((n) => n.numero == numero);
}
