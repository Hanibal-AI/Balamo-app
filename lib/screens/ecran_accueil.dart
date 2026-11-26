import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../logic/reglages_audio.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';
import '../widgets/boutons.dart';
import '../widgets/en_tete.dart';
import '../widgets/choix_niveau.dart';
import '../widgets/regles_feuille.dart';
import 'mise_en_page.dart';

/// Accueil : choix de la catégorie et du niveau.
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
          const ChoixNiveau(),
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
                    '${donnees.partie.length} mots à jouer',
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
