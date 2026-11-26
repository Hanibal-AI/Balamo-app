import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/donnees_jeu.dart';
import '../models/etat_manche.dart';
import '../models/niveau.dart';
import '../services/stockage.dart';
import 'regles.dart';
import 'tirage.dart';

/// Ce qui vient de se passer dans le jeu, du point de vue des sens.
///
/// Le contrôleur se contente de signaler ces événements ; c'est l'application
/// qui les traduit en sons (`lib/services/audio_balamo.dart`) et en vibrations
/// (`lib/main.dart`).
enum Retour {
  /// Une option choisie : niveau, longueur de partie, oui / non, nombre.
  choix,

  /// Un bouton sans conséquence sur le score (revoir un mot…).
  bouton,
  debutDePartie,
  pariJuste,
  pariRate,

  /// Un jeton soulevé pour être glissé.
  jetonSaisi,

  /// Un jeton arrive sur le plateau.
  jetonPose,

  /// Un jeton retourne au chevalet.
  jetonRepris,
  melange,
  toutRamene,
  indice,
  indiceRefuse,
  motTrouve,
  toutesTrouvees,
  motRefuse,

  /// Mot de départ ou anagramme déjà trouvée : ni bien ni mal.
  motNeutre,

  /// Une des dernières secondes du chrono.
  tic,
  tempsEcoule,

  /// « Voir les réponses ».
  reponses,
  motSuivant,
  bilan,
  nouveauRecord,
  quitter,
}

/// Toute la logique d'une partie de Balamo.
///
/// L'interface ne fait que lire cet état et appeler ses méthodes ; elle est
/// prévenue de chaque changement par [notifyListeners]. Aucun widget ici :
/// le contrôleur se teste sans écran (voir `test/partie_controller_test.dart`).
class PartieController extends ChangeNotifier {
  PartieController({
    required this.donnees,
    required Stockage stockage,
    Random? hasard,
    DateTime Function()? horloge,
  })  : _stockage = stockage,
        _hasard = hasard ?? Random(),
        _horloge = horloge ?? DateTime.now {
    _niveauDebloque = stockage.niveauDebloque;
    final dernier = stockage.dernierNiveau ?? Niveau.n1;
    _niveau = estDebloque(dernier) ? dernier : Niveau.n1;
    _record = _stockage.lireRecord(_niveau);
  }

  final DonneesJeu donnees;
  final Stockage _stockage;
  final Random _hasard;
  final DateTime Function() _horloge;

  /// Branché par l'application pour déclencher les vibrations.
  void Function(Retour retour)? surRetour;

  // ---------------------------------------------------------------- réglages

  late Niveau _niveau;
  late int _niveauDebloque;

  Niveau get niveau => _niveau;
  int get totalManches => Regles.motsParPartie;

  /// Le joueur a-t-il accès à ce niveau ?
  bool estDebloque(Niveau niveau) => niveau.numero <= _niveauDebloque;

  void choisirNiveau(Niveau niveau) {
    if (_niveau == niveau || !estDebloque(niveau)) return;
    _niveau = niveau;
    surRetour?.call(Retour.choix);
    _record = _stockage.lireRecord(_niveau);
    unawaited(_stockage.memoriserNiveau(_niveau));
    notifyListeners();
  }

  /// Choisit le plus haut niveau accessible d'une catégorie.
  void choisirCategorie(Categorie categorie) {
    if (_niveau.categorie == categorie) return;
    final accessibles = Niveau.values
        .where((n) => n.categorie == categorie && estDebloque(n));
    if (accessibles.isNotEmpty) choisirNiveau(accessibles.last);
  }

  // ------------------------------------------------------------------- partie

  Vue _vue = Vue.accueil;
  int _score = 0;
  int _manche = 0;
  int _record = 0;
  int _recordAvantPartie = 0;
  int _objectif = 0;
  Niveau? _niveauGagne;
  List<EntreePartie> _pioche = [];
  List<BilanManche> _journal = [];

  Vue get vue => _vue;
  int get score => _score;
  int get manche => _manche;

  /// Meilleur score atteint pour ce niveau.
  int get record => _record;

  /// Record à battre au début de la partie en cours.
  int get recordAvantPartie => _recordAvantPartie;
  bool get nouveauRecord => _record > _recordAvantPartie;

  /// Score à atteindre pour débloquer le niveau suivant, calculé sur les mots
  /// réellement tirés.
  int get objectif => _objectif;
  bool get objectifAtteint => _score >= _objectif;

