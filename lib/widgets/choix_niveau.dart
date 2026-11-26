import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../logic/regles.dart';
import '../models/niveau.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';

const _duree = Duration(milliseconds: 180);

/// Couleurs d'une catégorie : l'encre violette pour l'entraînement, le bois des
/// jetons pour la compétition.
({Color fond, Color trait, Color texte}) _teintes(
  CouleursBalamo c,
  Categorie categorie,
) =>
    switch (categorie) {
      Categorie.entrainement => (
          fond: c.violettePale,
          trait: c.violette,
          texte: c.encre,
        ),
      Categorie.competition => (
          fond: c.bois,
          trait: c.chevalet,
          texte: c.boisEncre,
        ),
    };

IconData _icone(Categorie categorie) => switch (categorie) {
      Categorie.entrainement => Icons.school_outlined,
      Categorie.competition => Icons.emoji_events_outlined,
    };

/// Le choix du niveau : deux carrés (entraînement, compétition), la barre des
/// dix niveaux, puis la fiche du niveau sélectionné.
class ChoixNiveau extends StatelessWidget {
  const ChoixNiveau({super.key});

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final categorie in Categorie.values) ...[
                if (categorie != Categorie.values.first) const SizedBox(width: 10),
                Expanded(child: _CarreCategorie(categorie: categorie)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _BarreNiveaux(),
        const SizedBox(height: 14),
        _FicheNiveau(niveau: partie.niveau),
      ],
    );
  }
}

class _CarreCategorie extends StatelessWidget {
  const _CarreCategorie({required this.categorie});

  final Categorie categorie;

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final c = context.couleurs;
    final teintes = _teintes(c, categorie);
    final niveaux = Niveau.values.where((n) => n.categorie == categorie);
    final accessible = niveaux.any(partie.estDebloque);
    final selectionne = partie.niveau.categorie == categorie;
    final texte = selectionne ? teintes.texte : c.encre;
    final rayon = BorderRadius.circular(18);

    return Semantics(
      button: true,
      enabled: accessible,
      selected: selectionne,
      child: AnimatedContainer(
        duration: _duree,
        // Presque carré sur un téléphone, plus bas sur un grand écran.
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: selectionne ? teintes.fond : c.feuille,
          borderRadius: rayon,
          border: Border.all(
            color: selectionne ? teintes.trait : c.filet,
            width: selectionne ? 3 : 2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: accessible ? () => partie.choisirCategorie(categorie) : null,
            borderRadius: rayon,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    accessible ? _icone(categorie) : Icons.lock_outline_rounded,
                    size: 38,
                    color: selectionne ? texte : teintes.trait,
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(categorie.libelle, style: Typo.titre(21, couleur: texte)),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      accessible
                          ? 'Niveaux ${niveaux.map((n) => n.numero).join(' · ')}'
                          : 'Dès le niveau ${niveaux.first.numero}',
                      style: Typo.ui(14, couleur: texte),
                    ),
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

/// Les dix niveaux côte à côte : la couleur et l'icône disent la catégorie,
/// les libellés du dessous le palier.
class _BarreNiveaux extends StatelessWidget {
  const _BarreNiveaux();

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final niveau in Niveau.values)
              Expanded(child: _CaseNiveau(niveau: niveau)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final palier in Palier.values)
              Expanded(
                flex: Niveau.values.where((n) => n.palier == palier).length,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.encreDouce)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      palier.libelle,
                      style: Typo.ui(13, couleur: c.encreDouce),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            for (final categorie in Categorie.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _teintes(c, categorie).fond,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _teintes(c, categorie).trait),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(_icone(categorie), size: 15, color: c.encreDouce),
                  const SizedBox(width: 4),
                  Text(categorie.libelle, style: Typo.ui(14, couleur: c.encreDouce)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _CaseNiveau extends StatelessWidget {
  const _CaseNiveau({required this.niveau});

  final Niveau niveau;

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final c = context.couleurs;
    final teintes = _teintes(c, niveau.categorie);
    final debloque = partie.estDebloque(niveau);
    final selectionne = partie.niveau == niveau;
    final rayon = BorderRadius.circular(8);

    return Semantics(
      button: true,
      enabled: debloque,
      selected: selectionne,
      label: 'Niveau ${niveau.numero}, ${niveau.famille}'
          '${debloque ? '' : ', verrouillé'}',
      excludeSemantics: true,
      onTap: debloque ? () => partie.choisirNiveau(niveau) : null,
      child: AnimatedOpacity(
        duration: _duree,
        opacity: debloque ? 1 : 0.5,
        child: AnimatedContainer(
          duration: _duree,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: teintes.fond,
            borderRadius: rayon,
            border: Border.all(
              color: selectionne ? c.encre : teintes.trait,
              width: selectionne ? 3 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: ValueKey('niveau-${niveau.numero}'),
              onTap: debloque ? () => partie.choisirNiveau(niveau) : null,
              borderRadius: rayon,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${niveau.numero}',
                      style: Typo.jeton(16, couleur: teintes.texte),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    debloque ? _icone(niveau.categorie) : Icons.lock_outline_rounded,
                    size: 14,
                    color: teintes.texte,
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

/// Ce qui attend le joueur au niveau sélectionné.
class _FicheNiveau extends StatelessWidget {
  const _FicheNiveau({required this.niveau});

  final Niveau niveau;

  List<String> _lignes(Iterable<int> longueurs) {
    final min = longueurs.reduce((a, b) => a < b ? a : b);
    final max = longueurs.reduce((a, b) => a > b ? a : b);
    final pieges = niveau.pieges;
    final indices = niveau.indicesMax;
    return [
      '${Regles.motsParPartie} mots de ${min == max ? '$min' : '$min à $max'} lettres, '
          '${pieges == 0 ? 'sans piège' : 'dont $pieges piège${pieges > 1 ? 's' : ''}'}',
      niveau.demandeCombien
          ? 'Pari oui / non, puis combien'
          : 'Pari oui / non seulement',
      if (niveau.aChrono)
        '${niveau.chronoSecondes} secondes par mot, temps mesuré'
      else
        'Sans chrono',
      indices == null
          ? 'Indices à ${niveau.prixIndice} points'
          : '$indices indice${indices > 1 ? 's' : ''} par mot, à ${niveau.prixIndice} points',
      if (niveau != Niveau.values.last)
        'Niveau suivant : ${niveau.objectifPourcent} % du meilleur score',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final c = context.couleurs;
    final longueurs = partie.donnees.lot(niveau).map((m) => m.tuiles.length);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.feuille,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teintes(c, niveau.categorie).trait, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Niveau ${niveau.numero} · ${niveau.famille}',
                  style: Typo.capitales(13.5, couleur: c.encreDouce),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'points ×${niveau.multiplicateur}',
                style: Typo.capitales(13.5, couleur: c.violette),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(niveau.titre, style: Typo.titre(23, couleur: c.encre)),
          const SizedBox(height: 6),
          if (longueurs.isNotEmpty)
            for (final ligne in _lignes(longueurs))
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '•  $ligne',
                  style: Typo.ui(15.5, couleur: c.encreDouce, hauteur: 1.3),
                ),
              ),
        ],
      ),
    );
  }
}
