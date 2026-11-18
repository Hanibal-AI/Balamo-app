import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/couleurs.dart';

// ------------------------------------------------------------------ analyse
//
// Les fiches étymologiques sont écrites dans un markdown minimal : gras,
// italique, liens, listes à puces. Cette partie est du Dart pur (testable).

/// Un morceau de texte avec son style.
@immutable
class SegmentMd {
  const SegmentMd(this.texte, {this.gras = false, this.italique = false, this.lien});

  final String texte;
  final bool gras;
  final bool italique;
  final String? lien;
}

sealed class BlocMd {
  const BlocMd();
}

class ParagrapheMd extends BlocMd {
  const ParagrapheMd(this.segments);
  final List<SegmentMd> segments;
}

class ListeMd extends BlocMd {
  const ListeMd(this.elements);
  final List<List<SegmentMd>> elements;
}

const String _etoile = '\u0001';

final RegExp _lienOuEtoiles = RegExp(
  r'\[([^\]]+)\]\((https?:[^)\s]+)\)' // 1, 2 : lien
  r'|(\*+)', // 3 : suite d'étoiles
);

/// Analyse une ligne : `**gras**`, `*italique*`, `***les deux***`,
/// `[texte](https://…)`. Les styles peuvent s'imbriquer
/// (`***mot*, suite en gras**`) ; une étoile échappée (`\*`) ou isolée reste
/// une étoile.
List<SegmentMd> analyserEnLigne(String texte) {
  final segments = <SegmentMd>[];
  _analyser(texte.replaceAll(r'\*', _etoile), segments,
      gras: false, italique: false, lien: null);
  return segments;
}

enum _Style { gras, italique }

/// Un jeton de la ligne : du texte, un lien, ou une suite d'étoiles.
class _Jeton {
  _Jeton.texte(this.texte)
      : lien = null,
        etoiles = 0;
  _Jeton.lien(this.texte, this.lien) : etoiles = 0;
  _Jeton.etoiles(this.etoiles)
      : texte = '',
        lien = null;

  final String texte;
  final String? lien;
  final int etoiles;

  /// Ce que font ces étoiles, dans l'ordre : fermer puis ouvrir des styles.
  final List<_Style> ferme = [];
  final List<_Ouverture> ouvre = [];

  /// Étoiles qui ne balisent rien et s'affichent telles quelles.
  int litterales = 0;
}

class _Ouverture {
  _Ouverture(this.style);

  final _Style style;

  /// Vrai une fois la fermeture correspondante trouvée.
  bool fermee = false;

  int get largeur => style == _Style.gras ? 2 : 1;
}

void _analyser(
  String t,
  List<SegmentMd> sortie, {
  required bool gras,
  required bool italique,
  required String? lien,
}) {
  // 1. Découpage en texte, liens et suites d'étoiles.
  final jetons = <_Jeton>[];
  final bords = <(bool, bool)>[]; // (peut ouvrir, peut fermer), par jeton
  var curseur = 0;
  bool espace(int i) => i < 0 || i >= t.length || t[i].trim().isEmpty;
  for (final m in _lienOuEtoiles.allMatches(t)) {
    if (m.start > curseur) {
      jetons.add(_Jeton.texte(t.substring(curseur, m.start)));
      bords.add((false, false));
    }
    curseur = m.end;
    if (m.group(3) != null) {
      jetons.add(_Jeton.etoiles(m.group(3)!.length));
      bords.add((!espace(m.end), !espace(m.start - 1)));
    } else {
      jetons.add(_Jeton.lien(m.group(1)!, m.group(2)));
      bords.add((false, false));
    }
  }
  if (curseur < t.length) {
    jetons.add(_Jeton.texte(t.substring(curseur)));
    bords.add((false, false));
  }

  // 2. Appariement des étoiles ouvrantes et fermantes, avec une pile.
  final pile = <_Ouverture>[];
  for (var i = 0; i < jetons.length; i++) {
    final j = jetons[i];
    if (j.etoiles == 0) continue;
    final (peutOuvrir, peutFermer) = bords[i];
    var reste = j.etoiles;
    if (peutFermer) {
      while (reste > 0 && pile.isNotEmpty) {
        // « ***a** b* » : le gras se ferme avant l'italique ouvert avec lui.
        if (reste == 2 &&
            pile.length >= 2 &&
            pile.last.style == _Style.italique &&
            pile[pile.length - 2].style == _Style.gras) {
          final italiqueOuvert = pile.removeLast();
          pile.insert(pile.length - 1, italiqueOuvert);
        }
        final sommet = pile.last;
        if (sommet.largeur > reste) break;
        pile.removeLast();
        sommet.fermee = true;
        j.ferme.add(sommet.style);
        reste -= sommet.largeur;
      }
    }
    if (reste > 0 && peutOuvrir) {
      final styles = switch (reste) {
        1 => const [_Style.italique],
        2 => const [_Style.gras],
        _ => const [_Style.gras, _Style.italique],
      };
      for (final style in styles) {
        final ouverture = _Ouverture(style);
        j.ouvre.add(ouverture);
        pile.add(ouverture);
        reste -= ouverture.largeur;
      }
    }
    j.litterales = reste;
  }

  // 3. Émission des segments stylés.
  final tampon = StringBuffer();
  void vider() {
    if (tampon.isEmpty) return;
    sortie.add(SegmentMd(tampon.toString().replaceAll(_etoile, '*'),
        gras: gras, italique: italique, lien: lien));
    tampon.clear();
  }

  void basculer(_Style style, bool actif) {
    vider();
    if (style == _Style.gras) {
      gras = actif;
    } else {
      italique = actif;
    }
  }

  final grasInitial = gras, italiqueInitial = italique;
  for (final j in jetons) {
    if (j.lien != null) {
      vider();
      _analyser(j.texte, sortie, gras: gras, italique: italique, lien: j.lien);
    } else if (j.etoiles == 0) {
      tampon.write(j.texte);
    } else {
      for (final style in j.ferme) {
        basculer(style, style == _Style.gras ? grasInitial : italiqueInitial);
      }
      // Les étoiles sans rôle restent du texte, comme une ouverture jamais fermée.
      tampon.write('*' * j.litterales);
      for (final ouverture in j.ouvre) {
        if (ouverture.fermee) {
          basculer(ouverture.style, true);
        } else {
          tampon.write('*' * ouverture.largeur);
        }
      }
    }
  }
  vider();
}

