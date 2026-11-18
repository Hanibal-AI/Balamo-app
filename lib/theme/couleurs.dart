import 'package:material_ui/material_ui.dart';

/// La palette de Balamo : une page de vieux dictionnaire scolaire, de l'encre
/// violette, et des jetons en hêtre posés sur un chevalet en bois.
///
/// Les teintes reprennent celles du prototype web, en clair comme en sombre.
@immutable
class CouleursBalamo extends ThemeExtension<CouleursBalamo> {
  const CouleursBalamo({
    required this.papier,
    required this.feuille,
    required this.encre,
    required this.encreDouce,
    required this.filet,
    required this.violette,
    required this.violettePale,
    required this.ok,
    required this.okPale,
    required this.non,
    required this.nonPale,
    required this.bois,
    required this.boisClair,
    required this.boisFonce,
    required this.boisBord,
    required this.boisEncre,
    required this.chevalet,
    required this.chevaletOmbre,
  });

  /// Fond de page, bleuté.
  final Color papier;

  /// Fond des cartes et des zones de saisie.
  final Color feuille;

  /// Texte principal, noir-bleu.
  final Color encre;

  /// Texte secondaire.
  final Color encreDouce;

  /// Filets et bordures discrètes.
  final Color filet;

  /// Couleur d'accent : l'encre violette des dictées.
  final Color violette;
  final Color violettePale;

  final Color ok;
  final Color okPale;
  final Color non;
  final Color nonPale;

  /// Jetons en hêtre.
  final Color bois;
  final Color boisClair;
  final Color boisFonce;
  final Color boisBord;
  final Color boisEncre;

  /// Chevalet.
  final Color chevalet;
  final Color chevaletOmbre;

  static const clair = CouleursBalamo(
    papier: Color(0xFFEEF0F4),
    feuille: Color(0xFFF8F9FB),
    encre: Color(0xFF1C2238),
    encreDouce: Color(0xFF5A6178),
    filet: Color(0xFFD3D7E2),
    violette: Color(0xFF5A3EA6),
    violettePale: Color(0xFFEBE6F7),
    ok: Color(0xFF1F7A4D),
    okPale: Color(0xFFE2F2E9),
    non: Color(0xFFB3261E),
    nonPale: Color(0xFFFBE7E5),
    bois: Color(0xFFE8CF9C),
    boisClair: Color(0xFFF3DFB4),
    boisFonce: Color(0xFFDCBF86),
    boisBord: Color(0xFFB8955A),
    boisEncre: Color(0xFF2B1D0C),
    chevalet: Color(0xFF8A5A2B),
    chevaletOmbre: Color(0xFF5D3A19),
  );

  static const sombre = CouleursBalamo(
    papier: Color(0xFF121628),
    feuille: Color(0xFF1A1F36),
    encre: Color(0xFFE6E8F2),
    encreDouce: Color(0xFFA5ABC4),
    filet: Color(0xFF2E3552),
    violette: Color(0xFFB9A5F2),
    violettePale: Color(0xFF2A2550),
    ok: Color(0xFF6FD3A0),
    okPale: Color(0xFF173327),
    non: Color(0xFFFF8F86),
    nonPale: Color(0xFF3A1C1C),
    bois: Color(0xFFE8CF9C),
    boisClair: Color(0xFFF3DFB4),
    boisFonce: Color(0xFFDCBF86),
    boisBord: Color(0xFFB8955A),
    boisEncre: Color(0xFF2B1D0C),
    chevalet: Color(0xFF6E4520),
    chevaletOmbre: Color(0xFF3D2410),
  );

  @override
  CouleursBalamo copyWith() => this;

  @override
  CouleursBalamo lerp(ThemeExtension<CouleursBalamo>? other, double t) {
    if (other is! CouleursBalamo) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t)!;
    return CouleursBalamo(
      papier: m(papier, other.papier),
      feuille: m(feuille, other.feuille),
      encre: m(encre, other.encre),
      encreDouce: m(encreDouce, other.encreDouce),
      filet: m(filet, other.filet),
      violette: m(violette, other.violette),
      violettePale: m(violettePale, other.violettePale),
      ok: m(ok, other.ok),
      okPale: m(okPale, other.okPale),
      non: m(non, other.non),
      nonPale: m(nonPale, other.nonPale),
      bois: m(bois, other.bois),
      boisClair: m(boisClair, other.boisClair),
      boisFonce: m(boisFonce, other.boisFonce),
      boisBord: m(boisBord, other.boisBord),
      boisEncre: m(boisEncre, other.boisEncre),
      chevalet: m(chevalet, other.chevalet),
      chevaletOmbre: m(chevaletOmbre, other.chevaletOmbre),
    );
  }
}

extension CouleursDuContexte on BuildContext {
  /// La palette Balamo du thème courant (clair ou sombre).
  CouleursBalamo get couleurs =>
      Theme.of(this).extension<CouleursBalamo>() ?? CouleursBalamo.clair;
}
