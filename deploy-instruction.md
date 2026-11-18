# Déployer Balamo

Ce guide résume ce qu'il faut savoir pour compiler et diffuser Balamo, en particulier depuis le VPS. Les détails (installation, tests, architecture) sont dans [`docs/`](docs/).

## Résumé

| Sujet | État actuel |
| --- | --- |
| Plateforme | Android 7.0 (API 24) et plus. iOS prévu, pas encore fait |
| Identifiant | `com.balamo.app` (`android/app/build.gradle.kts`) |
| Version | `1.0.0+1` (`pubspec.yaml`) |
| Signature de l'APK release | **Clé de debug** : suffisant pour tester, **refusé par le Play Store** |
| Fichier à distribuer | `build/app/outputs/flutter-apk/app-release.apk` (environ 53 Mo) |

## 1. Préparer l'environnement (VPS)

Flutter, le JDK 21 et le SDK Android sont installés dans `~/development/`, sans droits root. Dans chaque nouveau terminal :

```bash
source ~/development/env.sh
```

Pour le rendre permanent : `echo 'source ~/development/env.sh' >> ~/.bashrc`.

Vérifier que tout est en place :

```bash
flutter doctor
```

Seuls `Flutter` et `Android toolchain` doivent être au vert. Les lignes Chrome, Linux et Android Studio peuvent rester en erreur.

> Sur une autre machine, suis [`docs/01-installation.md`](docs/01-installation.md). Il décrit le Mac d'origine : adapte les chemins.

## 2. Vérifier avant de compiler

```bash
flutter pub get
flutter analyze
flutter test
```

Les trois doivent passer (aucun problème, 52 tests verts) avant de distribuer une version.

## 3. Compiler l'APK

```bash
flutter build apk --release
```

Résultat : `build/app/outputs/flutter-apk/app-release.apk`. Il contient les trois architectures (arm64, arm 32 bits, x86_64).

Variante plus légère, un APK par architecture (`arm64-v8a` convient à presque tous les téléphones actuels) :

```bash
flutter build apk --release --split-per-abi
```

Le VPS n'a pas d'écran : on peut **compiler** l'APK mais pas le **lancer**. Il faut le récupérer et l'installer sur un téléphone.

## 4. Récupérer et installer l'APK

