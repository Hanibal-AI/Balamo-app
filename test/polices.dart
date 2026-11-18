import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices de l'application dans les tests de widgets.
///
/// Sans cela, Flutter dessine le texte avec « Ahem », une police de test dont
/// chaque caractère est un carré : les mises en page n'auraient pas les
/// dimensions réelles et les captures seraient illisibles.
Future<void> chargerPolices() async {
  Future<void> charger(String famille, List<String> fichiers) async {
    final chargeur = FontLoader(famille);
    for (final fichier in fichiers) {
      final octets = File(fichier).readAsBytesSync();
      chargeur.addFont(Future.value(ByteData.sublistView(octets)));
    }
    await chargeur.load();
  }

  const d = 'assets/fonts';
  await charger('Alegreya', ['$d/Alegreya.ttf', '$d/Alegreya-Italic.ttf']);
  await charger('AlegreyaSans', [
    '$d/AlegreyaSans-Regular.ttf',
    '$d/AlegreyaSans-Medium.ttf',
    '$d/AlegreyaSans-Bold.ttf',
  ]);
  await charger('AlegreyaSansSC', [
    '$d/AlegreyaSansSC-Medium.ttf',
    '$d/AlegreyaSansSC-Bold.ttf',
  ]);
  await charger('Archivo', ['$d/Archivo.ttf']);

  // Les icônes Material sont fournies par le SDK Flutter.
  final racine = Platform.environment['FLUTTER_ROOT'];
  if (racine != null) {
    final icones = File(
      '$racine/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icones.existsSync()) await charger('MaterialIcons', [icones.path]);
  }
}

/// Donne à la fenêtre de test la taille d'un téléphone (en points logiques).
void tailleTelephone(WidgetTester tester, {double largeur = 360, double hauteur = 760}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(largeur * 3, hauteur * 3);
  addTearDown(tester.view.reset);
}
