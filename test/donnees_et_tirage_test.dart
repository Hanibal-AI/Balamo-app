import 'dart:math';

import 'package:balamo/logic/tirage.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/models/tuiles.dart';
import 'package:balamo/widgets/mini_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aides.dart';

String _cle(String mot) => (mot.split('')..sort()).join();

void main() {
  final donnees = chargerVraiesDonnees();

  group('Les données embarquées', () {
    test('chaque niveau a assez de mots pour une partie, selon ses règles', () {
      for (final niveau in Niveau.values) {
        final lot = donnees.lot(niveau);
        final series = lot.where((p) => !p.estPiege);
        expect(series.length, greaterThanOrEqualTo(5), reason: '${niveau.numero}');
        expect(lot.length - series.length, greaterThanOrEqualTo(niveau.pieges));
        for (final mot in lot) {
          expect(mot.tuiles.length,
              inInclusiveRange(niveau.lettresMin, niveau.lettresMax));
          expect(niveau.partDegres.keys, contains(mot.degre));
          expect(mot.anagrammes.length, lessThanOrEqualTo(niveau.anagrammesMax));
        }
      }
    });

    test('les parts de degrés font 100 % à chaque niveau', () {
      for (final niveau in Niveau.values) {
        expect(niveau.partDegres.values.fold(0, (a, b) => a + b), 100,
            reason: '${niveau.numero}');
      }
    });

    test('aucune série n\'apparaît deux fois', () {
      expect(donnees.partie.map((p) => p.cleAnagramme).toSet(),
          hasLength(donnees.partie.length));
    });

    test('chaque jeton de lettres a son orthographe accentuée', () {
      for (final entree in donnees.partie) {
        expect(entree.formes, hasLength(entree.anagrammes.length + 1));
        expect(enTuiles(entree.forme), entree.tuiles);
      }
      expect(donnees.formeDe('DEJA'), 'déjà');
    });

    test('chaque anagramme utilise exactement les lettres du mot, sans être le mot', () {
      for (final entree in donnees.partie) {
        expect(RegExp(r'^[A-Z]+$').hasMatch(entree.tuiles), isTrue, reason: entree.tuiles);
        expect(entree.anagrammes.toSet(), hasLength(entree.anagrammes.length));
        for (final anagramme in entree.anagrammes) {
          expect(_cle(anagramme), _cle(entree.tuiles), reason: '${entree.tuiles} / $anagramme');
          expect(anagramme, isNot(entree.tuiles));
        }
      }
    });

    test('une forme fléchie est rattachée à son lemme', () {
      final sens = donnees.sensDe('BADEURS');
      expect(sens, isNotEmpty);
      expect(sens.first.titre, isNot(sens.first.mot.lemme));
      expect(sens.first.formeDe, sens.first.mot.lemme);
      // Le mot de départ, lui, s'affiche sous son lemme.
      expect(donnees.sensDe('ABSURDE').first.formeDe, isNull);
    });
  });

  group('La pioche', () {
    for (final niveau in Niveau.values) {
      test('niveau ${niveau.numero} : cinq mots, avec le bon nombre de pièges', () {
        final lot = donnees.lot(niveau);
        for (var graine = 0; graine < 5; graine++) {
          final pioche = composerPioche(
            lot: lot,
            niveau: niveau,
            hasard: Random(graine),
          );
          expect(pioche, hasLength(5));
          expect(pioche.every(lot.contains), isTrue);
          expect(pioche.map((p) => p.cleAnagramme).toSet(), hasLength(5));
          expect(pioche.where((p) => p.estPiege), hasLength(niveau.pieges));
        }
      });
    }

    test('le degré des mots tirés suit la part prévue au niveau', () {
      // Niveau 9 : 70 % de C4, alors que la réserve est surtout en C5.
      final lot = donnees.lot(Niveau.n9);
      final tires = [
        for (var graine = 0; graine < 100; graine++)
          ...composerPioche(lot: lot, niveau: Niveau.n9, hasard: Random(graine))
              .where((p) => !p.estPiege),
      ];
      final part = tires.where((p) => p.degre == 4).length / tires.length;
      expect(part, closeTo(0.7, 0.08));
    });

    test('les lettres sont mélangées, jamais rendues dans l\'ordre', () {
      for (var graine = 0; graine < 50; graine++) {
        final lettres = melangerLettres('SEL', Random(graine));
        expect(lettres.join(), isNot('SEL'));
        expect(lettres..sort(), ['E', 'L', 'S']);
      }
      expect(melangerLettres('AAA', Random(1)).join(), 'AAA');
    });
  });

  group('Le mini-markdown', () {
    test('gras, italique, lien et étoile échappée', () {
      final s = analyserEnLigne(r'Le **latin** *surdus* (\*swer-), voir [TLFi](https://www.cnrtl.fr/x).');
      expect(s.map((x) => x.texte).join(), 'Le latin surdus (*swer-), voir TLFi.');
      expect(s.firstWhere((x) => x.texte == 'latin').gras, isTrue);
      expect(s.firstWhere((x) => x.texte == 'surdus').italique, isTrue);
      expect(s.firstWhere((x) => x.texte == 'TLFi').lien, 'https://www.cnrtl.fr/x');
    });

    test('gras à l\'intérieur d\'un lien, lien à l\'intérieur du gras', () {
      final a = analyserEnLigne('[**Littré**](https://x.fr)').single;
      expect((a.texte, a.gras, a.lien), ('Littré', true, 'https://x.fr'));
      final b = analyserEnLigne('**[Littré](https://x.fr)**').single;
      expect((b.texte, b.gras, b.lien), ('Littré', true, 'https://x.fr'));
    });

    test('styles imbriqués et étoiles isolées', () {
      final a = analyserEnLigne('- ***grêle*, nom féminin** ; une **voix grêle**.');
      expect(a.map((x) => x.texte).join(), '- grêle, nom féminin ; une voix grêle.');
      expect(a.firstWhere((x) => x.texte == 'grêle'), isA<SegmentMd>()
          .having((x) => x.gras, 'gras', isTrue)
          .having((x) => x.italique, 'italique', isTrue));
      final suite = a.firstWhere((x) => x.texte == ', nom féminin');
      expect((suite.gras, suite.italique), (true, false));
      final fin = a.firstWhere((x) => x.texte == ' ; une ');
      expect((fin.gras, fin.italique), (false, false));

      expect(analyserEnLigne('3 * 4 = 12').single.texte, '3 * 4 = 12');
      expect(analyserEnLigne('un *oubli').single.texte, 'un *oubli');
      final b = analyserEnLigne('le grec ***anti***,');
      expect(b[1].texte, 'anti');
      expect((b[1].gras, b[1].italique), (true, true));
    });

    test('paragraphes et listes', () {
      final blocs = analyserMarkdown('Une ligne\nqui continue.\n\n- un\n- deux\n\n![[image.png]]\nFin.');
      expect(blocs, hasLength(3));
      expect((blocs[0] as ParagrapheMd).segments.single.texte, 'Une ligne qui continue.');
      expect((blocs[1] as ListeMd).elements, hasLength(2));
      expect((blocs[2] as ParagrapheMd).segments.single.texte, 'Fin.');
    });

    test('toutes les fiches du jeu s\'analysent sans laisser de balisage visible', () {
      var segments = 0;
      final restes = <String>[];
      void verifier(String texte) {
        for (final bloc in analyserMarkdown(texte)) {
          final lignes = switch (bloc) {
            ParagrapheMd(:final segments) => [segments],
            ListeMd(:final elements) => elements,
          };
          for (final ligne in lignes) {
            for (final s in ligne) {
              segments++;
              // Une étoile en tête de mot est légitime : elle note une forme
              // reconstituée (« *swer- »). Collée après un mot, c'est un reste.
              if (RegExp(r'[\p{L}\d]\*|\*\*|\]\(', unicode: true).hasMatch(s.texte)) restes.add(s.texte);
            }
          }
        }
      }

      for (final mot in donnees.mots.values) {
        verifier(mot.definition);
        verifier(mot.fiche.enUnePhrase);
        verifier(mot.fiche.origine);
        verifier(mot.fiche.aRetenir);
        verifier(mot.fiche.sources);
        for (final etape in mot.fiche.etapes) {
          verifier(etape.titre);
          verifier(etape.texte);
        }
        for (final racine in mot.racines) {
          verifier(racine.note);
        }
      }
      expect(segments, greaterThan(5000));
      expect(restes, isEmpty);
    });
  });
}
