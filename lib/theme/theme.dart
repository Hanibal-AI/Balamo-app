import 'package:material_ui/material_ui.dart';

import 'couleurs.dart';
import 'typo.dart';

/// Construit le thème Material 3 de Balamo à partir de la palette.
ThemeData themeBalamo(Brightness luminosite) {
  final c = luminosite == Brightness.dark
      ? CouleursBalamo.sombre
      : CouleursBalamo.clair;

  final schema = ColorScheme.fromSeed(
    seedColor: CouleursBalamo.clair.violette,
    brightness: luminosite,
  ).copyWith(
    primary: c.violette,
    onPrimary: c.feuille,
    primaryContainer: c.violettePale,
    onPrimaryContainer: c.encre,
    secondary: c.encre,
    onSecondary: c.papier,
    surface: c.papier,
    onSurface: c.encre,
    onSurfaceVariant: c.encreDouce,
    surfaceContainerLowest: c.feuille,
    surfaceContainerLow: c.feuille,
    surfaceContainer: c.feuille,
    surfaceContainerHigh: c.feuille,
    surfaceContainerHighest: c.feuille,
    outline: c.encreDouce,
    outlineVariant: c.filet,
    error: c.non,
    onError: c.feuille,
    errorContainer: c.nonPale,
    onErrorContainer: c.non,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: luminosite,
    colorScheme: schema,
    scaffoldBackgroundColor: c.papier,
    fontFamily: 'AlegreyaSans',
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: c.filet, thickness: 1, space: 1),
    textTheme: TextTheme(
      bodyLarge: Typo.ui(17, couleur: c.encre),
      bodyMedium: Typo.ui(16, couleur: c.encre),
      bodySmall: Typo.ui(14, couleur: c.encreDouce),
      titleLarge: Typo.titre(24, couleur: c.encre),
      labelLarge: Typo.ui(16, couleur: c.encre, graisse: FontWeight.w700),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.feuille,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: Typo.titre(22, couleur: c.encre),
      contentTextStyle: Typo.ui(16.5, couleur: c.encre),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.papier,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.filet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.violette,
        textStyle: Typo.ui(16, graisse: FontWeight.w700),
        minimumSize: const Size(48, 48),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.encre,
      contentTextStyle: Typo.ui(15.5, couleur: c.papier),
    ),
  );
}
