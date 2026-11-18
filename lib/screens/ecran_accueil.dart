import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../logic/reglages_audio.dart';
import '../logic/regles.dart';
import '../models/niveau.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';
import '../widgets/boutons.dart';
import '../widgets/en_tete.dart';
import '../widgets/regles_feuille.dart';
import 'mise_en_page.dart';

/// Accueil : choix du niveau et de la longueur de partie.
class EcranAccueil extends StatelessWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final audio = context.watch<ReglagesAudio>();
    final c = context.couleurs;
    final donnees = partie.donnees;

    return PageBalamo(
      corps: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          EnTete(
            compteurs: [Compteur(valeur: '${partie.record}', nom: 'record')],
          ),
          const SizedBox(height: 18),
          Text(
            'Un mot du dictionnaire, trois temps : parie sur ses anagrammes, '
            "retrouve-les avec les jetons, puis découvre d'où vient chaque mot créé.",
            style: Typo.texte(19, couleur: c.encre, hauteur: 1.42),
          ),
          const SizedBox(height: 22),
          const Etiquette('Niveau'),
          const SizedBox(height: 10),
          for (final niveau in Niveau.values) ...[
            _CarteNiveau(
              niveau: niveau,
              selectionne: partie.niveau == niveau,
              mots: donnees.nombreDeMots(niveau),
              pieges: donnees.nombreDePieges(niveau),
              onTap: () => partie.choisirNiveau(niveau),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          const Etiquette('Partie'),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final total in Regles.longueursDePartie) ...[
                if (total != Regles.longueursDePartie.first) const SizedBox(width: 10),
                Expanded(
                  child: BoutonBalamo(
                    libelle: '$total manches',
                    selectionne: partie.totalManches == total,
                    onPressed: () => partie.choisirTotalManches(total),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          const Etiquette('Ambiance'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BoutonBalamo(
                  libelle: 'Sons',
                  icone: audio.sons
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  selectionne: audio.sons,
                  onPressed: audio.basculerSons,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BoutonBalamo(
                  libelle: 'Musique',
                  icone: audio.musique
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  selectionne: audio.musique,
                  onPressed: audio.basculerMusique,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.filet)),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => montrerRegles(context),
                  icon: const Icon(Icons.menu_book_outlined, size: 20),
                  label: const Text('Règles et points'),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '${donnees.partie.length} mots · données du ${donnees.genere}',
                    textAlign: TextAlign.end,
                    style: Typo.ui(13.5, couleur: c.encreDouce),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      pied: BoutonBalamo(
        libelle: 'Commencer la partie',
        style: StyleBouton.principal,
        icone: Icons.play_arrow_rounded,
        hauteur: 56,
        onPressed: partie.commencerPartie,
      ),
    );
  }
}

class _CarteNiveau extends StatelessWidget {
  const _CarteNiveau({
    required this.niveau,
    required this.selectionne,
    required this.mots,
    required this.pieges,
    required this.onTap,
  });

  final Niveau niveau;
  final bool selectionne;
  final int mots;
  final int pieges;
  final VoidCallback onTap;

  static const _vocabulaire = {
    Niveau.facile: 'Mots courts et courants',
    Niveau.intermediaire: 'Mots plus longs, plus de pièges',
    Niveau.expert: 'Mots longs ou rares, formes conjuguées',
  };

  List<String> get _lignes => [
        _vocabulaire[niveau]!,
        niveau.demandeCombien
            ? 'Pari oui / non, puis combien'
            : 'Pari oui / non seulement',
        if (niveau.aChrono)
          '${niveau.chronoSecondes} secondes pour chercher'
        else if (niveau.indiceDisponible)
          'Bouton indice (−${Regles.coutIndice * niveau.multiplicateur} points)'
        else
          'Sans indice',
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final rayon = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selectionne,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selectionne ? c.violettePale : c.feuille,
          borderRadius: rayon,
          border: Border.all(color: selectionne ? c.violette : c.filet, width: 2),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: rayon,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(niveau.libelle, style: Typo.titre(23, couleur: c.encre)),
                      ),
                      Text(
                        'points ×${niveau.multiplicateur}',
                        style: Typo.capitales(13.5, couleur: c.violette),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          selectionne
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          key: ValueKey(selectionne),
                          size: 22,
                          color: selectionne ? c.violette : c.filet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final ligne in _lignes)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '•  $ligne',
                        style: Typo.ui(15.5, couleur: c.encreDouce, hauteur: 1.3),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '$mots mots, dont $pieges piège${pieges > 1 ? 's' : ''}',
                    style: Typo.ui(14, couleur: c.encreDouce)
                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
