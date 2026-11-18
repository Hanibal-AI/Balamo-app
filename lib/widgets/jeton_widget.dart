import 'package:material_ui/material_ui.dart';

import '../logic/regles.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';

/// Un jeton de lettre en hêtre, avec sa valeur en indice.
class JetonWidget extends StatelessWidget {
  const JetonWidget({
    super.key,
    required this.lettre,
    required this.taille,
    this.enVol = false,
  });

  final String lettre;

  /// Largeur du jeton ; il est plus haut de 2 px, comme une vraie tuile.
  final double taille;

  /// Jeton soulevé par le doigt : ombre portée plus profonde.
  final bool enVol;

  static double hauteurPour(double taille) => taille + 2;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final valeur = Regles.valeursLettres[lettre];
    return Container(
      width: taille,
      height: hauteurPour(taille),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(taille * 0.13),
        gradient: LinearGradient(
          begin: const Alignment(-0.7, -1),
          end: const Alignment(0.7, 1),
          colors: [c.boisClair, c.bois, c.boisFonce],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: enVol
            ? const [
                BoxShadow(
                  color: Color(0x59140A00),
                  offset: Offset(0, 14),
                  blurRadius: 24,
                ),
              ]
            : [
                BoxShadow(color: c.boisBord, offset: const Offset(0, 1.5)),
                BoxShadow(color: c.boisBord, offset: const Offset(0, 3)),
                const BoxShadow(
                  color: Color(0x401E1405),
                  offset: Offset(0, 5),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              lettre,
              style: Typo.jeton(taille * 0.52, couleur: c.boisEncre),
            ),
          ),
          if (valeur != null)
            Positioned(
              right: taille * 0.09,
              bottom: taille * 0.06,
              child: Text(
                '$valeur',
                style: Typo.jeton((taille * 0.2).clamp(7.5, 11), couleur: c.boisEncre),
              ),
            ),
        ],
      ),
    );
  }
}
