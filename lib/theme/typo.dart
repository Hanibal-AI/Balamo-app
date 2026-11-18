import 'package:flutter/painting.dart';

/// Les quatre voix typographiques de Balamo (polices embarquées, voir
/// `pubspec.yaml`) :
///
/// - [titre] / [texte] : Alegreya, la serif du dictionnaire ;
/// - [ui] : Alegreya Sans, pour les boutons et les messages ;
/// - [capitales] : Alegreya Sans SC, petites capitales des étiquettes ;
/// - [jeton] : Archivo extra-gras, gravé sur les jetons.
abstract final class Typo {
  static const String _serif = 'Alegreya';
  static const String _sans = 'AlegreyaSans';
  static const String _petitesCapitales = 'AlegreyaSansSC';
  static const String _jeton = 'Archivo';

  /// Titres en Alegreya (police variable : la graisse passe par l'axe `wght`).
  static TextStyle titre(
    double taille, {
    Color? couleur,
    FontWeight graisse = FontWeight.w800,
    double hauteur = 1.1,
  }) =>
      TextStyle(
        fontFamily: _serif,
        fontSize: taille,
        height: hauteur,
        color: couleur,
        fontWeight: graisse,
        fontVariations: [FontVariation('wght', graisse.value.toDouble())],
        // Chiffres alignés et de même largeur : le « 0 » elzévirien
        // d'Alegreya se confond avec un « o » dans les compteurs.
        fontFeatures: const [
          FontFeature.liningFigures(),
          FontFeature.tabularFigures(),
        ],
        letterSpacing: -0.2,
      );

  /// Texte courant en Alegreya.
  static TextStyle texte(
    double taille, {
    Color? couleur,
    bool italique = false,
    FontWeight graisse = FontWeight.w400,
    double hauteur = 1.5,
  }) =>
      TextStyle(
        fontFamily: _serif,
        fontSize: taille,
        height: hauteur,
        color: couleur,
        fontStyle: italique ? FontStyle.italic : FontStyle.normal,
        fontWeight: graisse,
        fontVariations: [FontVariation('wght', graisse.value.toDouble())],
      );

  /// Interface en Alegreya Sans.
  static TextStyle ui(
    double taille, {
    Color? couleur,
    FontWeight graisse = FontWeight.w400,
    double hauteur = 1.35,
  }) =>
      TextStyle(
        fontFamily: _sans,
        fontSize: taille,
        height: hauteur,
        color: couleur,
        fontWeight: graisse,
      );

  /// Étiquettes en petites capitales espacées.
  static TextStyle capitales(
    double taille, {
    Color? couleur,
    FontWeight graisse = FontWeight.w500,
  }) =>
      TextStyle(
        fontFamily: _petitesCapitales,
        fontSize: taille,
        height: 1.2,
        color: couleur,
        fontWeight: graisse,
        letterSpacing: taille * 0.1,
      );

  /// Lettres des jetons et des cases.
  static TextStyle jeton(
    double taille, {
    Color? couleur,
    double espacement = 0,
  }) =>
      TextStyle(
        fontFamily: _jeton,
        fontSize: taille,
        height: 1,
        color: couleur,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 800)],
        letterSpacing: espacement,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
