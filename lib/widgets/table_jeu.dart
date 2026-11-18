import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/partie_controller.dart';
import '../models/etat_manche.dart';
import '../theme/couleurs.dart';
import '../theme/typo.dart';
import 'jeton_widget.dart';

/// Géométrie de la table : où se trouve chaque case du plateau et du chevalet.
///
/// Tout est calculé (rien n'est mesuré à l'écran) : c'est ce qui permet
/// d'animer les jetons d'une zone à l'autre et de savoir sous quel
/// emplacement se trouve le doigt pendant un glisser.
@immutable
class GeometrieTable {
  factory GeometrieTable(double largeur, int nombreDeJetons) {
    final n = math.max(1, nombreDeJetons);
    final etroit = largeur < 380;
    final marge = etroit ? 8.0 : 12.0;
    final ecart = etroit ? 4.0 : 6.0;
    final utile = largeur - 2 * marge;
    // Les mots longs tiennent sur une seule ligne tant que les jetons restent
    // assez grands pour le doigt ; en dessous, on les répartit sur deux
    // lignes (ou plus) de jetons plus confortables.
    double tailleSur(int parLigne) =>
        ((utile - ecart * (parLigne - 1)) / parLigne).floorToDouble();
    var lignes = 1;
    while (tailleSur((n / lignes).ceil()) < tailleMin && lignes < n) {
      lignes++;
    }
    final parLigne = (n / lignes).ceil();
    final taille = tailleSur(parLigne).clamp(tailleMin, tailleMax);
    final hauteurJeton = JetonWidget.hauteurPour(taille);
    final bloc = lignes * hauteurJeton + (lignes - 1) * ecart;
    final hautPlateau = bloc + 2 * _margePlateau;
    final hautChevalet = bloc + _hautChevalet + _basChevalet;
    return GeometrieTable._(
      largeur: largeur,
      marge: marge,
      ecart: ecart,
      taille: taille,
      hauteurJeton: hauteurJeton,
      parLigne: parLigne,
      plateau: Rect.fromLTWH(0, 0, largeur, hautPlateau),
      chevalet: Rect.fromLTWH(0, hautPlateau + _entreZones, largeur, hautChevalet),
    );
  }

  const GeometrieTable._({
    required this.largeur,
    required this.marge,
    required this.ecart,
    required this.taille,
    required this.hauteurJeton,
    required this.parLigne,
    required this.plateau,
    required this.chevalet,
  });

  /// Plus petit jeton encore facile à viser, et plus grand jeton utile.
  static const double tailleMin = 26;
  static const double tailleMax = 52;

  static const double _margePlateau = 12;
  static const double _hautChevalet = 12;
  static const double _basChevalet = 16;
  static const double _entreZones = 14;

  /// Épaisseur de la tranche du chevalet, sous sa face.
  static const double tranche = 6;

  final double largeur;
  final double marge;
  final double ecart;
  final double taille;
  final double hauteurJeton;
  final int parLigne;
  final Rect plateau;
  final Rect chevalet;

  double get hauteur => chevalet.bottom + tranche;

  double _hautDesJetons(Zone zone) => zone == Zone.plateau
      ? plateau.top + _margePlateau
      : chevalet.top + _hautChevalet;

  /// Coin haut-gauche du jeton n° [index] d'une zone qui en contient [nombre].
  Offset position(Zone zone, int index, int nombre) {
    final ligne = index ~/ parLigne;
    final colonne = index % parLigne;
    final surLaLigne = math.min(parLigne, nombre - ligne * parLigne);
    final largeurLigne = surLaLigne * taille + (surLaLigne - 1) * ecart;
    final x0 = (largeur - largeurLigne) / 2;
    return Offset(
      x0 + colonne * (taille + ecart),
      _hautDesJetons(zone) + ligne * (hauteurJeton + ecart),
    );
  }

  /// Zone survolée : tout ce qui est au-dessus du milieu va au plateau.
  Zone zoneSous(Offset point) =>
      point.dy < (plateau.bottom + chevalet.top) / 2 ? Zone.plateau : Zone.chevalet;

  /// Emplacement le plus proche du doigt dans une zone qui contiendra
  /// [nombre] jetons une fois le jeton déposé.
  int emplacementSous(Offset point, Zone zone, int nombre) {
    if (nombre <= 1) return 0;
    final lignes = (nombre / parLigne).ceil();
    final ligne = ((point.dy - _hautDesJetons(zone)) / (hauteurJeton + ecart))
        .floor()
        .clamp(0, lignes - 1);
    final debut = ligne * parLigne;
    final fin = math.min(nombre, debut + parLigne);
    var meilleur = debut;
    var distance = double.infinity;
    for (var i = debut; i < fin; i++) {
      final d = (position(zone, i, nombre).dx + taille / 2 - point.dx).abs();
      if (d < distance) {
        distance = d;
        meilleur = i;
      }
    }
    return meilleur;
  }
}

