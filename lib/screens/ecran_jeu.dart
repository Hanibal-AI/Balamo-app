import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../logic/regles.dart';
import '../models/etat_manche.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';
import '../widgets/boutons.dart';
import '../widgets/cases_anagrammes.dart';
import '../widgets/en_tete.dart';
import '../widgets/mini_markdown.dart';
import '../widgets/revelation.dart';
import '../widgets/table_jeu.dart';
import 'mise_en_page.dart';

/// Demande confirmation avant de quitter une partie en cours.
Future<void> demanderAQuitter(BuildContext context) async {
  final partie = context.read<PartieController>();
  final quitter = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Quitter la partie ?'),
      content: const Text('La partie en cours sera abandonnée.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Continuer à jouer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Quitter'),
        ),
      ],
    ),
  );
  if (quitter == true) partie.quitter();
}

/// L'écran de jeu : en haut la page de dictionnaire (le mot, puis sa
/// révélation), en bas le panneau d'action du moment — pari, table de jeu
/// ou passage au mot suivant.
class EcranJeu extends StatefulWidget {
  const EcranJeu({super.key});

  @override
  State<EcranJeu> createState() => _EcranJeuState();
}

class _EcranJeuState extends State<EcranJeu> {
  final ScrollController _defilement = ScrollController();
  final GlobalKey _cleRevelation = GlobalKey();
  int? _mancheVue;
  int? _revelationsVues;

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  /// Remonte en haut à chaque nouveau mot ; descend jusqu'à la révélation
  /// quand un mot vient d'être dévoilé.
  void _suivreLaPartie(PartieController partie) {
    if (_mancheVue != partie.manche) {
      _mancheVue = partie.manche;
      _revelationsVues = partie.revelations;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_defilement.hasClients) _defilement.jumpTo(0);
      });
      return;
    }
    if (_revelationsVues != partie.revelations) {
      _revelationsVues = partie.revelations;
      if (partie.revelationPiege) return; // le verdict doit rester visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final contexte = _cleRevelation.currentContext;
        if (contexte == null || !contexte.mounted) return;
        Scrollable.ensureVisible(
          contexte,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    if (!partie.aUneManche) return const SizedBox.shrink();
    _suivreLaPartie(partie);

    final c = context.couleurs;
    final mot = partie.donnees.motDe(partie.courant);
    final enPari = partie.phase == Phase.pari;
    final revelee = partie.orthographeRevelee;

    return PageBalamo(
      entete: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnTete(
              compact: true,
              debut: IconButton(
                onPressed: () => demanderAQuitter(context),
                icon: const Icon(Icons.close_rounded),
                color: c.encre,
                tooltip: 'Quitter la partie',
                visualDensity: VisualDensity.compact,
              ),
              compteurs: [
                Compteur(valeur: '${partie.manche}/${partie.totalManches}', nom: 'manche'),
                Compteur(valeur: '${partie.score}', nom: 'points', accent: true),
                Compteur(valeur: '${partie.record}', nom: 'record'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 10),
              child: BarreEtapes(etape: partie.etape),
            ),
          ],
        ),
      ),
      corps: SingleChildScrollView(
        controller: _defilement,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${partie.courant.tuiles.length} lettres',
              style: Typo.capitales(14, couleur: c.encreDouce),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              style: Typo.titre(enPari ? 52 : 36, couleur: c.encre, hauteur: 1.05),
              child: Text(mot?.lemme ?? partie.courant.note),
            ),
            if ((mot?.nature ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  mot!.nature,
                  style: Typo.texte(18.5, couleur: c.encreDouce, italique: true, hauteur: 1.3),
                ),
              ),
            if (partie.verdict != null) ...[
              const SizedBox(height: 16),
              _CarteVerdict(verdict: partie.verdict!),
            ],
            if (revelee != null) ...[
              const SizedBox(height: 22),
              Revelation(
                key: _cleRevelation,
                donnees: partie.donnees,
                orthographe: revelee,
                piege: partie.revelationPiege,
              ),
            ],
          ],
        ),
      ),
      pied: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: switch (partie.phase) {
          Phase.pari => const _PanneauPari(),
          Phase.recherche => const _PanneauRecherche(),
          Phase.terminee => const _PanneauSuite(),
        },
      ),
    );
  }
}

