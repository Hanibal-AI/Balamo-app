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

/// Regroupe les niveaux qui partagent une valeur : « ×1 aux niveaux 1 à 3, … ».
String _parValeur(String Function(Niveau) valeur) {
  final groupes = <String, List<int>>{};
  for (final n in Niveau.values) {
    groupes.putIfAbsent(valeur(n), () => []).add(n.numero);
  }
  return groupes.entries.map((g) {
    final niveaux = g.value.length > 1
        ? '${g.value.first} à ${g.value.last}'
        : '${g.value.first}';
    return '${g.key} ${g.value.length > 1 ? 'aux niveaux' : 'au niveau'} $niveaux';
  }).join(', ');
}

class _Regles extends StatelessWidget {
  const _Regles();

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final corps = Typo.ui(16.5, couleur: c.encre, hauteur: 1.45);
    final multiplicateurs = _parValeur((n) => '×${n.multiplicateur}');
    final prixIndices = _parValeur((n) => '${n.prixIndice} points');
    final chronos = Niveau.values
        .where((n) => n.aChrono)
        .map((n) => '${n.chronoSecondes} s au niveau ${n.numero}')
        .join(', ');
    final premierCombien =
        Niveau.values.firstWhere((n) => n.demandeCombien).numero;

    final bareme = <(String, String)>[
      ('Bon pari oui / non', '+${Regles.pointsBonPari}'),
      ('Bon « non » sur un mot piège', '+${Regles.pointsBonPiege}'),
      ("Bon nombre d'anagrammes (dès le niveau $premierCombien)",
          '+${Regles.pointsBonNombre}'),
      ('Chaque anagramme trouvée', '+${Regles.pointsAnagramme}'),
      ('Toutes trouvées', '+${Regles.pointsToutesTrouvees}'),
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
          Text('Barème de base, multiplié selon le niveau : $multiplicateurs.',
              style: corps),
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
            "Il s'achète avec les points déjà gagnés : sans assez de points, pas d'indice. "
            'Prix : $prixIndices. Leur nombre par mot diminue aux niveaux élevés.',
            style: corps,
          ),
          const SizedBox(height: 12),
          Text(
            'Compétition : la recherche de chaque mot est chronométrée ($chronos). '
            'Ton temps est affiché au bilan.',
            style: corps,
          ),
          const SizedBox(height: 12),
          Text(
            'Une partie compte ${Regles.motsParPartie} mots. Atteins '
            "l'objectif, une part du meilleur score possible sans indice, pour "
            'débloquer le niveau suivant.',
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