/// La table de jeu : le plateau (où l'on compose le mot) et le chevalet.
///
/// - Un appui sur un jeton l'envoie de l'autre côté.
/// - On peut aussi le faire glisser : les autres jetons s'écartent pour lui
///   faire place, et le mot est examiné au moment où on le lâche.
class TableJeu extends StatefulWidget {
  const TableJeu({super.key});

  @override
  State<TableJeu> createState() => _TableJeuState();
}

class _TableJeuState extends State<TableJeu> with SingleTickerProviderStateMixin {
  /// Distance à partir de laquelle un appui devient un glisser.
  static const double _seuilGlisser = 8;

  late final AnimationController _secousse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  int? _refusVus;

  // Glisser en cours.
  int? _pointeur;
  int? _jetonTenu;
  Offset _depart = Offset.zero;
  Offset _doigt = Offset.zero;
  Offset _prise = Offset.zero;
  bool _glisse = false;

  @override
  void dispose() {
    _secousse.dispose();
    super.dispose();
  }

  void _appui(PointerDownEvent e, PartieController partie, GeometrieTable g) {
    if (_pointeur != null) return;
    final p = e.localPosition;
    final tolerance = g.ecart / 2;
    for (final zone in Zone.values) {
      final jetons = zone == Zone.plateau ? partie.plateau : partie.chevalet;
      for (var i = 0; i < jetons.length; i++) {
        final coin = g.position(zone, i, jetons.length);
        final rect = (coin & Size(g.taille, g.hauteurJeton)).inflate(tolerance);
        if (rect.contains(p)) {
          _pointeur = e.pointer;
          _jetonTenu = jetons[i].id;
          _depart = p;
          _doigt = p;
          _prise = p - coin;
          _glisse = false;
          return;
        }
      }
    }
  }

  void _mouvement(PointerMoveEvent e, PartieController partie, GeometrieTable g) {
    if (e.pointer != _pointeur || _jetonTenu == null) return;
    final p = e.localPosition;
    if (!_glisse) {
      if ((p - _depart).distance < _seuilGlisser) return;
      _glisse = true;
      partie.saisirJeton(_jetonTenu!);
    }
    setState(() => _doigt = p);
    final id = _jetonTenu!;
    final zone = g.zoneSous(p);
    final jetons = zone == Zone.plateau ? partie.plateau : partie.chevalet;
    final dejaLa = jetons.any((j) => j.id == id);
    final nombre = jetons.length + (dejaLa ? 0 : 1);
    partie.deplacerJeton(id, zone, g.emplacementSous(p, zone, nombre));
  }

