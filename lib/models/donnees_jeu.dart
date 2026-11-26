import 'mot.dart';
import 'niveau.dart';

/// Un mot proposé en jeu : ses jetons et les anagrammes à retrouver.
class EntreePartie {
  const EntreePartie({
    required this.tuiles,
    required this.anagrammes,
    required this.niveau,
    this.formes = const {},
  });

  /// Les lettres du mot, en capitales sans accents (ex. « TROUPE »).
  final String tuiles;

  /// Anagrammes acceptées (vide = mot piège).
  final List<String> anagrammes;

  final Niveau niveau;

  /// Orthographe accentuée du mot et de ses anagrammes, par jeu de jetons.
  final Map<String, String> formes;

  bool get estPiege => anagrammes.isEmpty;

  /// Le mot tel qu'on l'écrit (ex. « déjà » pour les jetons « DEJA »).
  String get forme => formes[tuiles] ?? tuiles.toLowerCase();

  /// Deux mots de même clé sont anagrammes l'un de l'autre.
  String get cleAnagramme => (tuiles.split('')..sort()).join();

  factory EntreePartie.fromJson(Map<String, dynamic> j) => EntreePartie(
        tuiles: j['tuiles'] as String,
        anagrammes: (j['anagrammes'] as List).cast<String>(),
        niveau: Niveau.depuisNumero(j['niveau'] as int),
        formes: (j['formes'] as Map<String, dynamic>).cast<String, String>(),
      );
}

/// Une lecture possible d'une orthographe : la forme accentuée et son mot.
class Lecture {
  const Lecture({required this.forme, required this.note});

  final String forme;
  final String note;

  factory Lecture.fromJson(Map<String, dynamic> j) => Lecture(
        forme: (j['forme'] ?? '') as String,
        note: (j['note'] ?? '') as String,
      );
}

/// Un sens affiché dans la révélation : titre, rattachement et entrée.
class SensRevele {
  const SensRevele({required this.titre, required this.formeDe, required this.mot});

  /// Forme affichée en titre (forme conjuguée/accordée, sinon le lemme).
  final String titre;

  /// Lemme de rattachement quand le titre est une forme fléchie, sinon `null`.
  final String? formeDe;

  final Mot mot;
}

/// Toutes les données du jeu : le dictionnaire (`assets/donnees/balamo.json`)
/// et les mots des dix niveaux (`assets/donnees/mastergrid.json`).
class DonneesJeu {
  const DonneesJeu({
    required this.genere,
    required this.mots,
    required this.orthographes,
    required this.partie,
  });

  /// Date de génération du fichier de données.
  final String genere;

  /// Entrées de dictionnaire, par clé de note.
  final Map<String, Mot> mots;

  /// Lectures possibles de chaque orthographe en capitales.
  final Map<String, List<Lecture>> orthographes;

  /// Les mots jouables.
  final List<EntreePartie> partie;

  /// L'entrée de dictionnaire du mot proposé, s'il en a une.
  Mot? motDe(EntreePartie entree) {
    for (final sens in sensDe(entree.tuiles)) {
      return sens.mot;
    }
    return null;
  }

  /// Orthographe accentuée d'un jeu de jetons.
  String formeDe(String orthographe) {
    for (final entree in partie) {
      final forme = entree.formes[orthographe];
      if (forme != null) return forme;
    }
    return orthographe.toLowerCase();
  }

  List<EntreePartie> lot(Niveau niveau) =>
      partie.where((p) => p.niveau == niveau).toList();

  /// Les sens à afficher pour une orthographe (un par mot du dictionnaire).
  List<SensRevele> sensDe(String orthographe) {
    final lectures = orthographes[orthographe] ?? const <Lecture>[];
    final vues = <String>{};
    final sens = <SensRevele>[];
    for (final lecture in lectures) {
      if (!vues.add(lecture.note)) continue;
      final mot = mots[lecture.note];
      if (mot == null) continue;
      final formes = lectures
          .where((l) => l.note == lecture.note)
          .map((l) => l.forme)
          .where((f) => f != mot.lemme);
      final forme = formes.isEmpty ? null : formes.first;
      sens.add(SensRevele(
        titre: forme ?? mot.lemme,
        formeDe: forme == null ? null : mot.lemme,
        mot: mot,
      ));
    }
    return sens;
  }

  factory DonneesJeu.fromJson(
    Map<String, dynamic> j,
    Map<String, dynamic> grille,
  ) =>
      DonneesJeu(
        genere: (j['genere'] ?? '') as String,
        mots: (j['mots'] as Map<String, dynamic>).map(
          (cle, v) => MapEntry(cle, Mot.fromJson(v as Map<String, dynamic>)),
        ),
        orthographes: (j['orthographes'] as Map<String, dynamic>).map(
          (cle, v) => MapEntry(
            cle,
            (v as List)
                .map((l) => Lecture.fromJson(l as Map<String, dynamic>))
                .toList(growable: false),
          ),
        ),
        partie: (grille['mots'] as List)
            .map((p) => EntreePartie.fromJson(p as Map<String, dynamic>))
            .toList(growable: false),
      );
}
