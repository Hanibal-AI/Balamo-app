// Génère les captures d'écran de docs/captures/ à partir de la vraie
// interface, sans téléphone ni émulateur :
//
//     flutter test tool/captures_test.dart --update-goldens
//
// Ce fichier n'est pas dans test/ : il ne tourne pas avec `flutter test`.
import 'package:balamo/app.dart';
import 'package:balamo/logic/partie_controller.dart';
import 'package:balamo/models/donnees_jeu.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/widgets/jeton_widget.dart';
import 'package:balamo/widgets/regles_feuille.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/aides.dart';
import '../test/polices.dart';

/// Les données réelles, réduites à un seul mot jouable pour choisir la scène.
DonneesJeu _avecSeulement(DonneesJeu d, String tuiles) => DonneesDeTest(
      genere: d.genere,
      mots: d.mots,
      orthographes: d.orthographes,
      partie: d.partie.where((p) => p.tuiles == tuiles).toList(),
    );

Future<void> _capture(WidgetTester tester, String nom) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/captures/$nom.png'),
  );
}

Future<void> _poser(WidgetTester tester, String mot) async {
  for (final lettre in mot.split('')) {
    await tester.tap(find.widgetWithText(JetonWidget, lettre).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  final donnees = chargerVraiesDonnees();

  setUpAll(chargerPolices);
  setUp(() => debugDisableShadows = false);

  Future<PartieController> lancer(
    WidgetTester tester, {
    String? mot,
    Niveau niveau = Niveau.n1,
    double largeur = 390,
    double hauteur = 844,
    Brightness theme = Brightness.light,
  }) async {
    tailleTelephone(tester, largeur: largeur, hauteur: hauteur);
    tester.platformDispatcher.platformBrightnessTestValue = theme;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final partie = creerPartie(
      mot == null ? donnees : _avecSeulement(donnees, mot),
      niveau: niveau,
    );
    addTearDown(partie.dispose);
    await tester.pumpWidget(BalamoApp(partie: partie));
    await tester.pumpAndSettle();
    return partie;
  }

  testWidgets('accueil', (tester) async {
    await lancer(tester);
    await _capture(tester, '01-accueil');
    debugDisableShadows = true;
  });

  testWidgets('pari, recherche et révélation (facile)', (tester) async {
    final partie = await lancer(tester, mot: 'LAPIN', niveau: Niveau.n2);
    partie.commencerPartie();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui'));
    await _capture(tester, '02-pari');

    await tester.tap(find.text('Valider le pari'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Indice −5', findRichText: true));
    await tester.pump(const Duration(milliseconds: 300));
    await _poser(tester, 'PAL');
    await _capture(tester, '03-recherche');

    await _poser(tester, 'NI');
    await _capture(tester, '04-mot-refuse');

    partie.toutRamener();
    await tester.pumpAndSettle();
    await _poser(tester, 'ALPIN');
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/captures/05-mot-trouve.png'),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await _poser(tester, 'PLAIN');
    await _capture(tester, '06-revelation');
    debugDisableShadows = true;
  });

  testWidgets('pari avec « combien » (niveau 4)', (tester) async {
    final partie = await lancer(tester, mot: 'REVEIL', niveau: Niveau.n4);
    partie.commencerPartie();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3'));
    await _capture(tester, '07-pari-combien');
    debugDisableShadows = true;
  });

  testWidgets('compétition en thème sombre, avec chrono', (tester) async {
    final partie = await lancer(
      tester,
      mot: 'MACHINES',
      niveau: Niveau.n9,
      theme: Brightness.dark,
    );
    partie
      ..commencerPartie()
      ..choisirPari(true)
      ..choisirNombre(3)
      ..validerPari();
    await tester.pump(const Duration(milliseconds: 600));
    await _poser(tester, 'CHI');
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/captures/08-expert-sombre.png'),
    );
    partie.quitter();
    await tester.pumpAndSettle();
    debugDisableShadows = true;
  });

  testWidgets('mot piège', (tester) async {
    final piege = donnees.lot(Niveau.n2).firstWhere((p) => p.estPiege);
    final partie = await lancer(tester, mot: piege.tuiles, niveau: Niveau.n2);
    partie
      ..commencerPartie()
      ..choisirPari(false)
      ..validerPari();
    await _capture(tester, '09-piege');
    debugDisableShadows = true;
  });

  testWidgets('bilan', (tester) async {
    final partie = await lancer(tester, niveau: Niveau.n6);
    partie.commencerPartie();
    for (var m = 0; m < 5; m++) {
      final oui = !partie.courant.estPiege;
      partie.choisirPari(m == 2 ? !oui : oui);
      if (partie.demandeCombien) {
        partie.choisirNombre(partie.courant.anagrammes.length.clamp(1, 6));
      }
      partie.validerPari();
      if (!partie.finie) {
        if (m == 1) partie.demanderIndice();
        final anagrammes = partie.courant.anagrammes;
        for (final a in m == 3 ? anagrammes.take(1) : anagrammes) {
          poser(partie, a);
        }
        if (!partie.finie) partie.abandonner();
      }
      partie.suivant();
    }
    await _capture(tester, '10-bilan');
    debugDisableShadows = true;
  });

  testWidgets('règles', (tester) async {
    await lancer(tester);
    montrerRegles(tester.element(find.text('Niveau')));
    await _capture(tester, '11-regles');
    debugDisableShadows = true;
  });

  testWidgets('petit écran, mot long', (tester) async {
    // Le plus long mot jouable qui ait des anagrammes.
    final long = donnees
        .lot(Niveau.n10)
        .where((p) => !p.estPiege)
        .reduce((a, b) => b.tuiles.length > a.tuiles.length ? b : a);
    final partie = await lancer(
      tester,
      mot: long.tuiles,
      niveau: Niveau.n10,
      largeur: 320,
      hauteur: 568,
    );
    partie
      ..commencerPartie()
      ..choisirPari(true)
      ..choisirNombre(long.anagrammes.length)
      ..validerPari();
    await tester.pump(const Duration(milliseconds: 600));
    await _poser(tester, long.tuiles.substring(0, 3));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/captures/12-petit-ecran.png'),
    );
    partie.quitter();
    await tester.pumpAndSettle();
    debugDisableShadows = true;
  });
}
