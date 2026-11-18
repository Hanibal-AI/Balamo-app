import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'logic/partie_controller.dart';
import 'logic/reglages_audio.dart';
import 'models/etat_manche.dart';
import 'screens/ecran_accueil.dart';
import 'screens/ecran_bilan.dart';
import 'screens/ecran_jeu.dart';
import 'theme/couleurs.dart';
import 'theme/theme.dart';
import 'theme/typo.dart';

/// Racine de l'application : thème clair/sombre et navigation entre les
/// trois écrans. L'écran affiché découle de l'état de la partie
/// ([PartieController.vue]) : il n'y a pas de pile de navigation à gérer.
class BalamoApp extends StatelessWidget {
  BalamoApp({super.key, required this.partie, ReglagesAudio? reglagesAudio})
      : reglagesAudio = reglagesAudio ?? ReglagesAudio.muets();

  final PartieController partie;

  /// Interrupteurs « Sons » et « Musique ». Muets par défaut (tests).
  final ReglagesAudio reglagesAudio;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PartieController>.value(value: partie),
        ChangeNotifierProvider<ReglagesAudio>.value(value: reglagesAudio),
      ],
      child: MaterialApp(
        title: 'Balamo',
        debugShowCheckedModeBanner: false,
        theme: themeBalamo(Brightness.light),
        darkTheme: themeBalamo(Brightness.dark),
        themeMode: ThemeMode.system,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, enfant) {
          // On respecte la taille de texte choisie dans les réglages du
          // téléphone, sans la laisser casser la table de jeu.
          return MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.25,
            child: _BarresSysteme(child: enfant!),
          );
        },
        home: const _Aiguillage(),
      ),
    );
  }
}

/// Assortit les icônes des barres système au thème.
class _BarresSysteme extends StatelessWidget {
  const _BarresSysteme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final icones = sombre ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icones,
        statusBarBrightness: sombre ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: icones,
      ),
      child: child,
    );
  }
}

/// Affiche l'écran correspondant à l'état de la partie et gère le bouton
/// « retour » d'Android.
class _Aiguillage extends StatelessWidget {
  const _Aiguillage();

  @override
  Widget build(BuildContext context) {
    final vue = context.select<PartieController, Vue>((p) => p.vue);
    return PopScope(
      canPop: vue == Vue.accueil,
      onPopInvokedWithResult: (sorti, _) {
        if (sorti) return;
        switch (vue) {
          case Vue.jeu:
            demanderAQuitter(context);
          case Vue.bilan:
            context.read<PartieController>().quitter();
          case Vue.accueil:
            break;
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(vue),
          child: switch (vue) {
            Vue.accueil => const EcranAccueil(),
            Vue.jeu => const EcranJeu(),
            Vue.bilan => const EcranBilan(),
          },
        ),
      ),
    );
  }
}

/// Écran d'attente pendant le chargement des données.
class EcranDemarrage extends StatelessWidget {
  const EcranDemarrage({super.key, this.erreur, this.onReessayer});

  final Object? erreur;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final sombre =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final c = sombre ? CouleursBalamo.sombre : CouleursBalamo.clair;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: c.papier,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Balamo', style: Typo.titre(46, couleur: c.encre)),
                const SizedBox(height: 8),
                Text(
                  erreur == null
                      ? 'Anagrammes & étymologie'
                      : 'Impossible de charger les mots.',
                  textAlign: TextAlign.center,
                  style: Typo.capitales(15, couleur: erreur == null ? c.encreDouce : c.non),
                ),
                if (erreur != null && onReessayer != null) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: onReessayer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.encre,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Réessayer',
                        style: Typo.ui(17, couleur: c.papier, graisse: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
