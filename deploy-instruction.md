# Déployer Balamo

Ce guide résume ce qu'il faut savoir pour compiler et diffuser Balamo, en particulier depuis le VPS. Les détails (installation, tests, architecture) sont dans [`docs/`](docs/).

## Résumé

| Sujet | État actuel |
| --- | --- |
| Plateforme | Android 7.0 (API 24) et plus. iOS prévu, pas encore fait |
| Identifiant | `fr.balamo.game` (`android/app/build.gradle.kts`) |
| Version | `1.0.1+3` (`pubspec.yaml`) |
| Signature release | Clé d'envoi `~/balamo-upload.jks` (alias `upload`), configurée via `android/key.properties` |
| Fichier pour le Play Store | `build/app/outputs/bundle/release/app-release.aab` (environ 52 Mo) |
| Fichier pour tester sur un téléphone | `build/app/outputs/flutter-apk/app-release.apk` (environ 53 Mo) |

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

Les trois doivent passer (aucun problème, 63 tests verts) avant de distribuer une version.

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
version: 1.0.1+3
```

- `1.0.1` : nom de version affiché.
- `+3` : numéro de build interne. Il doit **augmenter à chaque `.aab` ou APK distribué**, sinon Android refuse la mise à jour.

Ou à la compilation : `flutter build appbundle --release --build-name=1.0.1 --build-number=3`.

## 6. Signature

La signature de publication est **déjà en place** :

- le magasin de clés est `~/balamo-upload.jks` (alias `upload`, hors du dépôt) ;
- `android/key.properties` contient son chemin et ses mots de passe (fichier ignoré par Git) ;
- `android/app/build.gradle.kts` lit ce fichier et signe le type `release` avec cette clé. **Sans `android/key.properties`, le build retombe sur la clé de debug**, que le Play Store refuse.

**Sauvegarde `~/balamo-upload.jks` et `android/key.properties` (qui contient les mots de passe) dans un endroit sûr, hors du VPS.** Sans eux, tu ne peux plus signer de mise à jour de la même façon : il faudrait demander à Google de réinitialiser la clé d'envoi.

Vérifier avec quelle clé un fichier est signé :

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab     # .aab
~/development/android-sdk/build-tools/36.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk   # .apk
```

Le propriétaire doit être `CN=Balamo, C=FR` (et non `Android Debug`). Empreinte SHA-256 du certificat d'envoi :

```
94:50:1A:29:AE:19:63:36:F8:A4:85:94:08:F6:43:8D:E2:FC:2F:92:EC:0B:AC:B5:9F:2C:05:84:22:4B:C3:C3
```

Sur une autre machine, copie `balamo-upload.jks`, recrée `android/key.properties` (modèle ci-dessous) en adaptant `storeFile`, puis compile.

```properties
storePassword=<mot de passe du magasin>
keyPassword=<mot de passe de la clé>
keyAlias=upload
storeFile=/chemin/vers/balamo-upload.jks
```

## 7. Publier sur le Play Store

Le Play Store n'accepte plus les APK pour une nouvelle application : il attend un *App Bundle* (`.aab`), signé avec ta clé d'envoi (étape 6) :

```bash
flutter build appbundle --release
```

Fichier généré : `build/app/outputs/bundle/release/app-release.aab`. Envoie-le dans la Play Console (Tests, Test interne ou Production, Créer une version). Accepte Play App Signing si on te le propose : ta clé devient la clé d'envoi et Google signe l'application distribuée.

Avant la première publication :

- **L'identifiant `fr.balamo.game` doit rester celui saisi dans la Play Console** : il ne pourra plus être modifié une fois le premier bundle envoyé, et un identifiant différent fait refuser l'upload. Il est défini dans `applicationId` et `namespace` (`android/app/build.gradle.kts`), dans le `package` de `MainActivity.kt` (dossier `android/app/src/main/kotlin/fr/balamo/game/`) et dans `PRODUCT_BUNDLE_IDENTIFIER` côté iOS.
- Prévois la fiche du store : description, captures (le dossier `docs/captures/` en contient), icône, politique de confidentialité. Le jeu fonctionne hors ligne, sans compte ni publicité.

## 8. Compiler l'`.aab` dans GitHub Actions (à la demande)

Le workflow `.github/workflows/build-aab.yml` compile et signe l'`.aab` sur un serveur GitHub, sans passer par le VPS. Il **ne se lance jamais tout seul** : ni à un commit, ni à un push. Il faut le déclencher à la main.

### Configuration (une seule fois)

Dans le dépôt GitHub : *Settings, Secrets and variables, Actions, New repository secret*. Crée ces 4 secrets :

| Secret | Valeur |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Le keystore encodé : `base64 -w0 ~/balamo-upload.jks` (copie toute la sortie) |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` de `android/key.properties` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` de `android/key.properties` |
| `ANDROID_KEY_ALIAS` | `keyAlias` de `android/key.properties` (`upload`) |

Ne colle jamais ces valeurs dans un fichier du dépôt, une issue ou un message.

### Lancer un build

1. Augmente le `+N` de `version:` dans `pubspec.yaml`, commite et pousse.
2. Sur GitHub : onglet *Actions*, workflow **Build AAB**, *Run workflow*, choisis la branche (`main` par défaut), valide.
3. Quand le job est vert, ouvre l'exécution et télécharge l'artefact `balamo-aab-<version>` (un zip qui contient `app-release.aab`). Il reste disponible 90 jours.

Le workflow lance `flutter analyze` et `flutter test`, compile avec Flutter 3.50.0 et JDK 21, puis **refuse de continuer** si l'un des secrets manque ou si le bundle est signé avec la clé de debug. La clé de signature est supprimée du serveur à la fin du job.

> Ce workflow n'a pas encore été exécuté sur GitHub : le premier lancement peut demander un ajustement.

## 9. Fichiers locaux à ne pas versionner

Ces fichiers sont propres à la machine ou secrets. Ils sont couverts par le `.gitignore` :

| Fichier | Pourquoi |
| --- | --- |
| `android/local.properties` | Chemins du SDK de cette machine, régénéré par Flutter |
| `android/key.properties`, `*.jks`, `*.keystore` | Clés de signature et mots de passe |
| `android/.gradle/` | Cache Gradle |
| `build/`, `.dart_tool/` | Fichiers générés (plus de 2 Go) |

`android/gradle.properties` doit, lui, rester dans le dépôt : il règle Gradle pour le projet.

## 10. En cas de problème

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
- [ ] Pour le Play Store : clé de signature personnelle (`android/key.properties` présent), identifiant identique à la Play Console (`fr.balamo.game`), `.aab` généré
