import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:balamo/logic/partie_controller.dart';
import 'package:balamo/models/donnees_jeu.dart';
import 'package:balamo/models/etat_manche.dart';
import 'package:balamo/models/mot.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/services/stockage.dart';

Map<String, dynamic> _lire(String nom) =>
    jsonDecode(File('assets/donnees/$nom.json').readAsStringSync())
        as Map<String, dynamic>;

/// Les vraies données du jeu, lues directement dans `assets/`.
DonneesJeu chargerVraiesDonnees() =>
    DonneesJeu.fromJson(_lire('balamo'), _lire('mastergrid'));

Mot _mot(String lemme) => Mot(
      lemme: lemme,
      nature: 'nom',
      definition: 'Définition de $lemme.',
      statut: 'vérifiée',
      certitude: null,
      racines: const [],
      fiche: const Fiche(enUnePhrase: '', origine: '', aRetenir: '', sources: '', etapes: []),
    );

/// Données dont tous les mots sont proposés, quel que soit le niveau : les
/// tests choisissent librement leurs mots.
class DonneesDeTest extends DonneesJeu {
  DonneesDeTest({
    required super.genere,
    required super.mots,
    required super.orthographes,
    required super.partie,
  });

  @override
  List<EntreePartie> lot(Niveau niveau) => partie;
}

/// Petit jeu de données maîtrisé : un seul mot par niveau, pour des tests
/// dont on connaît d'avance le déroulement.
DonneesJeu donneesDeTest({
  String tuiles = 'TROUPE',
  List<String> anagrammes = const ['POUTRE', 'TOUPER'],
}) =>
    DonneesDeTest(
      genere: 'test',
      mots: {'Mot': _mot(tuiles.toLowerCase())},
      orthographes: {
        for (final o in [tuiles, ...anagrammes])
          o: [Lecture(forme: o.toLowerCase(), note: 'Mot')],
      },
      partie: [
        EntreePartie(tuiles: tuiles, anagrammes: anagrammes),
      ],
    );

/// Horloge que les tests avancent à la main.
class HorlogeDeTest {
  DateTime maintenant = DateTime(2026, 1, 1, 12);

  DateTime call() => maintenant;

  void avancer(Duration duree) => maintenant = maintenant.add(duree);
}

PartieController creerPartie(
  DonneesJeu donnees, {
  Niveau niveau = Niveau.n1,
  Stockage? stockage,
  HorlogeDeTest? horloge,
}) {
  // Tous les niveaux sont ouverts : les tests choisissent librement le leur.
  final s = stockage ?? StockageMemoire(niveauDebloque: Niveau.values.length);
  return PartieController(
    donnees: donnees,
    stockage: s,
    hasard: Random(42),
    horloge: horloge?.call,
  )
    ..choisirNiveau(niveau);
}

/// Compose [mot] sur le plateau en touchant les jetons un à un.
void poser(PartieController partie, String mot) {
  partie.toutRamener();
  for (final lettre in mot.split('')) {
    final jeton = partie.chevalet.firstWhere((Jeton j) => j.lettre == lettre);
    partie.basculerJeton(jeton.id);
  }
}
