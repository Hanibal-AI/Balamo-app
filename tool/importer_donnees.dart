// Met à jour les mots du jeu à partir du prototype HTML (« Le ForMika »).
//
// Le prototype embarque ses données dans une balise
// <script id="donnees" type="application/json">…</script> ; cet outil les
// extrait, les vérifie sommairement et les écrit dans
// assets/donnees/balamo.json.
//
//     dart run tool/importer_donnees.dart "chemin/vers/Le ForMika, anagrammes.html"
//
// Ensuite : `flutter test` (test/donnees_et_tirage_test.dart contrôle le fichier).
import 'dart:convert';
import 'dart:io';

const _sortie = 'assets/donnees/balamo.json';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage : dart run tool/importer_donnees.dart <prototype.html>');
    exitCode = 64;
    return;
  }
  final source = File(arguments.single);
  if (!source.existsSync()) {
    stderr.writeln('Fichier introuvable : ${source.path}');
    exitCode = 66;
    return;
  }

  final html = source.readAsStringSync();
  final balise = RegExp(
    r'<script[^>]*id="donnees"[^>]*>(.*?)</script>',
    dotAll: true,
  ).firstMatch(html);
  if (balise == null) {
    stderr.writeln('Balise <script id="donnees"> absente : est-ce bien le prototype ?');
    exitCode = 65;
    return;
  }

  final Map<String, dynamic> donnees;
  try {
    donnees = jsonDecode(balise.group(1)!) as Map<String, dynamic>;
  } on FormatException catch (e) {
    stderr.writeln('JSON illisible : ${e.message}');
    exitCode = 65;
    return;
  }

  final manquantes =
      ['genere', 'mots', 'orthographes', 'partie'].where((c) => !donnees.containsKey(c));
  if (manquantes.isNotEmpty) {
    stderr.writeln('Rubriques manquantes : ${manquantes.join(', ')}');
    exitCode = 65;
    return;
  }

  File(_sortie)
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(donnees));

  final partie = donnees['partie'] as List;
  final parNiveau = <String, int>{};
  for (final mot in partie.cast<Map<String, dynamic>>()) {
    parNiveau.update(mot['niveau'] as String, (n) => n + 1, ifAbsent: () => 1);
  }
  stdout
    ..writeln('$_sortie mis à jour (données du ${donnees['genere']}).')
    ..writeln('${partie.length} mots jouables : '
        '${parNiveau.entries.map((e) => '${e.value} ${e.key}').join(', ')}.')
    ..writeln('Lance maintenant « flutter test » pour vérifier leur cohérence.');
}
