import 'package:balamo/models/donnees_jeu.dart';
import 'package:balamo/models/mot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/importer_definitions.dart';
import 'aides.dart';

const _entete = 'id|mot|categorie|definition|etymologie';

/// Un mot inconnu du dictionnaire (CAVE) et son anagramme déjà définie (AVEC).
DonneesJeu _donnees({Map<String, Complement> complements = const {}}) =>
    DonneesDeTest(
      genere: 'test',
      mots: {
        'Avec': Mot.vide('avec')
            .completePar(const Complement(definition: 'En compagnie de.')),
      },
      orthographes: {
        'AVEC': [const Lecture(forme: 'avec', note: 'Avec')],
      },
      partie: [
        EntreePartie.depuisFormes(1, ['cave', 'avec']),
      ],
      complements: complements,
    );

void main() {
  group('L\'import du CSV', () {
    test('garde les textes remplis, avec leurs virgules et guillemets', () {
      final resultat = importer([
        '﻿$_entete',
        'CAVE|cave|C1|Pièce en sous-sol, fraîche ; « cellier ».|Du latin, « cava ».',
        '',
      ], _donnees());

      expect(resultat.erreurs, isEmpty);
      expect(resultat.complements['CAVE'], {
        'definition': 'Pièce en sous-sol, fraîche ; « cellier ».',
        'etymologie': 'Du latin, « cava ».',
      });
      expect(resultat.restants, {'C1': 1}, reason: 'AVEC reste sans étymologie');
    });

    test('ignore les lignes vides et ne remplace pas le dictionnaire', () {
      final resultat = importer([
        _entete,
        'CAVE|cave|C1||',
        'AVEC|avec|C1|Autre texte.|Du latin.',
      ], _donnees());

      expect(resultat.complements, {
        'AVEC': {'etymologie': 'Du latin.'},
      });
    });

    test('refuse les lignes fautives en donnant leur numéro', () {
      final resultat = importer([
        _entete,
        'CAVE|cave|C1|Une | de trop|',
        'XYZ|xyz|C1|Texte.|',
        'CAVE|cave|C2|Texte.|',
        'CAVE|cave|C1|Bon texte.|',
        'CAVE|cave|C1|Doublon.|',
      ], _donnees());

      expect(resultat.erreurs, hasLength(4));
      expect(resultat.erreurs.first, startsWith('Ligne 2 : 6 colonnes'));
      expect(resultat.erreurs.last, contains('en double'));
      expect(resultat.complements['CAVE'], {'definition': 'Bon texte.'});
    });

    test('refuse un fichier sans le bon en-tête', () {
      expect(() => importer(['id;mot'], _donnees()), throwsFormatException);
    });
  });

  group('Les textes importés dans le jeu', () {
    test('un mot absent du dictionnaire reçoit une entrée à relire', () {
      final sens = _donnees(complements: const {
        'CAVE': Complement(definition: 'Sous-sol.', etymologie: 'Du latin.'),
      }).sensDe('CAVE').single;

      expect(sens.titre, 'cave');
      expect(sens.mot.definition, 'Sous-sol.');
      expect(sens.mot.definitionARelire, isTrue);
      expect(sens.mot.fiche.enUnePhrase, 'Du latin.');
    });

    test('une entrée existante est seulement complétée', () {
      final sens = _donnees(complements: const {
        'AVEC': Complement(definition: 'Autre.', etymologie: 'Du latin.'),
      }).sensDe('AVEC').single;

      expect(sens.mot.definition, 'En compagnie de.');
      expect(sens.mot.aEtymologie, isTrue);
    });

    test('une étymologie seule n\'affiche pas « à relire »', () {
      final sens = _donnees(complements: const {
        'CAVE': Complement(etymologie: 'Du latin.'),
      }).sensDe('CAVE').single;

      expect(sens.mot.definition, isEmpty);
      expect(sens.mot.definitionARelire, isFalse);
    });
  });
}
