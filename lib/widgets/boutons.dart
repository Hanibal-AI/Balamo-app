import 'package:material_ui/material_ui.dart';

import '../theme/couleurs.dart';
import '../theme/typo.dart';

/// Les trois poids de bouton du prototype.
enum StyleBouton {
  /// Bordure d'encre sur fond de feuille.
  normal,

  /// Plein, à l'encre : l'action principale de l'écran.
  principal,

  /// Bordure légère : actions secondaires.
  discret,
}

/// Bouton de Balamo : large, haut d'au moins 52 px pour le pouce.
///
/// [selectionne] le remplit d'encre violette (choix actif d'un groupe).
class BoutonBalamo extends StatelessWidget {
  const BoutonBalamo({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.style = StyleBouton.normal,
    this.selectionne = false,
    this.icone,
    this.hauteur = 52,
    this.dense = false,
  });

  final String libelle;
  final VoidCallback? onPressed;
  final StyleBouton style;
  final bool selectionne;
  final IconData? icone;
  final double hauteur;

  /// Marges intérieures réduites (boutons de nombre).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final actif = onPressed != null;

    final Color fond;
    final Color texte;
    final Color bord;
    if (selectionne) {
      fond = c.violette;
      texte = c.feuille;
      bord = c.violette;
    } else {
      switch (style) {
        case StyleBouton.principal:
          fond = c.encre;
          texte = c.papier;
          bord = c.encre;
        case StyleBouton.normal:
          fond = c.feuille;
          texte = c.encre;
          bord = c.encre;
        case StyleBouton.discret:
          fond = c.feuille;
          texte = c.encre;
          bord = c.filet;
      }
    }

    final rayon = BorderRadius.circular(14);
    return Semantics(
      button: true,
      enabled: actif,
      selected: selectionne,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: actif ? 1 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: hauteur, minWidth: hauteur),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: rayon,
            border: Border.all(color: bord, width: 2),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: rayon,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 20, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icone != null) ...[
                      Icon(icone, size: 20, color: texte),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        libelle,
                        textAlign: TextAlign.center,
                        style: Typo.ui(
                          style == StyleBouton.discret ? 16 : 17.5,
                          couleur: texte,
                          graisse: style == StyleBouton.discret && !selectionne
                              ? FontWeight.w500
                              : FontWeight.w700,
                          hauteur: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit bouton d'outil : une icône au-dessus d'un libellé court.
class BoutonOutil extends StatelessWidget {
  const BoutonOutil({
    super.key,
    required this.icone,
    required this.libelle,
    required this.onPressed,
    this.attenue = false,
    this.detail,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback? onPressed;

  /// Affiché en retrait (action possible mais déconseillée ou indisponible).
  final bool attenue;

  /// Mention accolée au libellé (ex. le coût d'un indice).
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final rayon = BorderRadius.circular(12);
    return Semantics(
      button: true,
      label: detail == null ? libelle : '$libelle, $detail',
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.35 : (attenue ? 0.55 : 1),
        child: Material(
          color: c.feuille,
          shape: RoundedRectangleBorder(
            borderRadius: rayon,
            side: BorderSide(color: c.filet, width: 1.5),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: rayon,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icone, size: 20, color: c.encre),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          text: libelle,
                          children: [
                            if (detail != null)
                              TextSpan(
                                text: ' $detail',
                                style: TextStyle(
                                  color: c.violette,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        style: Typo.ui(13.5,
                            couleur: c.encre, graisse: FontWeight.w500, hauteur: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Étiquette en petites capitales (« NIVEAU », « PARTIE »…).
class Etiquette extends StatelessWidget {
  const Etiquette(this.texte, {super.key, this.couleur});

  final String texte;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: Typo.capitales(14.5, couleur: couleur ?? context.couleurs.encreDouce),
      );
}

/// Pastille arrondie (« établie », « définition à relire »…).
class Pastille extends StatelessWidget {
  const Pastille(this.texte, {super.key, required this.couleur});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: couleur),
        ),
        child: Text(texte, style: Typo.capitales(12.5, couleur: couleur)),
      );
}
