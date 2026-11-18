import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:balamo/logic/partie_controller.dart';
import 'package:balamo/models/donnees_jeu.dart';
import 'package:balamo/models/etat_manche.dart';
import 'package:balamo/models/mot.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/services/stockage.dart';

/// Les vraies données du jeu, lues directement dans `assets/`.
DonneesJeu chargerVraiesDonnees() => DonneesJeu.fromJson(
      jsonDecode(File('assets/donnees/balamo.json').readAsStringSync())
          as Map<String, dynamic>,
    );

Mot _mot(String lemme) => Mot(
      lemme: lemme,
      nature: 'nom',
      definition: 'Définition de $lemme.',
      statut: 'vérifiée',
      certitude: null,
      racines: const [],
      fiche: const Fiche(enUnePhrase: '', origine: '', aRetenir: '', sources: '', etapes: []),
    );

/// Petit jeu de données maîtrisé : un seul mot par niveau, pour des tests
/// dont on connaît d'avance le déroulement.
DonneesJeu donneesDeTest({
  String tuiles = 'TROUPE',
  List<String> anagrammes = const ['POUTRE', 'TOUPER'],
  Niveau niveau = Niveau.facile,
}) =>
    DonneesJeu(
      genere: 'test',
      mots: {'Mot': _mot(tuiles.toLowerCase())},
      orthographes: {
        for (final o in [tuiles, ...anagrammes])
          o: [Lecture(forme: o.toLowerCase(), note: 'Mot')],
      },
      partie: [
        EntreePartie(note: 'Mot', tuiles: tuiles, anagrammes: anagrammes, niveau: niveau),
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
  Niveau niveau = Niveau.facile,
  int manches = 5,
  Stockage? stockage,
  HorlogeDeTest? horloge,
}) {
  final s = stockage ?? StockageMemoire();
  return PartieController(
    donnees: donnees,
    stockage: s,
    hasard: Random(42),
    horloge: horloge?.call,
  )
    ..choisirNiveau(niveau)
    ..choisirTotalManches(manches);
}

/// Compose [mot] sur le plateau en touchant les jetons un à un.
void poser(PartieController partie, String mot) {
  partie.toutRamener();
  for (final lettre in mot.split('')) {
    final jeton = partie.chevalet.firstWhere((Jeton j) => j.lettre == lettre);
    partie.basculerJeton(jeton.id);
  }
}
