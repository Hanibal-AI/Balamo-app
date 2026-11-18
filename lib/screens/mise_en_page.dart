import 'package:material_ui/material_ui.dart';

import '../theme/couleurs.dart';

/// Largeur maximale du contenu : sur tablette, la page reste une colonne.
const double largeurMaxPage = 620;

/// Gabarit commun aux écrans : un [corps] qui occupe la place disponible et
/// un [pied] fixé en bas, à portée de pouce, au-dessus des barres système.
class PageBalamo extends StatelessWidget {
  const PageBalamo({super.key, required this.corps, this.pied, this.entete});

  /// Bandeau fixe en haut (facultatif).
  final Widget? entete;
  final Widget corps;

  /// Zone d'action fixe en bas (facultative).
  final Widget? pied;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: largeurMaxPage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?entete,
                Expanded(child: corps),
                if (pied != null) PanneauBas(child: pied!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Panneau du bas de l'écran : la zone que le pouce atteint sans effort.
class PanneauBas extends StatelessWidget {
  const PanneauBas({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final bas = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.papier,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          // Liseré puis ombre douce : le panneau se détache de la page.
          BoxShadow(color: c.filet, offset: const Offset(0, -1)),
          BoxShadow(
            color: c.encre.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bas),
        child: child,
      ),
    );
  }
}
