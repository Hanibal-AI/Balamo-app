import 'package:material_ui/material_ui.dart';

import '../theme/couleurs.dart';
import '../theme/typo.dart';

/// Un compteur de l'en-tête : une valeur en gros, son nom en petites capitales.
class Compteur extends StatelessWidget {
  const Compteur({
    super.key,
    required this.valeur,
    required this.nom,
    this.accent = false,
  });

  final String valeur;
  final String nom;

  /// Valeur à l'encre violette (le score).
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Semantics(
      label: '$nom : $valeur',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (enfant, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.35), end: Offset.zero)
                    .animate(animation),
                child: enfant,
              ),
            ),
            child: Text(
              valeur,
              key: ValueKey(valeur),
              style: Typo.titre(26, couleur: accent ? c.violette : c.encre, hauteur: 1),
            ),
          ),
          const SizedBox(height: 2),
          Text(nom, style: Typo.capitales(12.5, couleur: c.encreDouce)),
        ],
      ),
    );
  }
}

/// En-tête commun : la marque à gauche, les compteurs à droite, et un filet
/// d'encre dessous, comme en haut d'une page de dictionnaire.
class EnTete extends StatelessWidget {
  const EnTete({
    super.key,
    this.compteurs = const [],
    this.compact = false,
    this.debut,
  });

  final List<Widget> compteurs;

  /// Marque plus petite et sans sous-titre (écran de jeu).
  final bool compact;

  /// Widget placé avant la marque (bouton « quitter »).
  final Widget? debut;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Container(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.encre, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ?debut,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Balamo',
                    style: Typo.titre(compact ? 26 : 38, couleur: c.encre, hauteur: 1),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Anagrammes & étymologie',
                    style: Typo.capitales(13.5, couleur: c.encreDouce),
                  ),
                ],
              ],
            ),
          ),
          for (final compteur in compteurs) ...[
            const SizedBox(width: 18),
            compteur,
          ],
        ],
      ),
    );
  }
}

/// Les trois temps d'une manche : pari, recherche, révélation.
class BarreEtapes extends StatelessWidget {
  const BarreEtapes({super.key, required this.etape});

  /// Étape active, de 1 à 3.
  final int etape;

  static const _noms = ['Le pari', 'La recherche', 'La révélation'];

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Semantics(
      label: 'Étape $etape sur 3 : ${_noms[etape - 1]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i == etape
                          ? c.violette
                          : (i < etape ? c.encreDouce : c.filet),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$i · ${_noms[i - 1]}',
                      maxLines: 1,
                      style: Typo.capitales(
                        13.5,
                        couleur: i == etape ? c.encre : c.encreDouce,
                        graisse: i == etape ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