/// Résultat du pari : bandeau vert ou rouge.
class _CarteVerdict extends StatelessWidget {
  const _CarteVerdict({required this.verdict});

  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: verdict.juste ? c.okPale : c.nonPale,
          border: Border(
            left: BorderSide(color: verdict.juste ? c.ok : c.non, width: 5),
          ),
        ),
        child: TexteMd(
          verdict.texte,
          enLigne: true,
          style: Typo.ui(16.5, couleur: c.encre),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- 1 · le pari

class _PanneauPari extends StatelessWidget {
  const _PanneauPari();

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final c = context.couleurs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ce mot a-t-il au moins une anagramme ?',
          style: Typo.titre(22, couleur: c.encre, graisse: FontWeight.w700, hauteur: 1.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BoutonBalamo(
                libelle: 'Oui',
                selectionne: partie.pari == true,
                onPressed: () => partie.choisirPari(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BoutonBalamo(
                libelle: 'Non',
                selectionne: partie.pari == false,
                onPressed: () => partie.choisirPari(false),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !partie.demandeCombien
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Combien ?',
                        style: Typo.titre(20, couleur: c.encre, graisse: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var n = 1; n <= Regles.nombreMax; n++) ...[
                            if (n > 1) const SizedBox(width: 6),
                            Expanded(
                              child: BoutonBalamo(
                                libelle: n == Regles.nombreMax ? '$n+' : '$n',
                                dense: true,
                                hauteur: 48,
                                selectionne: partie.nombre == n,
                                onPressed: () => partie.choisirNombre(n),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 14),
        BoutonBalamo(
          libelle: 'Valider le pari',
          style: StyleBouton.principal,
          hauteur: 56,
          onPressed: partie.pariValidable ? partie.validerPari : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- 2 · la recherche

class _PanneauRecherche extends StatelessWidget {
  const _PanneauRecherche();

  Future<void> _voirLesReponses(BuildContext context) async {
    final partie = context.read<PartieController>();
    final reste = partie.courant.anagrammes.length - partie.trouvees.length;
    final abandon = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voir les réponses ?'),
        content: Text(
          'La recherche s\'arrête pour ce mot : '
          '${reste > 1 ? 'les $reste anagrammes restantes ne rapporteront' : "l'anagramme restante ne rapportera"} '
          'plus de points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chercher encore'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Voir les réponses'),
          ),
        ],
      ),
    );
    if (abandon == true) partie.abandonner();
  }

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final secondes = partie.secondesRestantes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const CasesAnagrammes(),
        const SizedBox(height: 8),
        Row(
          children: [
            if (secondes != null) ...[
              _Chrono(secondes: secondes, urgent: partie.chronoUrgent),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _Message(
                texte: partie.message,
                ton: partie.ton,
                alignement: secondes != null ? TextAlign.start : TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const TableJeu(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BoutonOutil(
                icone: Icons.shuffle_rounded,
                libelle: 'Mélanger',
                onPressed: partie.melanger,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BoutonOutil(
                icone: Icons.keyboard_double_arrow_down_rounded,
                libelle: 'Tout ramener',
                onPressed: partie.plateau.isEmpty ? null : partie.toutRamener,
              ),
            ),
            if (partie.indicePropose) ...[
              const SizedBox(width: 8),
              Expanded(
                child: BoutonOutil(
                  icone: Icons.lightbulb_outline_rounded,
                  libelle: 'Indice',
                  detail: '−${partie.coutIndice}',
                  attenue: !partie.indiceAbordable,
                  onPressed: partie.indicesEpuises ? null : partie.demanderIndice,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: BoutonOutil(
                icone: Icons.visibility_outlined,
                libelle: 'Réponses',
                onPressed: () => _voirLesReponses(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.texte,
    required this.ton,
    this.alignement = TextAlign.center,
  });

  final String texte;
  final TonMessage ton;
  final TextAlign alignement;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final couleur = switch (ton) {
      TonMessage.ok => c.ok,
      TonMessage.non => c.non,
      TonMessage.neutre => c.encre,
    };
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 42),
        child: Align(
          alignment: alignement == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Text(
              texte,
              key: ValueKey(texte),
              textAlign: alignement,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Typo.ui(16, couleur: couleur, graisse: FontWeight.w500, hauteur: 1.25),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chrono extends StatelessWidget {
  const _Chrono({required this.secondes, required this.urgent});

  final int secondes;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final couleur = urgent ? c.non : c.encre;
    final texte = '${secondes ~/ 60}:${(secondes % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: 'Temps restant : $secondes secondes',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: urgent ? c.nonPale : c.feuille,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: urgent ? c.non : c.filet, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 17, color: couleur),
            const SizedBox(width: 5),
            Text(texte, style: Typo.jeton(16, couleur: couleur)),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------- 3 · la révélation

class _PanneauSuite extends StatelessWidget {
  const _PanneauSuite();

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();
    final piege = partie.courant.estPiege;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!piege) ...[
          const CasesAnagrammes(),
          if (partie.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _Message(texte: partie.message, ton: partie.ton),
            )
          else
            const SizedBox(height: 12),
        ],
        BoutonBalamo(
          libelle: partie.derniereManche ? 'Voir le bilan' : 'Mot suivant',
          style: StyleBouton.principal,
          icone: Icons.arrow_forward_rounded,
          hauteur: 56,
          onPressed: partie.suivant,
        ),
      ],
    );
  }
}
