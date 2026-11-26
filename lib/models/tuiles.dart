/// Lettres accentuées et ligatures, ramenées à ce qui est écrit sur les jetons.
const _sansAccent = {
  'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ç': 'C', 'É': 'E', 'È': 'E', 'Ê': 'E',
  'Ë': 'E', 'Î': 'I', 'Ï': 'I', 'Ô': 'O', 'Ö': 'O', 'Ù': 'U', 'Û': 'U',
  'Ü': 'U', 'Ÿ': 'Y', 'Œ': 'OE', 'Æ': 'AE',
};

/// Les jetons d'un mot : capitales sans accents (« déjà » donne « DEJA »).
String enTuiles(String mot) =>
    mot.toUpperCase().split('').map((l) => _sansAccent[l] ?? l).join();
