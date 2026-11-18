# 01 · Installation

Ce guide prépare une machine à compiler Balamo. À la fin, `flutter doctor` ne doit plus signaler d'erreur pour Android.

## Ce qu'il faut

| Outil | Version | Rôle |
| --- | --- | --- |
| **Flutter SDK** | 3.50 ou plus (Dart 3.14 inclus) | Le framework et ses outils en ligne de commande |
| **JDK** | 17 ou plus (21 conseillé) | Fait tourner Gradle, qui assemble l'APK |
| **SDK Android** | plateforme API 36, build-tools, platform-tools | Compile et installe l'application Android |
| **Git** | récent | Utilisé par Flutter pour se mettre à jour |

Pas besoin d'installer Dart à part : il est livré avec Flutter.

Pour iOS (plus tard), il faudra en plus un Mac avec **Xcode** et **CocoaPods** : voir la fin de ce guide.

## Sur ce Mac : c'est déjà fait

Les outils ont été installés pendant la création du projet, sans rien modifier dans le système :

| Outil | Emplacement |
| --- | --- |
| Flutter 3.50.0 | `~/development/flutter` |
| JDK 21 (Eclipse Temurin) | `~/development/jdk-21.0.13+9` |
| SDK Android (outils en ligne de commande, via Homebrew) | `/usr/local/share/android-commandlinetools` |

Flutter connaît déjà le chemin du JDK et du SDK Android (`flutter config`). **Il reste une seule chose à faire** : rendre la commande `flutter` disponible dans le terminal. Ajoute ces lignes à la fin de `~/.zshrc` :

```bash
export JAVA_HOME="$HOME/development/jdk-21.0.13+9/Contents/Home"
export ANDROID_HOME="/usr/local/share/android-commandlinetools"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"
```

Puis ouvre un nouveau terminal (ou lance `source ~/.zshrc`) et passe à la [vérification](#vérifier-linstallation).

## Sur une autre machine

### 1. Flutter

Télécharge l'archive « stable » pour ton système sur <https://docs.flutter.dev/install/archive>, puis décompresse-la dans un dossier sans espace ni droits spéciaux, par exemple :

- macOS / Linux : `~/development/flutter`
- Windows : `C:\dev\flutter`

Ajoute ensuite le dossier `flutter/bin` au `PATH` :

- **macOS (zsh)** : ajoute `export PATH="$HOME/development/flutter/bin:$PATH"` à `~/.zshrc`.
- **Linux (bash)** : même ligne, dans `~/.bashrc`.
- **Windows** : Paramètres → « Modifier les variables d'environnement pour votre compte » → `Path` → Nouveau → `C:\dev\flutter\bin`.

### 2. SDK Android et JDK

**Le plus simple : Android Studio.** Installe-le depuis <https://developer.android.com/studio>. Au premier lancement, l'assistant télécharge le SDK Android ; Android Studio embarque aussi son propre JDK, que Flutter détecte tout seul. Dans *Settings → Languages & Frameworks → Android SDK → SDK Tools*, coche **Android SDK Command-line Tools**.

**Sans Android Studio** (ce qui a été fait sur ce Mac) :

```bash
# JDK : https://adoptium.net (Temurin 21), ou sous Linux : sudo apt install openjdk-21-jdk
# Outils Android, avec Homebrew sur macOS :
brew install --cask android-commandlinetools
sdkmanager "platform-tools" "platforms;android-36"

flutter config --android-sdk /chemin/vers/le/sdk --jdk-dir /chemin/vers/le/jdk
```

Les composants manquants (build-tools, NDK) sont téléchargés automatiquement lors de la première compilation.

### 3. Variables d'environnement

| Variable | Valeur | Obligatoire ? |
| --- | --- | --- |
| `PATH` | doit contenir `…/flutter/bin` | Oui |
| `ANDROID_HOME` | dossier du SDK Android | Conseillé (indispensable pour utiliser `adb` et `sdkmanager` directement) |
| `JAVA_HOME` | dossier du JDK | Seulement si `flutter doctor` ne trouve pas Java |
| `PATH` | `$ANDROID_HOME/platform-tools` | Conseillé, pour la commande `adb` |

### 4. Licences Android

À faire une fois par machine, sinon la compilation s'arrête :

```bash
flutter doctor --android-licenses
```

Réponds `y` à chaque licence.

## Vérifier l'installation

```bash
flutter --version
```

```bash
flutter doctor -v
```

Ce qui compte pour Balamo :

- `[✓] Flutter` : version 3.50 ou plus, canal *stable*.
- `[✓] Android toolchain` : SDK trouvé, licences acceptées, Java détecté.

Les lignes *Xcode*, *Chrome* ou *Android Studio* peuvent rester en avertissement : elles ne sont pas nécessaires pour compiler l'APK.

Enfin, récupère les dépendances du projet (à refaire après chaque modification de `pubspec.yaml`) :

```bash
flutter pub get
```

## Problèmes fréquents

| Message | Solution |
| --- | --- |
| `command not found: flutter` | Le `PATH` n'est pas à jour : relis l'étape correspondante, puis ouvre un **nouveau** terminal. |
| `Unable to locate Android SDK` | `flutter config --android-sdk /chemin/vers/le/sdk` |
| `Android license status unknown` | `flutter doctor --android-licenses` |
| `Unable to find bundled Java version` / erreur de version Java | Installe un JDK 17+ puis `flutter config --jdk-dir /chemin/vers/le/jdk` |
| Première compilation très longue | Normal : Gradle télécharge ses composants et le NDK (plus d'1 Go). Les suivantes prennent moins d'une minute. |

## Et pour iOS, plus tard ?

Le code de Balamo n'utilise aucune API propre à Android : le dossier `ios/` est déjà généré et l'orientation portrait y est configurée. Pour compiler la version iPhone, il faudra :

1. un Mac avec **Xcode** (App Store), puis `sudo xcodebuild -runFirstLaunch` ;
2. **CocoaPods** : `brew install cocoapods` ;
3. `flutter doctor` pour vérifier, puis `flutter run` sur un simulateur ou `flutter build ipa` (compte développeur Apple requis pour distribuer).