  /// Niveau débloqué par la partie qui vient de se terminer, s'il y en a un.
  Niveau? get niveauGagne => _niveauGagne;

  /// Temps de recherche cumulé de la partie (niveaux de compétition).
  Duration get tempsTotal => _journal.fold(
      Duration.zero, (total, m) => total + (m.duree ?? Duration.zero));
  List<BilanManche> get journal => List.unmodifiable(_journal);
  bool get derniereManche => _manche >= totalManches;

  // ------------------------------------------------------------------- manche

  EntreePartie? _courant;
  Phase _phase = Phase.pari;
  bool? _pari;
  int? _nombre;
  Verdict? _verdict;
  List<String> _trouvees = [];
  int _indices = 0;
  List<Jeton> _plateau = [];
  List<Jeton> _chevalet = [];
  String _message = '';
  TonMessage _ton = TonMessage.neutre;
  EtatPlateau _etatPlateau = EtatPlateau.neutre;
  int _refus = 0;
  String? _orthographeRevelee;
  bool _revelationPiege = false;
  int _revelations = 0;

  /// Le mot de la manche en cours.
  EntreePartie get courant => _courant!;
  bool get aUneManche => _courant != null;
  Phase get phase => _phase;
  bool get finie => _phase == Phase.terminee;

  /// Étape affichée dans le fil d'Ariane : 1 pari, 2 recherche, 3 révélation.
  int get etape => switch (_phase) {
        Phase.pari => 1,
        Phase.recherche => 2,
        Phase.terminee => 3,
      };

  bool? get pari => _pari;
  int? get nombre => _nombre;
  bool get demandeCombien => _niveau.demandeCombien && _pari == true;
  bool get pariValidable =>
      _pari == false ||
      (_pari == true && (!_niveau.demandeCombien || _nombre != null));
  Verdict? get verdict => _verdict;

  List<String> get trouvees => List.unmodifiable(_trouvees);
  int get indices => _indices;
  List<Jeton> get plateau => List.unmodifiable(_plateau);
  List<Jeton> get chevalet => List.unmodifiable(_chevalet);
  String get message => _message;
  TonMessage get ton => _ton;
  EtatPlateau get etatPlateau => _etatPlateau;

  /// Incrémenté à chaque mot refusé : l'interface rejoue l'animation de refus.
  int get refus => _refus;

  /// Orthographe dont on affiche le sens et l'étymologie.
  String? get orthographeRevelee => _orthographeRevelee;

  /// Vrai quand on révèle l'histoire d'un mot piège.
  bool get revelationPiege => _revelationPiege;

  /// Incrémenté à chaque révélation : l'interface fait défiler jusqu'à elle.
  int get revelations => _revelations;

  // ------------------------------------------------------------- déroulement

  void commencerPartie() {
    _annulerMinuteries();
    _pioche = composerPioche(
      lot: donnees.lot(_niveau),
      niveau: _niveau,
      hasard: _hasard,
    );
    _objectif = _calculerObjectif();
    _niveauGagne = null;
    _score = 0;
    _manche = 0;
    _journal = [];
    _record = _stockage.lireRecord(_niveau);
    _recordAvantPartie = _record;
    _vue = Vue.jeu;
    surRetour?.call(Retour.debutDePartie);
    _nouvelleManche();
  }

  int _calculerObjectif() {
    final base = _pioche.fold(
      0,
      (total, mot) =>
          total +
          Regles.pointsMaximum(mot.anagrammes.length,
              demandeCombien: _niveau.demandeCombien),
    );
    return (base * _niveau.multiplicateur * _niveau.objectifPourcent / 100)
        .ceil();
  }

  void _debloquerLeSuivant() {
    if (!objectifAtteint || _niveau.numero >= Niveau.values.length) return;
    final suivant = Niveau.depuisNumero(_niveau.numero + 1);
    if (estDebloque(suivant)) return;
    _niveauDebloque = suivant.numero;
    _niveauGagne = suivant;
    unawaited(_stockage.ecrireNiveauDebloque(_niveauDebloque));
  }

  void _nouvelleManche() {
    _annulerMinuteries();
    final mot = _pioche.removeLast();
    _courant = mot;
    _manche += 1;
    _phase = Phase.pari;
    _pari = null;
    _nombre = null;
    _verdict = null;
    _trouvees = [];
    _indices = 0;
    _plateau = [];
    _chevalet = [];
    _message = '';
    _ton = TonMessage.neutre;
    _etatPlateau = EtatPlateau.neutre;
    _orthographeRevelee = null;
    _revelationPiege = false;
    _journal.add(BilanManche(
      lemme: mot.forme,
      tuiles: mot.tuiles,
      total: mot.anagrammes.length,
    ));
    notifyListeners();
  }

