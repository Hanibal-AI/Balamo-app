import 'package:material_ui/material_ui.dart';

import '../models/donnees_jeu.dart';
import '../models/mot.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';
import 'boutons.dart';
import 'mini_markdown.dart';

/// La révélation : pour une orthographe, le sens de chaque mot qu'elle peut
/// être, puis son étymologie.
class Revelation extends StatelessWidget {
  const Revelation({
    super.key,
    required this.donnees,
    required this.orthographe,
    this.piege = false,
    this.avecFilet = true,
  });

  final DonneesJeu donnees;
  final String orthographe;

  /// Mot piège : on précise qu'il n'avait aucune anagramme.
  final bool piege;

  /// Filet d'encre au-dessus, pour séparer la révélation du jeu.
  final bool avecFilet;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final sens = donnees.sensDe(orthographe);
    return Container(
      padding: EdgeInsets.only(top: avecFilet ? 18 : 0),
      decoration: avecFilet
          ? BoxDecoration(border: Border(top: BorderSide(color: c.encre, width: 2)))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (piege)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                "Aucune anagramme. Voici l'histoire du mot.",
                style: Typo.texte(18, couleur: c.encreDouce, italique: true, hauteur: 1.35),
              ),
            ),
          if (sens.isEmpty)
            Text(
              "Ce mot n'a pas encore d'entrée dans le dictionnaire.",
              style: Typo.texte(18, couleur: c.encreDouce, italique: true, hauteur: 1.35),
            ),
          for (var i = 0; i < sens.length; i++) ...[
            if (i > 0) const SizedBox(height: 26),
            _Sens(sens: sens[i]),
          ],
        ],
      ),
    );
  }
}

class _Sens extends StatelessWidget {
  const _Sens({required this.sens});

  final SensRevele sens;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final mot = sens.mot;
    final rattachement = sens.formeDe != null
        ? 'forme de **${sens.formeDe}**${mot.nature.isEmpty ? '' : ', ${mot.nature}'}'
        : mot.nature;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sens.titre, style: Typo.titre(32, couleur: c.encre)),
        if (rattachement.isNotEmpty) ...[
          const SizedBox(height: 4),
          TexteMd(
            rattachement,
            enLigne: true,
            style: Typo.texte(17.5, couleur: c.encreDouce, italique: true, hauteur: 1.3),
          ),
        ],
        const SizedBox(height: 8),
        TexteMd(
          mot.definition,
          enLigne: true,
          style: Typo.texte(19.5, couleur: c.encre, hauteur: 1.45),
        ),
        if (mot.definitionARelire) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Pastille('définition à relire', couleur: c.non),
          ),
        ],
        const SizedBox(height: 18),
        _Etymologie(mot: mot),
      ],
    );
  }
}

class _Etymologie extends StatelessWidget {
  const _Etymologie({required this.mot});

  final Mot mot;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final fiche = mot.fiche;
    final corps = Typo.texte(18, couleur: c.encre);

    if (!mot.aEtymologie) {
      return Text(
        "Pas encore d'étymologie pour ce mot.",
        style: Typo.texte(18, couleur: c.encreDouce, italique: true, hauteur: 1.35),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _Intertitre('Étymologie'),
            if (mot.certitude != null) Pastille(mot.certitude!, couleur: c.violette),
          ],
        ),
        if (fiche.enUnePhrase.isNotEmpty) ...[
          const SizedBox(height: 10),
          TexteMd(fiche.enUnePhrase, style: Typo.texte(20.5, couleur: c.encre, hauteur: 1.42)),
        ],
        if (fiche.origine.isNotEmpty) ...[
          const SizedBox(height: 12),
          TexteMd(fiche.origine, style: corps),
        ],
        if (fiche.aRetenir.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _Intertitre('À retenir'),
          const SizedBox(height: 8),
          TexteMd(fiche.aRetenir, style: corps),
        ],
        for (final racine in mot.racines) ...[
          const SizedBox(height: 14),
          _CarteRacine(racine: racine),
        ],
        if (fiche.etapes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Depliant(
            titre: 'Le voyage du mot, en ${fiche.etapes.length} étape'
                '${fiche.etapes.length > 1 ? 's' : ''}',
            constructeur: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final etape in fiche.etapes)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: c.violettePale, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TexteMd(
                          etape.titre,
                          enLigne: true,
                          style: Typo.ui(16.5,
                              couleur: c.violette, graisse: FontWeight.w700, hauteur: 1.25),
                        ),
                        const SizedBox(height: 8),
                        TexteMd(etape.texte, style: corps),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (fiche.sources.isNotEmpty)
          Depliant(
            titre: 'Sources',
            constructeur: (context) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TexteMd(fiche.sources, style: Typo.ui(16, couleur: c.encre), espacement: 6),
            ),
          ),
      ],
    );
  }
}

class _Intertitre extends StatelessWidget {
  const _Intertitre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Text(
        texte,
        style: Typo.capitales(15,
            couleur: context.couleurs.violette, graisse: FontWeight.w700),
      );
}

class _CarteRacine extends StatelessWidget {
  const _CarteRacine({required this.racine});

  final Racine racine;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final base = Typo.ui(16.5, couleur: c.encre);
    final freres = racine.mots.isEmpty
        ? ''
        : ' Même racine que : ${racine.mots.join(', ')}.';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: c.feuille,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.filet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              style: base,
              children: [
                const TextSpan(text: 'Racine '),
                TextSpan(
                  text: racine.forme,
                  style: Typo.texte(19, couleur: c.violette, graisse: FontWeight.w700, hauteur: 1.2),
                ),
                TextSpan(text: ' : ${racine.sens}'),
                if (racine.certitude != null) ...[
                  const TextSpan(text: '  '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Pastille(racine.certitude!, couleur: c.violette),
                  ),
                ],
              ],
            ),
          ),
          if (racine.note.isNotEmpty || freres.isNotEmpty) ...[
            const SizedBox(height: 6),
            TexteMd('${racine.note}$freres'.trim(), enLigne: true, style: base),
          ],
        ],
      ),
    );
  }
}

/// Section repliable. Son contenu n'est construit qu'une fois ouverte : les
/// fiches étymologiques sont longues.
class Depliant extends StatefulWidget {
  const Depliant({super.key, required this.titre, required this.constructeur});

  final String titre;
  final WidgetBuilder constructeur;

  @override
  State<Depliant> createState() => _DepliantState();
}

class _DepliantState extends State<Depliant> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.filet))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _ouvert,
            child: InkWell(
              onTap: () => setState(() => _ouvert = !_ouvert),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.titre,
                        style: Typo.ui(17, couleur: c.encre, graisse: FontWeight.w700),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _ouvert ? 0.5 : 0,
                      child: Icon(Icons.expand_more, color: c.encreDouce),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _ouvert
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: widget.constructeur(context),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
