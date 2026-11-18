# 02 · Développement et test

Comment lancer Balamo en mode *debug*, le modifier en direct et vérifier que tout fonctionne. Toutes les commandes se lancent à la racine du projet (le dossier qui contient `pubspec.yaml`).

## Lancer l'application

```bash
flutter pub get
```

```bash
flutter devices
```

```bash
flutter run
```

`flutter devices` liste les appareils disponibles. S'il y en a plusieurs, précise lequel : `flutter run -d <identifiant>`.

### Sur un téléphone Android (recommandé)

1. **Active les options pour les développeurs** : *Paramètres → À propos du téléphone*, puis touche sept fois **Numéro de build** (sur certains modèles : *Informations sur le logiciel → Numéro de version*).
2. **Active le débogage USB** : *Paramètres → Système → Options pour les développeurs → Débogage USB*.
3. Branche le téléphone avec un câble USB **de données** (certains câbles ne font que charger).
4. Sur le téléphone, accepte la fenêtre **« Autoriser le débogage USB ? »** (coche « Toujours autoriser »).
5. Vérifie que le téléphone est vu, puis lance :

```bash
flutter devices
```

```bash
flutter run
```

Si le téléphone n'apparaît pas : change de câble ou de port, choisis le mode USB « Transfert de fichiers », et regarde `adb devices` (un appareil marqué `unauthorized` attend que tu acceptes la fenêtre de l'étape 4).

**Sans câble (Android 11+)** : dans les options pour les développeurs, active *Débogage sans fil*, touche *Associer l'appareil avec un code d'association*, puis :

```bash
adb pair <ip>:<port-d-association>
adb connect <ip>:<port>
```

### Sur un émulateur Android

Avec Android Studio : *Device Manager → Create Virtual Device*, choisis un téléphone (Pixel par exemple) et une image système récente, puis démarre-le.

En ligne de commande :

```bash
sdkmanager "emulator" "system-images;android-36;google_apis;x86_64"
avdmanager create avd -n balamo -k "system-images;android-36;google_apis;x86_64" -d pixel_7
flutter emulators --launch balamo
flutter run
```

(Sur un Mac Apple Silicon, remplace `x86_64` par `arm64-v8a`.)

## Hot Reload : modifier sans relancer

Pendant que `flutter run` tourne, le terminal accepte des raccourcis :

| Touche | Effet |
| --- | --- |
| `r` | **Hot Reload** : injecte le code modifié en moins d'une seconde, **en gardant l'état** (la partie en cours, le score…). Idéal pour retoucher l'interface. |
| `R` | **Hot Restart** : redémarre l'application à zéro. Nécessaire si tu changes un état initial, un `enum`, `main()` ou les données chargées au démarrage. |
| `p` | Affiche les contours des widgets (pour déboguer une mise en page). |
| `q` | Quitte. |

Dans VS Code ou Android Studio (avec les extensions Flutter), le Hot Reload se déclenche à chaque sauvegarde.

À savoir :

- Une modification de `pubspec.yaml`, des polices ou de `assets/donnees/balamo.json` demande d'arrêter puis de relancer `flutter run`.
- Une modification des dossiers `android/` ou `ios/` demande une recompilation complète (relancer `flutter run`).
- Le mode debug est plus lent et plus lourd que la version finale : ne juge pas la fluidité dessus. Pour ça : `flutter run --release` (ou `--profile`).

## Lancer les tests

```bash
flutter test
```

Les tests n'ont besoin ni de téléphone ni d'émulateur. Ils couvrent :

| Fichier | Ce qui est vérifié |
| --- | --- |
| `test/partie_controller_test.dart` | Les règles : pari, barème et multiplicateurs, anagrammes trouvées/refusées, **coût des indices**, chrono du niveau expert, records, enchaînement des manches. |
| `test/donnees_et_tirage_test.dart` | Le fichier de mots (chaque anagramme utilise bien les lettres du mot, chaque mot a sa définition), la composition des parties (un piège sur quatre, jamais deux mots du même groupe) et l'affichage des fiches étymologiques. |
| `test/sons_test.dart` | Chaque action signale bien son événement sonore (jeton posé, mélange, indice, tic du chrono…), tous les fichiers audio existent, et les interrupteurs Sons / Musique sont mémorisés. |
| `test/parcours_test.dart` | L'interface réelle, pilotée comme au doigt : une manche complète, le glisser-déposer des jetons, le bilan, et l'absence de débordement sur un petit écran. |

Un seul fichier, ou un seul test par son nom :

```bash
flutter test test/partie_controller_test.dart
```

```bash
flutter test --plain-name "un indice dévoile une lettre"
```

Avant de partager du code, lance aussi l'analyse statique (elle doit répondre `No issues found!`) :

```bash
flutter analyze
```

Les tests vérifient que le bon son est *demandé* au bon moment ; ils ne peuvent pas juger s'il est agréable. Pour ça, il faut écouter sur un vrai téléphone (les fichiers de `assets/sons/` s'écoutent aussi directement sur l'ordinateur).

## Régénérer les captures d'écran

Les images de `docs/captures/` sont produites à partir de la vraie interface, sans appareil :

```bash
flutter test tool/captures_test.dart --update-goldens
```

Pratique pour vérifier d'un coup d'œil l'effet d'un changement de design, en clair comme en sombre.

## Voir les journaux et déboguer

- `flutter run` affiche les `print()` et les erreurs dans le terminal.
- `flutter logs` affiche les journaux d'un appareil déjà branché.
- La touche `v` pendant `flutter run` ouvre **DevTools** (inspecteur de widgets, performances, mémoire) dans le navigateur.