final RegExp _puce = RegExp(r'^[-*•]\s+');

/// Découpe un texte en paragraphes et listes à puces.
List<BlocMd> analyserMarkdown(String texte) {
  final blocs = <BlocMd>[];
  final paragraphe = <String>[];
  List<List<SegmentMd>>? liste;

  void finParagraphe() {
    if (paragraphe.isEmpty) return;
    blocs.add(ParagrapheMd(analyserEnLigne(paragraphe.join(' '))));
    paragraphe.clear();
  }

  void finListe() {
    if (liste == null) return;
    blocs.add(ListeMd(liste!));
    liste = null;
  }

  for (final ligne in texte.split('\n')) {
    var s = ligne.trim();
    if (_puce.hasMatch(s)) {
      finParagraphe();
      (liste ??= []).add(analyserEnLigne(s.replaceFirst(_puce, '')));
    } else if (s.isEmpty) {
      finParagraphe();
      finListe();
    } else if (s.startsWith('![[')) {
      // Image de la base de notes d'origine : ignorée.
    } else {
      if (s.startsWith('>')) s = s.substring(1).trimLeft(); // citation
      finListe();
      if (s.isNotEmpty) paragraphe.add(s);
    }
  }
  finParagraphe();
  finListe();
  return blocs;
}

// ------------------------------------------------------------------ affichage

/// Ouvre un lien dans le navigateur du téléphone.
Future<void> ouvrirLien(BuildContext context, String url) async {
  final messager = ScaffoldMessenger.maybeOf(context);
  var ouvert = false;
  try {
    ouvert = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ouvert = false;
  }
  if (!ouvert) {
    messager?.showSnackBar(
      const SnackBar(content: Text("Impossible d'ouvrir ce lien.")),
    );
  }
}

/// Affiche un texte en mini-markdown.
///
/// Avec [enLigne], le texte est rendu comme un seul paragraphe (pas de listes).
class TexteMd extends StatefulWidget {
  const TexteMd(
    this.texte, {
    super.key,
    required this.style,
    this.enLigne = false,
    this.espacement = 10,
    this.alignement = TextAlign.start,
  });

  final String texte;
  final TextStyle style;
  final bool enLigne;

  /// Espace vertical entre deux blocs.
  final double espacement;
  final TextAlign alignement;

  @override
  State<TexteMd> createState() => _TexteMdState();
}

class _TexteMdState extends State<TexteMd> {
  late List<BlocMd> _blocs;
  final List<TapGestureRecognizer> _liens = [];

  @override
  void initState() {
    super.initState();
    _analyser();
  }

  @override
  void didUpdateWidget(TexteMd ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.texte != widget.texte || ancien.enLigne != widget.enLigne) {
      _analyser();
    }
  }

  void _analyser() {
    _blocs = widget.enLigne
        ? [ParagrapheMd(analyserEnLigne(widget.texte))]
        : analyserMarkdown(widget.texte);
  }

  void _libererLiens() {
    for (final l in _liens) {
      l.dispose();
    }
    _liens.clear();
  }

  @override
  void dispose() {
    _libererLiens();
    super.dispose();
  }

  TextSpan _span(List<SegmentMd> segments, Color couleurLien) => TextSpan(
        style: widget.style,
        children: [
          for (final s in segments)
            TextSpan(
              text: s.texte,
              style: TextStyle(
                fontWeight: s.gras ? FontWeight.w700 : null,
                fontVariations:
                    s.gras ? const [FontVariation('wght', 700)] : null,
                fontStyle: s.italique ? FontStyle.italic : null,
                color: s.lien != null ? couleurLien : null,
                decoration: s.lien != null ? TextDecoration.underline : null,
                decorationColor: s.lien != null ? couleurLien : null,
              ),
              recognizer: s.lien == null ? null : _reconnaisseur(s.lien!),
            ),
        ],
      );

  TapGestureRecognizer _reconnaisseur(String url) {
    final r = TapGestureRecognizer()..onTap = () => ouvrirLien(context, url);
    _liens.add(r);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    _libererLiens();
    final couleurLien = context.couleurs.violette;

    Widget paragraphe(List<SegmentMd> segments) =>
        Text.rich(_span(segments, couleurLien), textAlign: widget.alignement);

    if (_blocs.length == 1 && _blocs.first is ParagrapheMd) {
      return paragraphe((_blocs.first as ParagrapheMd).segments);
    }

    final enfants = <Widget>[];
    for (final bloc in _blocs) {
      if (enfants.isNotEmpty) enfants.add(SizedBox(height: widget.espacement));
      switch (bloc) {
        case ParagrapheMd(:final segments):
          enfants.add(paragraphe(segments));
        case ListeMd(:final elements):
          enfants.add(Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < elements.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('•', style: widget.style, textAlign: TextAlign.center),
                      ),
                      Expanded(child: paragraphe(elements[i])),
                    ],
                  ),
                ),
            ],
          ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: enfants,
    );
  }
}