Depuis ta machine (remplace `<vps>` par l'adresse du serveur) :

```bash
scp yohann@<vps>:~/Apps/Balamo-app/build/app/outputs/flutter-apk/app-release.apk .
```

Puis, au choix :

- **Sans câble** : envoie le fichier au téléphone (e-mail, Drive, messagerie…), ouvre-le et accepte l'installation. Android demande d'autoriser l'installation d'applications inconnues, et Play Protect peut afficher un avertissement : choisis « Installer quand même ».
- **Avec un câble** (débogage USB activé) : `adb install -r app-release.apk`.

Si une version signée différemment est déjà installée (APK debug, ou APK compilé sur une autre machine), Android refuse la mise à jour : désinstalle d'abord l'ancienne.

## 5. Numéro de version

Dans `pubspec.yaml` :

```yaml
version: 1.0.0+1
```

- `1.0.0` : nom de version affiché.
- `+1` : numéro de build interne. Il doit **augmenter à chaque APK distribué**, sinon Android refuse la mise à jour.

Ou à la compilation : `flutter build apk --release --build-name=1.0.1 --build-number=2`.

## 6. Signature : à faire avant une diffusion large

L'APK release est actuellement signé avec la **clé de debug** de la machine qui compile (`signingConfig = signingConfigs.getByName("debug")` dans `android/app/build.gradle.kts`).

C'est suffisant pour tester et partager à quelques personnes, mais :

- le Play Store **refuse** cette signature ;
- deux machines différentes produisent deux signatures différentes : on ne peut pas mettre à jour l'un par l'autre sans désinstaller.

Pour une diffusion durable, crée ta propre clé **une seule fois** :

1. Générer le magasin de clés :

   ```bash
   keytool -genkey -v -keystore ~/balamo-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias balamo
   ```

   **Sauvegarde le fichier `.jks` et ses mots de passe dans un endroit sûr, hors du dépôt.** Si tu les perds, tu ne pourras plus jamais publier de mise à jour de l'application.

2. Créer `android/key.properties` :

   ```properties
   storePassword=<mot de passe du magasin>
   keyPassword=<mot de passe de la clé>
   keyAlias=balamo
   storeFile=/home/yohann/balamo-release.jks
   ```

3. Charger ce fichier et l'utiliser pour le type `release` dans `android/app/build.gradle.kts` : le code exact est dans [`docs/03-build-apk.md`](docs/03-build-apk.md#signature--à-lire-avant-de-diffuser-largement).

4. Recompiler avec `flutter build apk --release`.

`android/key.properties`, `*.jks` et `*.keystore` sont dans le `.gitignore` : **ne les commit jamais et ne les partage jamais**.

## 7. Publier sur le Play Store

Le Play Store attend un *App Bundle*, signé avec ta propre clé (étape 6) :

```bash
flutter build appbundle --release
```

Fichier généré : `build/app/outputs/bundle/release/app-release.aab`.

Avant la première publication :

- **Change l'identifiant** `com.balamo.app` pour un identifiant basé sur un nom de domaine qui t'appartient (par exemple `fr.mondomaine.balamo`). Il ne pourra plus être modifié une fois l'application publiée. Il se règle dans `applicationId` et `namespace` (`android/app/build.gradle.kts`), puis dans l'arborescence du code Android si elle y fait référence.
- Prévois la fiche du store : description, captures (le dossier `docs/captures/` en contient), icône, politique de confidentialité. Le jeu fonctionne hors ligne, sans compte ni publicité.

## 8. Fichiers locaux à ne pas versionner

Ces fichiers sont propres à la machine ou secrets. Ils sont couverts par le `.gitignore` :

| Fichier | Pourquoi |
| --- | --- |
| `android/local.properties` | Chemins du SDK de cette machine, régénéré par Flutter |
| `android/key.properties`, `*.jks`, `*.keystore` | Clés de signature et mots de passe |
| `android/.gradle/` | Cache Gradle |
| `build/`, `.dart_tool/` | Fichiers générés (plus de 2 Go) |

`android/gradle.properties` doit, lui, rester dans le dépôt : il règle Gradle pour le projet.

## 9. En cas de problème

| Symptôme | Piste |
| --- | --- |
| `Missing "unzip" tool` au premier lancement de `flutter` | `unzip` n'est pas installé et il n'y a pas `sudo` : utiliser le `unzip` de `~/development/bin` (déjà dans le `PATH` via `env.sh`), ou `sudo apt install unzip` |
| `Failed to install … platforms;android-NN` | `sdkmanager "platforms;android-NN"` (la plateforme demandée apparaît dans l'erreur) |
| `OutOfMemoryError: Metaspace` pendant `lintVitalAnalyzeRelease` | Vérifier que `android/gradle.properties` existe (et non `gradle.properties.txt`) : il règle la mémoire de Gradle |
| `License for package … not accepted` | `flutter doctor --android-licenses` |
| `SDK location not found` | `flutter config --android-sdk ~/development/android-sdk` |
| Le build échoue après une mise à jour | `flutter clean`, `flutter pub get`, puis recompiler |
| Détail d'une erreur de compilation | Ajouter `-v` : `flutter build apk --release -v` |

## Check-list avant une diffusion

- [ ] `flutter analyze` et `flutter test` passent
- [ ] Numéro de build (`+N`) incrémenté dans `pubspec.yaml`
- [ ] APK compilé avec `flutter build apk --release`
- [ ] Testé sur un vrai téléphone (le VPS ne peut pas lancer l'application)
- [ ] Pour le Play Store : clé de signature personnelle, identifiant changé, `.aab` généré
