import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../models/donnees_jeu.dart';
import '../models/etat_manche.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';
import '../widgets/boutons.dart';
import '../widgets/en_tete.dart';
import '../widgets/revelation.dart';
import 'mise_en_page.dart';

/// Ouvre l'histoire d'un mot dans une feuille que l'on tire vers le haut.
Future<void> montrerHistoire(
  BuildContext context,
  DonneesJeu donnees,
  String orthographe,
) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 1,
        builder: (context, defilement) => SingleChildScrollView(
          controller: defilement,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 36),
          child: Revelation(
            donnees: donnees,
            orthographe: orthographe,
            avecFilet: false,
          ),
        ),
      ),
    );

/// Bilan de fin de partie : le total, le record, et le détail manche par manche.
class EcranBilan extends StatelessWidget {
  const EcranBilan({super.key});

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final c = context.couleurs;
    final journal = partie.journal;

    return PageBalamo(
      corps: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          EnTete(
            compact: true,
            compteurs: [Compteur(valeur: '${partie.record}', nom: 'record')],
          ),
          const SizedBox(height: 20),
          Etiquette(
            'Bilan · ${partie.niveau.libelle.toLowerCase()} · ${partie.totalManches} manches',
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${partie.score} point${partie.score > 1 ? 's' : ''}',
              style: Typo.titre(60, couleur: c.violette, hauteur: 1),
            ),
          ),
          const SizedBox(height: 10),
          if (partie.nouveauRecord)
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: c.violette, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nouveau record pour ce niveau et cette longueur de partie.',
                    style: Typo.ui(17, couleur: c.encre, graisse: FontWeight.w700),
                  ),
                ),
              ],
            )
          else
            Text(
              'Record à battre : ${partie.record} point${partie.record > 1 ? 's' : ''}.',
              style: Typo.ui(17, couleur: c.encre),
            ),
          const SizedBox(height: 22),
          const _LigneTitres(),
          for (var i = 0; i < journal.length; i++)
            _LigneManche(
              numero: i + 1,
              manche: journal[i],
              onTap: () => montrerHistoire(context, partie.donnees, journal[i].tuiles),
            ),
          const SizedBox(height: 12),
          Text(
            'Touche un mot pour relire son sens et son histoire.',
            style: Typo.ui(14.5, couleur: c.encreDouce),
          ),
        ],
      ),
      pied: Row(
        children: [
          Expanded(
            flex: 5,
            child: BoutonBalamo(
              libelle: 'Rejouer',
              style: StyleBouton.principal,
              icone: Icons.replay_rounded,
              hauteur: 56,
              onPressed: partie.commencerPartie,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: BoutonBalamo(
              libelle: 'Changer de niveau',
              hauteur: 56,
              dense: true,
              onPressed: partie.quitter,
            ),
          ),
        ],
      ),
    );
  }
}

const double _colNumero = 26;
const double _colPari = 76;
const double _colAnagrammes = 66;
const double _colPoints = 50;

class _LigneTitres extends StatelessWidget {
  const _LigneTitres();

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final style = Typo.capitales(13, couleur: c.encreDouce);
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.encre, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(width: _colNumero, child: Text('#', style: style)),
          Expanded(child: Text('Mot', style: style)),
          SizedBox(width: _colPari, child: Text('Pari', style: style)),
          SizedBox(width: _colAnagrammes, child: Text('Trouvées', style: style, maxLines: 1, softWrap: false, overflow: TextOverflow.visible)),
          SizedBox(
            width: _colPoints,
            child: Text('Points', style: style, textAlign: TextAlign.end, maxLines: 1, softWrap: false),
          ),
        ],
      ),
    );
  }
}

class _LigneManche extends StatelessWidget {
  const _LigneManche({required this.numero, required this.manche, required this.onTap});

  final int numero;
  final BilanManche manche;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final chiffres = Typo.ui(16, couleur: c.encre)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final juste = manche.pariJuste == true;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.filet)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _colNumero,
              child: Text('$numero', style: chiffres.copyWith(color: c.encreDouce)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    manche.lemme,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.titre(20, couleur: c.violette, graisse: FontWeight.w700).copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: c.violette.withValues(alpha: 0.45),
                    ),
                  ),
                  if (manche.indices > 0)
                    Text(
                      '${manche.indices} indice${manche.indices > 1 ? 's' : ''}',
                      style: Typo.ui(13, couleur: c.encreDouce, hauteur: 1.1),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: _colPari,
              child: Row(
                children: [
                  Icon(
                    juste ? Icons.check_rounded : Icons.close_rounded,
                    size: 17,
                    color: juste ? c.ok : c.non,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    juste ? 'juste' : 'raté',
                    style: chiffres.copyWith(color: juste ? c.ok : c.non),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _colAnagrammes,
              child: Text(
                manche.total > 0 ? '${manche.trouvees} / ${manche.total}' : 'piège',
                style: chiffres,
              ),
            ),
            SizedBox(
              width: _colPoints,
              child: Text(
                '${manche.points}'.replaceFirst('-', '−'),
                textAlign: TextAlign.end,
                style: chiffres.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
