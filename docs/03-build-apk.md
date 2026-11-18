# 03 · Compiler l'APK

Deux fichiers APK possibles : un APK **de test** (debug) pour vérifier rapidement sur un téléphone, et un APK **de production** (release), optimisé, à partager et installer.

Toutes les commandes se lancent à la racine du projet. La toute première compilation est longue (Gradle télécharge ses composants et le NDK Android) ; les suivantes prennent environ une minute.

## Avant de compiler

```bash
flutter pub get
```

```bash
flutter analyze
```

```bash
flutter test
```

Les deux dernières commandes sont facultatives mais évitent de distribuer une version cassée.

## APK de test (debug)

```bash
flutter build apk --debug
```

Fichier généré :

```
build/app/outputs/flutter-apk/app-debug.apk
```

À savoir sur cet APK : il est gros (près de 200 Mo) et plus lent, car il embarque les outils de débogage, et il affiche un écran technique en cas d'erreur. Il sert à tester, pas à être distribué.

## APK de production (release)

```bash
flutter build apk --release
```

Fichier généré :

```
build/app/outputs/flutter-apk/app-release.apk
```

C'est **ce fichier-là** qu'on partage (environ 53 Mo) : il est compilé en code natif, optimisé, et contient les trois architectures de processeur (arm64, arm 32 bits, x86_64), donc il s'installe sur tous les téléphones Android 7.0 (API 24) et plus.

### Variante : un APK plus léger par architecture

```bash
flutter build apk --release --split-per-abi
```

Trois fichiers sont générés dans le même dossier ; chacun pèse environ un tiers de l'APK universel :

| Fichier | Pour |
| --- | --- |
| `app-arm64-v8a-release.apk` | Presque tous les téléphones actuels (à choisir en cas de doute) |
| `app-armeabi-v7a-release.apk` | Anciens téléphones 32 bits |
| `app-x86_64-release.apk` | Émulateurs et quelques tablettes |

## Installer l'APK sur un téléphone

**Avec un câble** (débogage USB activé, voir [02](02-developpement-et-test.md)) :

```bash
flutter install --release
```

ou, pour un fichier précis :

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Sans câble** : envoie le fichier `app-release.apk` sur le téléphone (e-mail, messagerie, Drive, clé USB…), ouvre-le depuis le téléphone, puis accepte l'installation. Android demandera d'autoriser l'application qui ouvre le fichier à « installer des applications inconnues » : c'est normal pour un APK qui ne vient pas du Play Store. Play Protect peut aussi afficher un avertissement : choisis « Installer quand même ».

Si une version signée différemment est déjà installée (par exemple un APK debug), Android refuse la mise à jour : désinstalle d'abord l'ancienne.

## Numéro de version

La version se règle dans `pubspec.yaml` :

```yaml
version: 1.0.0+1
```

`1.0.0` est le nom de version affiché ; `+1` est le numéro de build interne, qui doit **augmenter à chaque APK distribué** (sinon Android refuse la mise à jour). On peut aussi les passer à la compilation :

```bash
flutter build apk --release --build-name=1.0.1 --build-number=2
```

## Identifiant de l'application

Android reconnaît une application à son identifiant, ici **`com.balamo.app`** (ligne `applicationId` de `android/app/build.gradle.kts` ; côté iOS, `PRODUCT_BUNDLE_IDENTIFIER` dans le projet Xcode). Tant que l'application circule en APK, il peut rester tel quel. Avant une publication sur un store, remplace-le par un identifiant bâti sur un nom de domaine qui t'appartient (par exemple `fr.mondomaine.balamo`) : une fois l'application publiée, il ne peut plus changer.

## Signature : à lire avant de diffuser largement

Tel que le projet est configuré, l'APK release est **signé avec la clé de débogage** de la machine qui compile. C'est suffisant pour installer l'APK directement sur des téléphones et le partager à des testeurs. Deux limites :

- les APK compilés sur deux machines différentes n'ont pas la même signature (il faudra désinstaller avant de passer de l'un à l'autre) ;
- le Play Store refuse cette signature.

Pour une diffusion durable, crée ta propre clé de signature, **une fois pour toutes** :

1. Génère un magasin de clés (garde ce fichier et ses mots de passe en lieu sûr : sans eux, plus de mise à jour possible) :

   ```bash
   keytool -genkey -v -keystore ~/balamo-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias balamo
   ```

2. Crée le fichier `android/key.properties` (il est déjà ignoré par Git, ne le partage jamais) :

   ```properties
   storePassword=<mot de passe du magasin>
   keyPassword=<mot de passe de la clé>
   keyAlias=balamo
   storeFile=/Users/<toi>/balamo-release.jks
   ```

3. Dans `android/app/build.gradle.kts`, charge ce fichier et utilise-le pour le type `release` :

   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       // …
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String?
               keyPassword = keystoreProperties["keyPassword"] as String?
               storeFile = keystoreProperties["storeFile"]?.let { file(it) }
               storePassword = keystoreProperties["storePassword"] as String?
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

4. Recompile : `flutter build apk --release`.

## Pour le Play Store

Le Play Store attend un *App Bundle* plutôt qu'un APK :

```bash
flutter build appbundle --release
```

Fichier généré : `build/app/outputs/bundle/release/app-release.aab` (signature personnelle obligatoire, voir ci-dessus).

## En cas de problème

| Symptôme | Piste |
| --- | --- |
| La compilation échoue après une mise à jour de Flutter ou d'une dépendance | `flutter clean` puis `flutter pub get`, et recompile |
| `SDK location not found` | `flutter config --android-sdk /chemin/vers/le/sdk` (voir [01](01-installation.md)) |
| `License for package … not accepted` | `flutter doctor --android-licenses` |
| Erreur de version Java | JDK 17 minimum : `flutter config --jdk-dir /chemin/vers/le/jdk` |
| « Application non installée » sur le téléphone | Une version avec une autre signature est déjà installée : désinstalle-la d'abord |
| Besoin du détail de l'erreur | Ajoute `-v` à la commande : `flutter build apk --release -v` |
