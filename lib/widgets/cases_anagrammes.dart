import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';

enum _TypeCase { attente, trouvee, depart, ratee }

/// Les anagrammes à trouver : une case par mot. Cachées au départ (avec les
/// lettres offertes par les indices), elles deviennent des boutons une fois
/// connues : on les touche pour relire le sens et l'étymologie du mot.
class CasesAnagrammes extends StatelessWidget {
  const CasesAnagrammes({super.key});

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final mot = partie.courant;
    final revelee = partie.orthographeRevelee;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (partie.finie)
          _Case(
            texte: mot.tuiles,
            type: _TypeCase.depart,
            active: revelee == mot.tuiles,
            description: 'Mot de départ ${mot.tuiles}',
            onTap: () => partie.reveler(mot.tuiles),
          ),
        for (final anagramme in mot.anagrammes)
          () {
            final trouvee = partie.trouvees.contains(anagramme);
            final connue = trouvee || partie.finie;
            return _Case(
              texte: partie.masque(anagramme),
              type: trouvee
                  ? _TypeCase.trouvee
                  : (partie.finie ? _TypeCase.ratee : _TypeCase.attente),
              active: connue && revelee == anagramme,
              description: trouvee
                  ? 'Anagramme trouvée $anagramme'
                  : (partie.finie
                      ? 'Anagramme manquée $anagramme'
                      : 'Anagramme à trouver, ${anagramme.length} lettres'),
              onTap: connue ? () => partie.reveler(anagramme) : null,
            );
          }(),
      ],
    );
  }
}

class _Case extends StatelessWidget {
  const _Case({
    required this.texte,
    required this.type,
    required this.active,
    required this.description,
    this.onTap,
  });

  final String texte;
  final _TypeCase type;

  /// Case dont le sens est affiché en ce moment.
  final bool active;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final (Color trait, Color fond) = switch (type) {
      _TypeCase.attente => (c.encreDouce, c.feuille),
      _TypeCase.trouvee => (c.ok, c.okPale),
      _TypeCase.depart => (c.violette, c.violettePale),
      _TypeCase.ratee => (c.non, c.nonPale),
    };
    final rayon = BorderRadius.circular(9);
    return Semantics(
      button: onTap != null,
      label: description,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: rayon,
          border: Border.all(
            color: type == _TypeCase.attente ? c.filet : trait,
            width: active ? 2.5 : 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: rayon,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 38),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(texte, style: Typo.jeton(15, couleur: trait, espacement: 2.2)),
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
