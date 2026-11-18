import 'mot.dart';
import 'niveau.dart';

/// Un mot proposé en jeu : ses jetons et les anagrammes à retrouver.
class EntreePartie {
  const EntreePartie({
    required this.note,
    required this.tuiles,
    required this.anagrammes,
    required this.niveau,
  });

  /// Clé de l'entrée de dictionnaire correspondante ([DonneesJeu.mots]).
  final String note;

  /// Les lettres du mot, en capitales sans accents (ex. « TROUPE »).
  final String tuiles;

  /// Anagrammes acceptées (vide = mot piège).
  final List<String> anagrammes;

  final Niveau niveau;

  bool get estPiege => anagrammes.isEmpty;

  /// Deux mots de même clé sont anagrammes l'un de l'autre.
  String get cleAnagramme => (tuiles.split('')..sort()).join();

  factory EntreePartie.fromJson(Map<String, dynamic> j) => EntreePartie(
        note: j['note'] as String,
        tuiles: j['tuiles'] as String,
        anagrammes: (j['anagrammes'] as List).cast<String>(),
        niveau: Niveau.depuisCle(j['niveau'] as String),
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

/// Toutes les données du jeu, chargées depuis `assets/donnees/balamo.json`.
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

  Mot? motDe(EntreePartie entree) => mots[entree.note];

  List<EntreePartie> lot(Niveau niveau) =>
      partie.where((p) => p.niveau == niveau).toList();

  int nombreDeMots(Niveau niveau) => lot(niveau).length;

  int nombreDePieges(Niveau niveau) =>
      lot(niveau).where((p) => p.estPiege).length;

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

  factory DonneesJeu.fromJson(Map<String, dynamic> j) => DonneesJeu(
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
        partie: (j['partie'] as List)
            .map((p) => EntreePartie.fromJson(p as Map<String, dynamic>))
            .toList(growable: false),
      );
}