  /// Passe au mot suivant, ou au bilan après la dernière manche.
  void suivant() {
    if (!finie) return;
    if (derniereManche) {
      _annulerMinuteries();
      _debloquerLeSuivant();
      _vue = Vue.bilan;
      surRetour?.call(nouveauRecord ? Retour.nouveauRecord : Retour.bilan);
      notifyListeners();
    } else {
      surRetour?.call(Retour.motSuivant);
      _nouvelleManche();
    }
  }

  void quitter() {
    _annulerMinuteries();
    surRetour?.call(_vue == Vue.jeu ? Retour.quitter : Retour.bouton);
    _vue = Vue.accueil;
    _record = _stockage.lireRecord(_niveau);
    notifyListeners();
  }

  // --------------------------------------------------------------------- pari

  void choisirPari(bool aDesAnagrammes) {
    if (_phase != Phase.pari) return;
    _pari = aDesAnagrammes;
    if (!aDesAnagrammes) _nombre = null;
    surRetour?.call(Retour.choix);
    notifyListeners();
  }

  void choisirNombre(int nombre) {
    if (_phase != Phase.pari) return;
    _nombre = nombre.clamp(1, Regles.nombreMax);
    surRetour?.call(Retour.choix);
    notifyListeners();
  }

  void validerPari() {
    if (_phase != Phase.pari || !pariValidable) return;
    final total = courant.anagrammes.length;
    final aDesAnagrammes = total > 0;
    final k = _niveau.multiplicateur;
    final juste = _pari == aDesAnagrammes;
    final texte = <String>[];
    var gain = 0;

    _journal.last.pariJuste = juste;
    if (juste) {
      final p = aDesAnagrammes ? Regles.pointsBonPari : Regles.pointsBonPiege;
      gain += p;
      texte.add(aDesAnagrammes
          ? 'Bon pari : ce mot a bien des anagrammes. **+${p * k}**'
          : "Bien vu, c'était un piège : aucune anagramme. **+${p * k}**");
      if (aDesAnagrammes && _niveau.demandeCombien) {
        if (Regles.nombreJuste(_nombre, total)) {
          gain += Regles.pointsBonNombre;
          texte.add('Et le bon nombre ! **+${Regles.pointsBonNombre * k}**');
        } else {
          texte.add("Le nombre n'était pas le bon.");
        }
      }
    } else {
      texte.add(aDesAnagrammes
          ? 'Raté : ce mot a $total anagramme${total > 1 ? 's' : ''}.'
          : "Raté : ce mot n'a aucune anagramme.");
    }
    if (aDesAnagrammes) {
      texte.add('À toi de ${total > 1 ? 'les' : 'la'} trouver : $total à dénicher.');
    }
    _ajoute(gain);
    _verdict = Verdict(juste: juste, texte: texte.join(' '));
    surRetour?.call(juste ? Retour.pariJuste : Retour.pariRate);

    if (aDesAnagrammes) {
      _commencerRecherche();
    } else {
      _phase = Phase.terminee;
      _reveler(courant.tuiles, piege: true);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- recherche

  void _commencerRecherche() {
    _phase = Phase.recherche;
    _message = '';
    _ton = TonMessage.neutre;
    _etatPlateau = EtatPlateau.neutre;
    final lettres = melangerLettres(courant.tuiles, _hasard);
    _plateau = [];
    _chevalet = [
      for (var i = 0; i < lettres.length; i++) Jeton(id: i, lettre: lettres[i]),
    ];
    if (_niveau.aChrono) {
      _debutRecherche = _horloge();
      _lancerChrono(_niveau.chronoSecondes);
    }
  }

  /// Un appui sur un jeton l'envoie sur le plateau, ou le renvoie au chevalet.
  void basculerJeton(int id) {
    if (_phase != Phase.recherche) return;
    final surPlateau = _plateau.any((j) => j.id == id);
    final depuis = surPlateau ? _plateau : _chevalet;
    final vers = surPlateau ? _chevalet : _plateau;
    final i = depuis.indexWhere((j) => j.id == id);
    if (i < 0) return;
    vers.add(depuis.removeAt(i));
    surRetour?.call(surPlateau ? Retour.jetonRepris : Retour.jetonPose);
    _apresCoup();
    notifyListeners();
  }

  /// Pendant un glisser : place le jeton à [index] dans [zone], sans valider.
  void deplacerJeton(int id, Zone zone, int index) {
    if (_phase != Phase.recherche) return;
    final cible = zone == Zone.plateau ? _plateau : _chevalet;
    final actuel = cible.indexWhere((j) => j.id == id);
    Jeton jeton;
    if (actuel >= 0) {
      final i = index.clamp(0, cible.length - 1);
      if (i == actuel) return;
      jeton = cible.removeAt(actuel);
      cible.insert(i, jeton);
    } else {
      final source = zone == Zone.plateau ? _chevalet : _plateau;
      final i = source.indexWhere((j) => j.id == id);
      if (i < 0) return;
      jeton = source.removeAt(i);
      cible.insert(index.clamp(0, cible.length), jeton);
    }
    notifyListeners();
  }

  /// Début d'un glisser : le jeton quitte sa place sous le doigt.
  void saisirJeton(int id) {
    if (_phase != Phase.recherche) return;
    surRetour?.call(Retour.jetonSaisi);
  }

  /// Fin d'un glisser : le jeton [id] est lâché, le mot posé est examiné.
  void relacherJeton(int id) {
    if (_phase != Phase.recherche) return;
    final surPlateau = _plateau.any((j) => j.id == id);
    surRetour?.call(surPlateau ? Retour.jetonPose : Retour.jetonRepris);
    _apresCoup();
    notifyListeners();
  }

  void melanger() {
    if (_phase != Phase.recherche) return;
    _chevalet.shuffle(_hasard);
    surRetour?.call(Retour.melange);
    notifyListeners();
  }

  void toutRamener() {
    if (_phase != Phase.recherche) return;
    if (_plateau.isNotEmpty) surRetour?.call(Retour.toutRamene);
    _ramener();
    _apresCoup();
    notifyListeners();
  }

  void _ramener() {
    _chevalet.addAll(_plateau);
    _plateau.clear();
  }

  String get motPose => _plateau.map((j) => j.lettre).join();

  void _apresCoup() {
    _retourJetons?.cancel();
    _etatPlateau = EtatPlateau.neutre;
    if (_plateau.length != courant.tuiles.length || finie) {
      _message = '';
      _ton = TonMessage.neutre;
      return;
    }
    final mot = motPose;
    final k = _niveau.multiplicateur;
    if (mot == courant.tuiles) {
      _dire("C'est le mot de départ. Cherche un autre ordre.");
      surRetour?.call(Retour.motNeutre);
      return;
    }
    if (_trouvees.contains(mot)) {
      _dire('$mot : déjà trouvée.');
      surRetour?.call(Retour.motNeutre);
      return;
    }
    if (courant.anagrammes.contains(mot)) {
      _trouvees.add(mot);
      _ajoute(Regles.pointsAnagramme);
      _journal.last.trouvees = _trouvees.length;
      _dire('$mot ! +${Regles.pointsAnagramme * k}', TonMessage.ok);
      _etatPlateau = EtatPlateau.gagne;
      _reveler(mot);
      if (_trouvees.length == courant.anagrammes.length) {
        _ajoute(Regles.pointsToutesTrouvees);
        _message += ' Toutes trouvées : +${Regles.pointsToutesTrouvees * k}';
        _terminer();
        surRetour?.call(Retour.toutesTrouvees);
      } else {
        surRetour?.call(Retour.motTrouve);
        _retourJetons = Timer(Regles.delaiRetourJetons, () {
          if (finie) return;
          _etatPlateau = EtatPlateau.neutre;
          _ramener();
          notifyListeners();
        });
      }
      return;
    }
    _dire('$mot ne fait pas partie des anagrammes connues.', TonMessage.non);
    _etatPlateau = EtatPlateau.refuse;
    _refus += 1;
    surRetour?.call(Retour.motRefuse);
  }

  void _dire(String message, [TonMessage ton = TonMessage.neutre]) {
    _message = message;
    _ton = ton;
  }

  // ------------------------------------------------------------------ indices

  /// Coût d'un indice pour le niveau en cours.
  int get coutIndice => _niveau.prixIndice;

  /// Le bouton « Indice » est-il proposé ?
  bool get indicePropose => _phase == Phase.recherche;

  /// Plus d'indice pour ce mot : le quota du niveau est atteint, ou il ne
  /// reste que la dernière lettre, toujours cachée.
  bool get indicesEpuises {
    if (!aUneManche) return false;
    final lettres = courant.tuiles.length - 1;
    return _indices >= min(_niveau.indicesMax ?? lettres, lettres);
  }

  bool get indiceAbordable => _score >= coutIndice;

  /// Dévoile une lettre de plus de chaque anagramme restante, contre des
  /// points. Un indice s'achète : sans assez de points, pas d'indice.
  void demanderIndice() {
    if (!indicePropose || indicesEpuises) return;
    final cout = coutIndice;
    if (!indiceAbordable) {
      _dire('Il te faut $cout points pour un indice.', TonMessage.non);
      surRetour?.call(Retour.indiceRefuse);
      notifyListeners();
      return;
    }
    _indices += 1;
    _score -= cout;
    _journal.last
      ..indices += 1
      ..points -= cout;
    _dire('Indice : une lettre de plus. −$cout points');
    surRetour?.call(Retour.indice);
    notifyListeners();
  }

  /// Ce qu'on affiche dans la case d'une anagramme : le mot s'il est connu,
  /// sinon les lettres déjà dévoilées suivies de points.
  String masque(String anagramme) {
    if (finie || _trouvees.contains(anagramme)) return anagramme;
    final n = min(_indices, anagramme.length);
    return anagramme.substring(0, n) + '·' * (anagramme.length - n);
  }

  // --------------------------------------------------------------- fin, chrono

  /// « Voir les réponses » : la recherche s'arrête, tout est dévoilé.
  void abandonner([String prefixe = '']) {
    if (_phase != Phase.recherche) return;
    if (prefixe.isEmpty) surRetour?.call(Retour.reponses);
    _terminer();
    _dire('${prefixe}Touche une réponse pour lire son sens et son étymologie.');
    final reste = courant.anagrammes.where((a) => !_trouvees.contains(a));
    if (reste.isNotEmpty) _reveler(reste.first);
    notifyListeners();
  }

  void _terminer() {
    _mesurerLaDuree();
    _phase = Phase.terminee;
    _etatPlateau = EtatPlateau.neutre;
    _annulerMinuteries();
  }

  void _mesurerLaDuree() {
    final debut = _debutRecherche;
    if (debut == null) return;
    final ecoule = _horloge().difference(debut);
    final limite = Duration(seconds: _niveau.chronoSecondes);
    _journal.last.duree = ecoule > limite ? limite : ecoule;
    _debutRecherche = null;
  }

  DateTime? _debutRecherche;
  Timer? _minuteur;
  Timer? _retourJetons;
  DateTime? _finChrono;
  int? _secondesAffichees;

  /// Secondes restantes au chrono (`null` s'il ne tourne pas).
  int? get secondesRestantes {
    final fin = _finChrono;
    if (fin == null) return null;
    final reste = fin.difference(_horloge()).inMilliseconds;
    return max(0, (reste / 1000).ceil());
  }

  bool get chronoUrgent =>
      (secondesRestantes ?? Regles.secondesUrgence + 1) <= Regles.secondesUrgence;

  void _lancerChrono(int secondes) {
    _minuteur?.cancel();
    _finChrono = _horloge().add(Duration(seconds: secondes));
    _secondesAffichees = secondes;
    _minuteur = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final reste = secondesRestantes ?? 0;
      if (reste == 0) {
        if (!finie) {
          surRetour?.call(Retour.tempsEcoule);
          abandonner('Temps écoulé. ');
        }
      } else if (reste != _secondesAffichees) {
        _secondesAffichees = reste;
        if (reste <= Regles.secondesTic) surRetour?.call(Retour.tic);
        notifyListeners();
      }
    });
  }

  void _annulerMinuteries() {
    _debutRecherche = null;
    _minuteur?.cancel();
    _minuteur = null;
    _finChrono = null;
    _secondesAffichees = null;
    _retourJetons?.cancel();
    _retourJetons = null;
  }

  // ----------------------------------------------------------- points, sens

  void _ajoute(int pointsDeBase) {
    final n = pointsDeBase * _niveau.multiplicateur;
    if (n == 0) return;
    _score += n;
    if (_journal.isNotEmpty) _journal.last.points += n;
    if (_score > _record) {
      _record = _score;
      unawaited(_stockage.ecrireRecord(_niveau, _record));
    }
  }

  /// Affiche le sens et l'étymologie d'une orthographe (case touchée).
  void reveler(String orthographe) {
    surRetour?.call(Retour.bouton);
    _reveler(orthographe);
    notifyListeners();
  }

  void _reveler(String orthographe, {bool piege = false}) {
    _orthographeRevelee = orthographe;
    _revelationPiege = piege;
    _revelations += 1;
  }

  @override
  void dispose() {
    _annulerMinuteries();
    super.dispose();
  }
}