  void _relache(PointerEvent e, PartieController partie, {bool annule = false}) {
    if (e.pointer != _pointeur) return;
    final id = _jetonTenu;
    final glisse = _glisse;
    setState(() {
      _pointeur = null;
      _jetonTenu = null;
      _glisse = false;
    });
    if (id == null) return;
    if (glisse) {
      partie.relacherJeton(id);
    } else if (!annule) {
      partie.basculerJeton(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partie = context.watch<PartieController>();

    // Un nouveau refus : on secoue le plateau.
    if (_refusVus != null && partie.refus != _refusVus) {
      _secousse.forward(from: 0);
    }
    _refusVus = partie.refus;

    final enVol = _glisse ? _jetonTenu : null;

    return LayoutBuilder(
      builder: (context, contraintes) {
        final g = GeometrieTable(
          contraintes.maxWidth,
          partie.plateau.length + partie.chevalet.length,
        );

        final jetons = <({Jeton jeton, Zone zone, Offset position})>[
          for (var i = 0; i < partie.plateau.length; i++)
            (
              jeton: partie.plateau[i],
              zone: Zone.plateau,
              position: g.position(Zone.plateau, i, partie.plateau.length),
            ),
          for (var i = 0; i < partie.chevalet.length; i++)
            (
              jeton: partie.chevalet[i],
              zone: Zone.chevalet,
              position: g.position(Zone.chevalet, i, partie.chevalet.length),
            ),
        ]..sort((a, b) => a.jeton.id.compareTo(b.jeton.id));

        final tenu = enVol == null
            ? null
            : jetons.where((j) => j.jeton.id == enVol).firstOrNull;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _appui(e, partie, g),
          onPointerMove: (e) => _mouvement(e, partie, g),
          onPointerUp: (e) => _relache(e, partie),
          onPointerCancel: (e) => _relache(e, partie, annule: true),
          child: AnimatedBuilder(
            animation: _secousse,
            builder: (context, _) {
              final t = _secousse.value;
              final dx = _secousse.isAnimating
                  ? math.sin(t * math.pi * 4) * 7 * (1 - t)
                  : 0.0;
              return SizedBox(
                width: g.largeur,
                height: g.hauteur,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRect(
                      rect: g.plateau.shift(Offset(dx, 0)),
                      child: _Plateau(
                        etat: partie.etatPlateau,
                        vide: partie.plateau.isEmpty,
                      ),
                    ),
                    Positioned.fromRect(
                      rect: Rect.fromLTRB(
                        g.chevalet.left,
                        g.chevalet.top,
                        g.chevalet.right,
                        g.chevalet.bottom + GeometrieTable.tranche,
                      ),
                      child: const _Chevalet(),
                    ),
                    for (final j in jetons)
                      AnimatedPositioned(
                        key: ValueKey(j.jeton.id),
                        duration: const Duration(milliseconds: 190),
                        curve: Curves.easeOutCubic,
                        left: j.position.dx + (j.zone == Zone.plateau ? dx : 0),
                        top: j.position.dy,
                        child: Semantics(
                          button: true,
                          label: 'Jeton ${j.jeton.lettre}, '
                              '${j.zone == Zone.plateau ? 'sur le plateau' : 'sur le chevalet'}',
                          onTap: () => partie.basculerJeton(j.jeton.id),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 100),
                            opacity: j.jeton.id == enVol ? 0.25 : 1,
                            child: JetonWidget(lettre: j.jeton.lettre, taille: g.taille),
                          ),
                        ),
                      ),
                    if (tenu != null)
                      Positioned(
                        left: _doigt.dx - _prise.dx,
                        top: _doigt.dy - _prise.dy,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: -4 * math.pi / 180,
                            child: Transform.scale(
                              scale: 1.1,
                              child: JetonWidget(
                                lettre: tenu.jeton.lettre,
                                taille: g.taille,
                                enVol: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Zone de dépôt en pointillés où l'on compose le mot.
class _Plateau extends StatelessWidget {
  const _Plateau({required this.etat, required this.vide});

  final EtatPlateau etat;
  final bool vide;

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    final (Color bord, Color fond, bool plein) = switch (etat) {
      EtatPlateau.gagne => (c.ok, c.okPale, true),
      EtatPlateau.refuse => (c.non, c.feuille, false),
      EtatPlateau.neutre => (c.filet, c.feuille, false),
    };
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 180),
      tween: ColorTween(end: fond),
      builder: (context, couleurFond, _) => CustomPaint(
        painter: _BordPlateau(
          fond: couleurFond ?? fond,
          bord: bord,
          plein: plein,
          rayon: 12,
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: vide ? 1 : 0,
            child: Text(
              'Glisse les jetons ici',
              style: Typo.capitales(14, couleur: c.encreDouce),
            ),
          ),
        ),
      ),
    );
  }
}

class _BordPlateau extends CustomPainter {
  const _BordPlateau({
    required this.fond,
    required this.bord,
    required this.plein,
    required this.rayon,
  });

  final Color fond;
  final Color bord;
  final bool plein;
  final double rayon;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      Radius.circular(rayon),
    );
    canvas.drawRRect(rrect, Paint()..color = fond);
    final trait = Paint()
      ..color = bord
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (plein) {
      canvas.drawRRect(rrect, trait);
      return;
    }
    const tiret = 7.0, vide = 6.0;
    final chemin = Path()..addRRect(rrect);
    for (final PathMetric m in chemin.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + tiret, m.length)), trait);
        d += tiret + vide;
      }
    }
  }

  @override
  bool shouldRepaint(_BordPlateau ancien) =>
      ancien.fond != fond || ancien.bord != bord || ancien.plein != plein;
}

/// Le chevalet en bois sur lequel reposent les jetons.
class _Chevalet extends StatelessWidget {
  const _Chevalet();

  @override
  Widget build(BuildContext context) {
    final c = context.couleurs;
    const rayon = BorderRadius.vertical(
      top: Radius.circular(8),
      bottom: Radius.circular(16),
    );
    return Stack(
      children: [
        // Tranche du chevalet, visible sous sa face.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: c.chevaletOmbre, borderRadius: rayon),
          ),
        ),
        Positioned.fill(
          bottom: GeometrieTable.tranche,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: rayon,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.chevalet, c.chevalet, c.chevaletOmbre],
                stops: const [0, 0.7, 1],
              ),
            ),
          ),
        ),
        // Reflet sur l'arête supérieure.
        const Positioned(
          left: 8,
          right: 8,
          top: 0,
          height: 2,
          child: ColoredBox(color: Color(0x26FFFFFF)),
        ),
      ],
    );
  }
}
