import 'dart:io';

import 'package:balamo/app.dart';
import 'package:balamo/logic/partie_controller.dart';
import 'package:balamo/logic/reglages_audio.dart';
import 'package:balamo/models/etat_manche.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/services/audio.dart';
import 'package:balamo/services/stockage.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aides.dart';
import 'polices.dart';

/// Lance une partie et note, dans l'ordre, tous les événements signalés.
(PartieController, List<Retour>) _partieEcoutee({
  Niveau niveau = Niveau.facile,
  List<String> anagrammes = const ['POUTRE', 'TOUPER'],
  HorlogeDeTest? horloge,
}) {
  final entendus = <Retour>[];
  final partie = creerPartie(
    donneesDeTest(niveau: niveau, anagrammes: anagrammes),
    niveau: niveau,
    horloge: horloge,
  )..surRetour = entendus.add;
  return (partie, entendus);
}

void main() {
  group('Chaque action a son son', () {
    test('du début de partie à la dernière anagramme', () {
      final (partie, entendus) = _partieEcoutee();

      partie.commencerPartie();
      expect(entendus, [Retour.debutDePartie]);

      entendus.clear();
      partie
        ..choisirPari(true)
        ..validerPari();
      expect(entendus, [Retour.choix, Retour.pariJuste]);

      // Un jeton posé, puis repris.
      entendus.clear();
      final jeton = partie.chevalet.first;
      partie
        ..basculerJeton(jeton.id)
        ..basculerJeton(jeton.id);
      expect(entendus, [Retour.jetonPose, Retour.jetonRepris]);

      entendus.clear();
      partie.melanger();
      expect(entendus, [Retour.melange]);

      // « Tout ramener » ne s'entend que s'il y a des jetons à ramener.
      entendus.clear();
      partie.toutRamener();
      expect(entendus, isEmpty);
      partie
        ..basculerJeton(partie.chevalet.first.id)
        ..toutRamener();
      expect(entendus, [Retour.jetonPose, Retour.toutRamene]);

      entendus.clear();
      partie.demanderIndice();
      expect(entendus, [Retour.indice]);

      // Mot refusé : le dernier jeton posé, puis le refus.
      entendus.clear();
      poser(partie, 'EPORTU');
      expect(entendus.last, Retour.motRefuse);
      expect(entendus.where((r) => r == Retour.jetonPose), hasLength(6));

      entendus.clear();
      poser(partie, 'TROUPE');
      expect(entendus.last, Retour.motNeutre);

      entendus.clear();
      poser(partie, 'POUTRE');
      expect(entendus.last, Retour.motTrouve);

      entendus.clear();
      poser(partie, 'TOUPER');
      expect(entendus.last, Retour.toutesTrouvees);

      // Revoir un mot, puis passer au suivant.
      entendus.clear();
      partie
        ..reveler('POUTRE')
        ..suivant();
      expect(entendus, [Retour.bouton, Retour.motSuivant]);
    });

    test('glisser un jeton : on l\'entend partir, puis arriver', () {
      final (partie, entendus) = _partieEcoutee();
      partie
        ..commencerPartie()
        ..choisirPari(true)
        ..validerPari();
      entendus.clear();

      final jeton = partie.chevalet.first;
      partie
        ..saisirJeton(jeton.id)
        ..deplacerJeton(jeton.id, Zone.plateau, 0)
        ..relacherJeton(jeton.id);
      expect(entendus, [Retour.jetonSaisi, Retour.jetonPose]);

      entendus.clear();
      partie
        ..saisirJeton(jeton.id)
        ..deplacerJeton(jeton.id, Zone.chevalet, 0)
        ..relacherJeton(jeton.id);
      expect(entendus, [Retour.jetonSaisi, Retour.jetonRepris]);
    });

    test('pari raté, indice refusé, réponses demandées, départ', () {
      final (partie, entendus) = _partieEcoutee();
      partie
        ..commencerPartie()
        ..choisirPari(false)
        ..validerPari();
      expect(entendus.last, Retour.pariRate);

      partie.demanderIndice(); // 0 point : refusé
      expect(entendus.last, Retour.indiceRefuse);

      partie.abandonner();
      expect(entendus.last, Retour.reponses);

      partie.quitter();
      expect(entendus.last, Retour.quitter);
    });

    test('le chrono fait tic pendant les dix dernières secondes, puis sonne la fin', () {
      fakeAsync((async) {
        final horloge = HorlogeDeTest();
        final (partie, entendus) = _partieEcoutee(niveau: Niveau.expert, horloge: horloge);
        partie
          ..commencerPartie()
          ..choisirPari(true)
          ..choisirNombre(2)
          ..validerPari();
        entendus.clear();

        void attendre(int secondes) {
          for (var i = 0; i < secondes * 4; i++) {
            horloge.avancer(const Duration(milliseconds: 250));
            async.elapse(const Duration(milliseconds: 250));
          }
        }

        attendre(79);
        expect(entendus, isEmpty, reason: 'silence tant qu\'il reste plus de dix secondes');
        attendre(10);
        expect(entendus, List.filled(10, Retour.tic));
        attendre(2);
        expect(entendus.last, Retour.tempsEcoule);
        expect(entendus.where((r) => r == Retour.reponses), isEmpty);
      });
    });

    test('la fin de partie sonne le bilan, ou le record s\'il est battu', () {
      final stockage = StockageMemoire();
      final entendus = <Retour>[];
      final partie = creerPartie(chargerVraiesDonnees(), stockage: stockage)
        ..surRetour = entendus.add;

      void jouerUnePartie({required bool bien}) {
        partie.commencerPartie();
        for (var m = 0; m < 5; m++) {
          final oui = !partie.courant.estPiege;
          partie
            ..choisirPari(bien ? oui : !oui)
            ..validerPari();
          if (!partie.finie) partie.abandonner();
          partie.suivant();
        }
      }

      jouerUnePartie(bien: true);
      expect(entendus.last, Retour.nouveauRecord);
      jouerUnePartie(bien: false);
      expect(entendus.last, Retour.bilan);
    });

    test('tous les fichiers sonores attendus sont dans assets/sons/', () {
      final source = File('lib/services/audio_balamo.dart').readAsStringSync();
      final carte = source.substring(source.indexOf('_bruitages = {'), source.indexOf('};'));
      final noms = RegExp(r"'([a-z_0-9]+)'").allMatches(carte).map((m) => m.group(1)!).toSet();
      expect(noms.length, greaterThan(20));
      for (final nom in noms) {
        expect(File('assets/sons/$nom.wav').existsSync(), isTrue, reason: '$nom.wav');
      }
      expect(File('assets/sons/musique.m4a').existsSync(), isTrue);
      // Et chaque événement du jeu a un son.
      for (final retour in Retour.values) {
        expect(carte, contains('Retour.${retour.name}:'), reason: retour.name);
      }
    });
  });

  group('Les réglages Sons et Musique', () {
    setUpAll(chargerPolices);

    test('sont activés par défaut, s\'appliquent au moteur et sont mémorisés', () {
      final stockage = StockageMemoire();
      final audio = AudioMuet();
      final reglages = ReglagesAudio(stockage: stockage, audio: audio);
      expect((reglages.sons, reglages.musique), (true, true));
      expect((audio.sons, audio.musique), (true, true));

      reglages.basculerMusique();
      expect(audio.musique, isFalse);
      expect(audio.sons, isTrue);

      reglages.basculerSons();
      expect(audio.sons, isFalse);
      expect(audio.joues, isEmpty, reason: 'pas de son quand on les coupe');
      reglages.basculerSons();
      expect(audio.joues, [Retour.choix], reason: 'un son confirme qu\'ils sont revenus');

      // Une nouvelle session retrouve les choix du joueur.
      reglages.basculerSons();
      final audio2 = AudioMuet();
      final retrouves = ReglagesAudio(stockage: stockage, audio: audio2);
      expect((retrouves.sons, retrouves.musique), (false, false));
      expect((audio2.sons, audio2.musique), (false, false));
    });

    testWidgets('les interrupteurs de l\'accueil pilotent les réglages', (tester) async {
      tailleTelephone(tester, hauteur: 1000);
      final audio = AudioMuet();
      final reglages = ReglagesAudio(stockage: StockageMemoire(), audio: audio);
      final partie = creerPartie(donneesDeTest());
      addTearDown(partie.dispose);
      await tester.pumpWidget(BalamoApp(partie: partie, reglagesAudio: reglages));

      await tester.scrollUntilVisible(find.text('Musique'), 200);
      await tester.tap(find.text('Musique'));
      await tester.pump();
      expect(reglages.musique, isFalse);
      expect(audio.musique, isFalse);

      await tester.tap(find.text('Sons'));
      await tester.pump();
      expect(reglages.sons, isFalse);
    });
  });
}
