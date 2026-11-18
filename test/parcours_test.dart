import 'package:balamo/app.dart';
import 'package:balamo/logic/partie_controller.dart';
import 'package:balamo/logic/regles.dart';
import 'package:balamo/models/etat_manche.dart';
import 'package:balamo/models/niveau.dart';
import 'package:balamo/widgets/jeton_widget.dart';
import 'package:balamo/widgets/revelation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'aides.dart';
import 'polices.dart';

Finder _jeton(String lettre) => find.widgetWithText(JetonWidget, lettre);

Future<void> _composer(WidgetTester tester, PartieController partie, String mot) async {
  for (final lettre in mot.split('')) {
    await tester.tap(_jeton(lettre));
    // Une image pour lancer le déplacement du jeton, une autre pour le finir.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUpAll(chargerPolices);

  testWidgets('une manche complète au doigt, du pari à la révélation', (tester) async {
    tailleTelephone(tester);
    final partie = creerPartie(donneesDeTest());
    addTearDown(partie.dispose);
    await tester.pumpWidget(BalamoApp(partie: partie));

    // Accueil.
    expect(find.text('Balamo'), findsOneWidget);
    expect(find.text('Facile'), findsOneWidget);
    expect(find.textContaining('Bouton indice (−5 points)'), findsOneWidget);
    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();

    // 1 · Le pari.
    expect(find.text('troupe'), findsOneWidget);
    expect(find.text('6 lettres'), findsOneWidget);
    expect(find.text('Combien ?'), findsNothing, reason: 'pas en facile');
    await tester.tap(find.text('Oui'));
    await tester.pump();
    await tester.tap(find.text('Valider le pari'));
    await tester.pumpAndSettle();
    expect(partie.phase, Phase.recherche);
    expect(partie.score, 10);
    expect(find.byType(JetonWidget), findsNWidgets(6));
    expect(find.text('······'), findsNWidgets(2));

    // 2 · La recherche : un indice, puis un mot refusé, puis les deux anagrammes.
    await tester.tap(find.text('Indice −5', findRichText: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(partie.score, 5);
    expect(find.text('P·····'), findsOneWidget);
    expect(find.text('T·····'), findsOneWidget);

    await _composer(tester, partie, 'EPORTU');
    expect(partie.etatPlateau, EtatPlateau.refuse);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout ramener'));
    await tester.pumpAndSettle();
    expect(partie.plateau, isEmpty);

    await _composer(tester, partie, 'POUTRE');
    expect(partie.trouvees, ['POUTRE']);
    expect(partie.score, 20);
    expect(find.byType(Revelation), findsOneWidget);
    await tester.pump(Regles.delaiRetourJetons);
    await tester.pumpAndSettle();
    expect(partie.plateau, isEmpty, reason: 'les jetons sont revenus au chevalet');

    await _composer(tester, partie, 'TOUPER');
    await tester.pumpAndSettle();

    // 3 · La révélation.
    expect(partie.phase, Phase.terminee);
    expect(partie.score, 20 + 15 + 10);
    expect(find.byType(JetonWidget), findsNothing);
    expect(find.text('Mot suivant'), findsOneWidget);
    expect(find.text('TROUPE'), findsOneWidget, reason: 'la case du mot de départ');
    await tester.tap(find.text('TROUPE'));
    await tester.pumpAndSettle();
    expect(partie.orthographeRevelee, 'TROUPE');

    await tester.tap(find.text('Mot suivant'));
    await tester.pumpAndSettle();
    expect(partie.manche, 2);
    expect(partie.phase, Phase.pari);
  });

  testWidgets('on peut glisser un jeton du chevalet au plateau, et le replacer', (tester) async {
    tailleTelephone(tester);
    final partie = creerPartie(donneesDeTest())..commencerPartie();
    addTearDown(partie.dispose);
    partie
      ..choisirPari(true)
      ..validerPari();
    await tester.pumpWidget(BalamoApp(partie: partie));
    await tester.pumpAndSettle();

    // Trois jetons posés d'un appui…
    await _composer(tester, partie, 'OUT');
    await tester.pumpAndSettle();
    expect(partie.motPose, 'OUT');

    // … puis P glissé tout à gauche du plateau.
    final plateau = tester.getCenter(_jeton('O'));
    final geste = await tester.startGesture(tester.getCenter(_jeton('P')));
    await tester.pump(const Duration(milliseconds: 50));
    await geste.moveTo(Offset(plateau.dx - 60, plateau.dy + 10));
    await tester.pump(const Duration(milliseconds: 50));
    await geste.moveTo(Offset(plateau.dx - 80, plateau.dy));
    await tester.pump(const Duration(milliseconds: 50));
    expect(partie.motPose, 'POUT', reason: 'le jeton prend sa place pendant le glisser');
    await geste.up();
    await tester.pumpAndSettle();
    expect(partie.motPose, 'POUT');

    // Et T ramené au chevalet en le glissant vers le bas.
    final chevalet = tester.getCenter(_jeton('R'));
    await tester.dragFrom(
      tester.getCenter(_jeton('T')),
      chevalet - tester.getCenter(_jeton('T')),
    );
    await tester.pumpAndSettle();
    expect(partie.motPose, 'POU');
    expect(partie.chevalet.map((j) => j.lettre), contains('T'));
  });

  testWidgets('intermédiaire : le pari demande combien', (tester) async {
    tailleTelephone(tester);
    final partie = creerPartie(
      donneesDeTest(niveau: Niveau.intermediaire),
      niveau: Niveau.intermediaire,
    );
    addTearDown(partie.dispose);
    await tester.pumpWidget(BalamoApp(partie: partie));
    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oui'));
    await tester.pumpAndSettle();
    expect(find.text('Combien ?'), findsOneWidget);
    expect(find.text('6+'), findsOneWidget);
    expect(partie.pariValidable, isFalse);
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('Valider le pari'));
    await tester.pumpAndSettle();
    expect(partie.score, 60);
    expect(find.textContaining('Indice', findRichText: true), findsNothing,
        reason: 'pas d\'indice à ce niveau');
  });

  testWidgets('le bilan liste les manches et rouvre l\'histoire d\'un mot', (tester) async {
    tailleTelephone(tester);
    final partie = creerPartie(chargerVraiesDonnees())..commencerPartie();
    addTearDown(partie.dispose);
    for (var m = 0; m < 5; m++) {
      partie
        ..choisirPari(true)
        ..validerPari();
      if (!partie.finie) partie.abandonner();
      partie.suivant();
    }
    await tester.pumpWidget(BalamoApp(partie: partie));
    await tester.pumpAndSettle();

    expect(partie.vue, Vue.bilan);
    expect(find.textContaining('Bilan · facile · 5 manches'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);
    final premier = partie.journal.first;
    await tester.tap(find.text(premier.lemme));
    await tester.pumpAndSettle();
    expect(find.byType(Revelation), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('aucun débordement sur un petit écran, même avec un mot de 11 lettres', (tester) async {
    tailleTelephone(tester, largeur: 320, hauteur: 568);
    final partie = creerPartie(
      donneesDeTest(
        tuiles: 'ANTIMATIERE',
        anagrammes: const ['TAMINERAIET'],
        niveau: Niveau.expert,
      ),
      niveau: Niveau.expert,
    );
    addTearDown(partie.dispose);
    await tester.pumpWidget(BalamoApp(partie: partie));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer la partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('Valider le pari'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(JetonWidget), findsNWidgets(11));
    expect(find.text('1:30'), findsOneWidget);
    partie.quitter();
    await tester.pumpAndSettle();
  });
}
