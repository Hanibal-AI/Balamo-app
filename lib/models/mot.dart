/// Une entrée de dictionnaire : définition et étymologie d'un mot.
class Mot {
  const Mot({
    required this.lemme,
    required this.nature,
    required this.definition,
    required this.statut,
    required this.certitude,
    required this.racines,
    required this.fiche,
  });

  final String lemme;
  final String nature;
  final String definition;

  /// « vérifiée » ou « à relire ».
  final String statut;

  /// Degré de certitude de l'étymologie (« établie », « discutée »…), s'il est connu.
  final String? certitude;

  final List<Racine> racines;
  final Fiche fiche;

  bool get definitionARelire => statut == 'à relire';

  bool get aEtymologie =>
      fiche.enUnePhrase.isNotEmpty ||
      fiche.origine.isNotEmpty ||
      racines.isNotEmpty;

  factory Mot.fromJson(Map<String, dynamic> j) => Mot(
        lemme: (j['lemme'] ?? '') as String,
        nature: (j['nature'] ?? '') as String,
        definition: (j['definition'] ?? '') as String,
        statut: (j['statut'] ?? '') as String,
        certitude: j['certitude'] as String?,
        racines: ((j['racines'] ?? const []) as List)
            .map((r) => Racine.fromJson(r as Map<String, dynamic>))
            .toList(growable: false),
        fiche: Fiche.fromJson((j['fiche'] ?? const <String, dynamic>{})
            as Map<String, dynamic>),
      );
}

/// Racine (souvent indo-européenne) dont descend un mot.
class Racine {
  const Racine({
    required this.forme,
    required this.sens,
    required this.certitude,
    required this.note,
    required this.mots,
  });

  final String forme;
  final String sens;
  final String? certitude;
  final String note;

  /// Autres mots issus de la même racine.
  final List<String> mots;

  factory Racine.fromJson(Map<String, dynamic> j) => Racine(
        forme: (j['forme'] ?? '') as String,
        sens: (j['sens'] ?? '') as String,
        certitude: j['certitude'] as String?,
        note: (j['note'] ?? '') as String,
        mots: ((j['mots'] ?? const []) as List).cast<String>(),
      );
}

/// Fiche étymologique détaillée (texte en mini-markdown).
class Fiche {
  const Fiche({
    required this.enUnePhrase,
    required this.origine,
    required this.aRetenir,
    required this.sources,
    required this.etapes,
  });

  final String enUnePhrase;
  final String origine;
  final String aRetenir;
  final String sources;
  final List<EtapeFiche> etapes;

  factory Fiche.fromJson(Map<String, dynamic> j) => Fiche(
        enUnePhrase: (j['en_une_phrase'] ?? '') as String,
        origine: (j['origine'] ?? '') as String,
        aRetenir: (j['a_retenir'] ?? '') as String,
        sources: (j['sources'] ?? '') as String,
        etapes: ((j['etapes'] ?? const []) as List)
            .map((e) => EtapeFiche.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// Une étape du « voyage du mot ».
class EtapeFiche {
  const EtapeFiche({required this.titre, required this.texte});

  final String titre;
  final String texte;

  factory EtapeFiche.fromJson(Map<String, dynamic> j) => EtapeFiche(
        titre: (j['titre'] ?? '') as String,
        texte: (j['texte'] ?? '') as String,
      );
}
