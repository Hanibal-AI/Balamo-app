import 'package:balamo/logic/partie_controller.dart';
import 'package:balamo/logic/regles.dart';
import 'package:balamo/models/etat_manche.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/services/stockage.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aides.dart';

void main() {
  group('Le pari', () {
    test('bon « oui » en facile : +10, la recherche commence', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      expect(partie.vue, Vue.jeu);
      expect(partie.phase, Phase.pari);
      expect(partie.pariValidable, isFalse);

      partie.choisirPari(true);
      expect(partie.demandeCombien, isFalse, reason: 'pas de « combien » en facile');
      expect(partie.pariValidable, isTrue);
      partie.validerPari();

      expect(partie.score, 10);
      expect(partie.verdict!.juste, isTrue);
      expect(partie.phase, Phase.recherche);
      expect(partie.chevalet.map((j) => j.lettre).toList()..sort(),
          'TROUPE'.split('')..sort());
      expect(partie.chevalet.map((j) => j.lettre).join(), isNot('TROUPE'),
          reason: 'les jetons ne sont pas distribués dans l\'ordre du mot');
      expect(partie.plateau, isEmpty);
    });

    test('mauvais pari : aucun point, mais on cherche quand même', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(false)
        ..validerPari();
      expect(partie.score, 0);
      expect(partie.verdict!.juste, isFalse);
      expect(partie.verdict!.texte, contains('2 anagrammes'));
      expect(partie.phase, Phase.recherche);
    });

    test('bon « non » sur un piège : +30 et révélation immédiate', () {
      final partie = creerPartie(donneesDeTest(anagrammes: const []))..commencerPartie();
      partie
        ..choisirPari(false)
        ..validerPari();
      expect(partie.score, 30);
      expect(partie.phase, Phase.terminee);
      expect(partie.orthographeRevelee, 'TROUPE');
      expect(partie.revelationPiege, isTrue);
      expect(partie.journal.single.pariJuste, isTrue);
    });

    test('intermédiaire : il faut dire combien ; le bon nombre rapporte +20, le tout ×2', () {
      final partie = creerPartie(
        donneesDeTest(),
        niveau: Niveau.n4,
      )..commencerPartie();
      partie.choisirPari(true);
      expect(partie.demandeCombien, isTrue);
      expect(partie.pariValidable, isFalse);
      partie
        ..choisirNombre(2)
        ..validerPari();
      expect(partie.score, (10 + 20) * 2);
    });

    test('un mauvais nombre ne rapporte que le pari', () {
      final partie = creerPartie(
        donneesDeTest(),
        niveau: Niveau.n4,
      )..commencerPartie();
      partie
        ..choisirPari(true)
        ..choisirNombre(3)
        ..validerPari();
      expect(partie.score, 10 * 2);
    });

    test('« 6+ » vaut pour six anagrammes ou plus', () {
      expect(Regles.nombreJuste(6, 6), isTrue);
      expect(Regles.nombreJuste(6, 9), isTrue);
      expect(Regles.nombreJuste(5, 6), isFalse);
      expect(Regles.nombreJuste(null, 1), isFalse);
    });
  });

  group('La recherche', () {
    test('une anagramme trouvée : +15, le mot est révélé, les jetons reviennent', () {
      fakeAsync((async) {
        final partie = creerPartie(donneesDeTest())..commencerPartie();
        partie
          ..choisirPari(true)
          ..validerPari();
        poser(partie, 'POUTRE');

        expect(partie.score, 10 + 15);
        expect(partie.trouvees, ['POUTRE']);
        expect(partie.etatPlateau, EtatPlateau.gagne);
        expect(partie.ton, TonMessage.ok);
        expect(partie.orthographeRevelee, 'POUTRE');
        expect(partie.phase, Phase.recherche, reason: 'il en reste une à trouver');

        async.elapse(Regles.delaiRetourJetons);
        expect(partie.plateau, isEmpty);
        expect(partie.chevalet, hasLength(6));
        expect(partie.etatPlateau, EtatPlateau.neutre);
      });
    });

    test('toutes trouvées : bonus +10 et fin de la manche', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      poser(partie, 'POUTRE');
      poser(partie, 'TOUPER');

      expect(partie.score, 10 + 15 + 15 + 10);
      expect(partie.phase, Phase.terminee);
      expect(partie.message, contains('Toutes trouvées'));
      expect(partie.journal.single.trouvees, 2);
      expect(partie.journal.single.points, 50);
    });

    test('le mot de départ, une redite et un mot inconnu ne rapportent rien', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();

      poser(partie, 'TROUPE');
      expect(partie.message, contains('mot de départ'));
      expect(partie.score, 10);

      poser(partie, 'EPORTU');
      expect(partie.etatPlateau, EtatPlateau.refuse);
      expect(partie.ton, TonMessage.non);
      expect(partie.refus, 1);
      expect(partie.score, 10);

      poser(partie, 'POUTRE');
      poser(partie, 'POUTRE');
      expect(partie.message, contains('déjà trouvée'));
      expect(partie.score, 25);
    });

    test('un plateau incomplet efface le message', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      poser(partie, 'EPORTU');
      expect(partie.message, isNotEmpty);
      partie.basculerJeton(partie.plateau.last.id);
      expect(partie.message, isEmpty);
      expect(partie.etatPlateau, EtatPlateau.neutre);
    });

    test('glisser un jeton le place où l\'on veut, sans valider avant de le lâcher', () {
      final partie = creerPartie(donneesDeTest(tuiles: 'CHIEN', anagrammes: const ['NICHE', 'CHINE']))
        ..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      Jeton jeton(String l) => [...partie.plateau, ...partie.chevalet].firstWhere((j) => j.lettre == l);

      // On compose N-I-C-H-E en glissant chaque jeton en tête du plateau, à l'envers.
      for (final lettre in 'EHCIN'.split('')) {
        partie.deplacerJeton(jeton(lettre).id, Zone.plateau, 0);
      }
      expect(partie.motPose, 'NICHE');
      expect(partie.trouvees, isEmpty, reason: 'rien n\'est validé pendant le glisser');

      partie.relacherJeton(jeton('N').id);
      expect(partie.trouvees, ['NICHE']);

      // Réordonner au sein du plateau : N passe à la fin.
      partie.deplacerJeton(jeton('N').id, Zone.plateau, 4);
      expect(partie.motPose, 'ICHEN');
      // Et retour au chevalet, en première place.
      partie.deplacerJeton(jeton('N').id, Zone.chevalet, 0);
      expect(partie.motPose, 'ICHE');
      expect(partie.chevalet.first.lettre, 'N');
    });

    test('« voir les réponses » termine la manche et révèle une anagramme manquée', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      poser(partie, 'POUTRE');
      partie.abandonner();

      expect(partie.phase, Phase.terminee);
      expect(partie.orthographeRevelee, 'TOUPER');
      expect(partie.score, 25, reason: 'pas de bonus, rien pour le mot manqué');
      expect(partie.masque('TOUPER'), 'TOUPER', reason: 'tout est dévoilé');
    });
  });

  group('Les indices', () {
    test('un indice dévoile une lettre et coûte 5 points', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      expect(partie.indicePropose, isTrue);
      expect(partie.masque('POUTRE'), '······');

      partie.demanderIndice();
      expect(partie.masque('POUTRE'), 'P·····');
      expect(partie.masque('TOUPER'), 'T·····');
      expect(partie.score, 10 - Niveau.n1.prixIndice);
      expect(partie.journal.single.indices, 1);
      expect(partie.journal.single.points, 5);
      expect(partie.message, contains('−5'));
    });

    test('sans assez de points, pas d\'indice', () {
      final partie = creerPartie(donneesDeTest())..commencerPartie();
      partie
        ..choisirPari(false) // mauvais pari : 0 point
        ..validerPari();
      expect(partie.indiceAbordable, isFalse);

      partie.demanderIndice();
      expect(partie.indices, 0);
      expect(partie.score, 0);
      expect(partie.masque('POUTRE'), '······');
      expect(partie.ton, TonMessage.non);
    });

    test('la dernière lettre n\'est jamais offerte', () {
      final partie = creerPartie(donneesDeTest(tuiles: 'SEL', anagrammes: const ['LES']))
        ..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      partie
        ..demanderIndice()
        ..demanderIndice();
      expect(partie.masque('LES'), 'LE·');
      expect(partie.indicesEpuises, isTrue);
      expect(partie.score, 0);

      partie.demanderIndice();
      expect(partie.indices, 2);
    });

    test('le score baisse, mais le record garde le meilleur score atteint', () {
      final stockage = StockageMemoire();
      final partie = creerPartie(donneesDeTest(), stockage: stockage)..commencerPartie();
      partie
        ..choisirPari(true)
        ..validerPari();
      poser(partie, 'POUTRE'); // 25 points
      partie.demanderIndice(); // 20 points
      expect(partie.score, 20);
      expect(partie.record, 25);
      expect(stockage.lireRecord(Niveau.n1), 25);
    });

    test('le prix et le nombre d\'indices suivent le niveau', () {
      for (final niveau in [Niveau.n4, Niveau.n5, Niveau.n10]) {
        final partie = creerPartie(
          donneesDeTest(anagrammes: const ['POUTRE']),
          niveau: niveau,
        )..commencerPartie();
        partie
          ..choisirPari(true)
          ..choisirNombre(1)
          ..validerPari();
        expect(partie.coutIndice, niveau.prixIndice);
        final score = partie.score;

        for (var i = 0; i < 5; i++) {
          partie.demanderIndice();
        }
        final achetes = [niveau.indicesMax!, score ~/ niveau.prixIndice]
            .reduce((a, b) => a < b ? a : b);
        expect(partie.indices, achetes, reason: '${niveau.numero}');
        expect(partie.score, score - achetes * niveau.prixIndice);
        partie.dispose();
      }
    });
  });

  group('Le chrono (compétition)', () {
    test('90 secondes, puis la manche s\'arrête toute seule', () {
      fakeAsync((async) {
        final horloge = HorlogeDeTest();
        final partie = creerPartie(
          donneesDeTest(),
          niveau: Niveau.n3,
          horloge: horloge,
        )..commencerPartie();
        expect(partie.secondesRestantes, isNull, reason: 'pas de chrono pendant le pari');
        partie
          ..choisirPari(true)
          ..validerPari();
        expect(partie.secondesRestantes, 90);
        expect(partie.chronoUrgent, isFalse);

        void attendre(Duration d) {
          horloge.avancer(d);
          async.elapse(d);
        }

        attendre(const Duration(seconds: 80));
        expect(partie.secondesRestantes, 10);
        expect(partie.chronoUrgent, isTrue);
        expect(partie.phase, Phase.recherche);

        attendre(const Duration(seconds: 11));
        expect(partie.phase, Phase.terminee);
        expect(partie.message, startsWith('Temps écoulé.'));
        expect(partie.secondesRestantes, isNull);
      });
    });

    test('trouver le mot ×3 au niveau 9', () {
      final partie = creerPartie(
        donneesDeTest(anagrammes: const ['POUTRE']),
        niveau: Niveau.n9,
      )..commencerPartie();
      partie
        ..choisirPari(true)
        ..choisirNombre(1)
        ..validerPari();
      poser(partie, 'POUTRE');
      expect(partie.score, (10 + 20 + 15 + 10) * 3);
      expect(partie.secondesRestantes, isNull, reason: 'le chrono s\'arrête avec la manche');
    });
  });

  group('La partie', () {
    test('cinq manches, puis le bilan et le record', () {
      final stockage = StockageMemoire();
      final partie = creerPartie(chargerVraiesDonnees(), stockage: stockage)..commencerPartie();
      for (var m = 1; m <= 5; m++) {
        expect(partie.manche, m);
        final aDesAnagrammes = !partie.courant.estPiege;
        partie
          ..choisirPari(aDesAnagrammes)
          ..validerPari();
        if (aDesAnagrammes) {
          for (final a in partie.courant.anagrammes) {
            poser(partie, a);
          }
        }
        expect(partie.phase, Phase.terminee);
        expect(partie.derniereManche, m == 5);
        partie.suivant();
      }
      expect(partie.vue, Vue.bilan);
      expect(partie.journal, hasLength(5));
      expect(partie.journal.every((j) => j.pariJuste == true), isTrue);
      expect(partie.journal.fold<int>(0, (s, j) => s + j.points), partie.score);
      expect(partie.nouveauRecord, isTrue);
      expect(stockage.lireRecord(Niveau.n1), partie.score);

      // Rejouer : le record précédent devient celui à battre.
      final record = partie.score;
      partie.commencerPartie();
      expect(partie.score, 0);
      expect(partie.manche, 1);
      expect(partie.recordAvantPartie, record);
      expect(partie.nouveauRecord, isFalse);
    });

    test('un record par niveau', () {
      final stockage = StockageMemoire(niveauDebloque: 10)
        ..ecrireRecord(Niveau.n9, 420);
      final partie = creerPartie(chargerVraiesDonnees(), stockage: stockage);
      expect(partie.record, 0);
      partie.choisirNiveau(Niveau.n9);
      expect(partie.record, 420);
      expect(stockage.dernierNiveau, Niveau.n9);
    });

    test('quitter ramène à l\'accueil et arrête le chrono', () {
      fakeAsync((async) {
        final partie = creerPartie(
          donneesDeTest(),
          niveau: Niveau.n9,
          horloge: HorlogeDeTest(),
        )..commencerPartie();
        partie
          ..choisirPari(true)
          ..choisirNombre(1)
          ..validerPari();
        partie.quitter();
        expect(partie.vue, Vue.accueil);
        expect(partie.secondesRestantes, isNull);
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  group('La progression', () {
    /// Joue une partie entière, en trouvant tout ou en ratant tout.
    void jouer(PartieController partie, {required bool reussir}) {
      partie.commencerPartie();
      while (partie.vue == Vue.jeu) {
        final aDesAnagrammes = !partie.courant.estPiege;
        partie.choisirPari(reussir == aDesAnagrammes);
        if (partie.demandeCombien) {
          partie.choisirNombre(partie.courant.anagrammes.length.clamp(1, 6));
        }
        partie.validerPari();
        if (reussir && !partie.finie) {
          for (final a in partie.courant.anagrammes) {
            poser(partie, a);
          }
        }
        if (!partie.finie) partie.abandonner();
        partie.suivant();
      }
    }

    test('au départ, seul le niveau 1 est ouvert', () {
      final partie = creerPartie(chargerVraiesDonnees(), stockage: StockageMemoire());
      expect(Niveau.values.where(partie.estDebloque), [Niveau.n1]);
      partie
        ..choisirNiveau(Niveau.n2)
        ..choisirCategorie(Categorie.competition);
      expect(partie.niveau, Niveau.n1);
    });

    test('l\'objectif atteint débloque le niveau suivant, une seule fois', () {
      final stockage = StockageMemoire();
      final partie = creerPartie(chargerVraiesDonnees(), stockage: stockage);

      jouer(partie, reussir: false);
      expect(partie.objectifAtteint, isFalse);
      expect(stockage.niveauDebloque, 1);

      jouer(partie, reussir: true);
      // Niveau 1 : cinq mots à une anagramme, 35 points chacun ; objectif 50 %.
      expect(partie.objectif, 88);
      expect(partie.niveauGagne, Niveau.n2);
      expect(stockage.niveauDebloque, 2);

      jouer(partie, reussir: true);
      expect(partie.niveauGagne, isNull);
      expect(stockage.niveauDebloque, 2);
    });

    test('choisir une catégorie prend son plus haut niveau ouvert', () {
      final partie = creerPartie(chargerVraiesDonnees(),
          stockage: StockageMemoire(niveauDebloque: 7));
      partie.choisirCategorie(Categorie.competition);
      expect(partie.niveau, Niveau.n6);
      partie.choisirCategorie(Categorie.entrainement);
      expect(partie.niveau, Niveau.n7);
    });

    test('le temps de recherche est mesuré en compétition seulement', () {
      for (final (niveau, attendu) in [
        (Niveau.n3, const Duration(seconds: 12)),
        (Niveau.n1, null),
      ]) {
        final horloge = HorlogeDeTest();
        final partie = creerPartie(donneesDeTest(),
            niveau: niveau, horloge: horloge)
          ..commencerPartie()
          ..choisirPari(true)
          ..validerPari();
        horloge.avancer(const Duration(seconds: 12));
        partie.abandonner();
        expect(partie.journal.single.duree, attendu);
        expect(partie.tempsTotal, attendu ?? Duration.zero);
        partie.dispose();
      }
    });
  });
}
