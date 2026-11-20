import 'package:material_ui/material_ui.dart';

import '../logic/regles.dart';
import '../models/niveau.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';

/// Ouvre la feuille « Règles et points ». Le barème affiché est lu dans
/// [Regles] : il reste juste quand on modifie les valeurs.
Future<void> montrerRegles(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _Regles(),
    );

class _Regles extends StatelessWidget {
  const _Regles();

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final corps = Typo.ui(16.5, couleur: c.encre, hauteur: 1.45);
    final multiplicateurs = Niveau.values
        .map((n) => '${n.multiplicateur} en ${n.libelle.toLowerCase()}')
        .join(', ');
    final avecCombien = Niveau.values
        .where((n) => n.demandeCombien)
        .map((n) => n.libelle.toLowerCase())
        .join(', ');

    final bareme = <(String, String)>[
      ('Bon pari oui / non', '+${Regles.pointsBonPari}'),
      ('Bon « non » sur un mot piège', '+${Regles.pointsBonPiege}'),
      ("Bon nombre d'anagrammes ($avecCombien)", '+${Regles.pointsBonNombre}'),
      ('Chaque anagramme trouvée', '+${Regles.pointsAnagramme}'),
      ('Toutes trouvées', '+${Regles.pointsToutesTrouvees}'),
      ('Chaque indice demandé', '−${Regles.coutIndice}'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Règles et points', style: Typo.titre(26, couleur: c.encre)),
          const SizedBox(height: 12),
          Text(
            'Une anagramme utilise toutes les lettres du mot. Les accents sont '
            'ignorés (règle / grêle). Les formes conjuguées et les pluriels comptent.',
            style: corps,
          ),
          const SizedBox(height: 12),
          Text('Barème de base, multiplié par $multiplicateurs :', style: corps),
          const SizedBox(height: 6),
          for (final (libelle, points) in bareme)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.filet)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(libelle, style: corps)),
                  const SizedBox(width: 12),
                  Text(
                    points,
                    style: Typo.jeton(15,
                        couleur: points.startsWith('−') ? c.non : c.violette),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'Un indice dévoile une lettre de plus de chaque anagramme restante. '
            "Il s'achète avec les points déjà gagnés : sans assez de points, pas d'indice.",
            style: corps,
          ),
          const SizedBox(height: 12),
          Text(
            "Astuce : touche un jeton pour l'envoyer sur le plateau ou le renvoyer "
            'au chevalet. Tu peux aussi le faire glisser pour le placer où tu veux.',
            style: corps.copyWith(color: c.encreDouce),
          ),
        ],
      ),
    );
  }
}
