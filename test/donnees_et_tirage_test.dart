import 'dart:math';

import 'package:balamo/logic/tirage.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/widgets/mini_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aides.dart';

String _cle(String mot) => (mot.split('')..sort()).join();

void main() {
  final donnees = chargerVraiesDonnees();

  group('Les données embarquées', () {
    test('chaque niveau a des mots, dont des pièges', () {
      for (final niveau in Niveau.values) {
        expect(donnees.nombreDeMots(niveau), greaterThan(10), reason: niveau.libelle);
        expect(donnees.nombreDePieges(niveau), greaterThan(0), reason: niveau.libelle);
      }
    });

    test('chaque mot jouable a son entrée de dictionnaire', () {
      for (final entree in donnees.partie) {
        final mot = donnees.motDe(entree);
        expect(mot, isNotNull, reason: entree.note);
        expect(mot!.lemme, isNotEmpty);
        expect(mot.definition, isNotEmpty, reason: entree.note);
      }
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

    test('chaque orthographe à révéler a au moins un sens', () {
      for (final entree in donnees.partie) {
        for (final orthographe in [entree.tuiles, ...entree.anagrammes]) {
          expect(donnees.sensDe(orthographe), isNotEmpty, reason: orthographe);
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
      for (final total in [5, 10]) {
        test('${niveau.libelle}, $total manches', () {
          for (var graine = 0; graine < 40; graine++) {
            final pioche = composerPioche(
              partie: donnees.partie,
              niveau: niveau,
              total: total,
              hasard: Random(graine),
            );
            expect(pioche, hasLength(total));
            expect(pioche.every((p) => p.niveau == niveau), isTrue);
            // Jamais deux mots du même groupe d'anagrammes : l'un donnerait l'autre.
            expect(pioche.map((p) => p.cleAnagramme).toSet(), hasLength(total));
            // Environ un piège sur quatre.
            final pieges = pioche.where((p) => p.estPiege).length;
            expect(pieges, min((total / 4).round(), donnees.nombreDePieges(niveau)));
          }
        });
      }
    }

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
