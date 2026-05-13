Voici un guide complet au format **Markdown (.md)** que tu peux copier et enregistrer sous le nom `TUTO_FLUTTER_FIREBASE.md`. 

C'est un condensé de tout ce que nous avons fait aujourd'hui, étape par étape, pour que tu puisses reproduire cette configuration en un clin d'œil pour tes futurs projets.

---

# 🚀 Guide Complet : Création et Connexion Flutter + Firebase Firestore

Ce tutoriel trace le chemin exact pour créer une application Flutter stable et la connecter à Firebase en utilisant les outils modernes (2024/2025).

## 0. Pré-requis (Une seule fois par PC)
Avant de commencer, assure-toi que ton PC est prêt :
- **Flutter SDK** installé.
- **Node.js** installé (pour Firebase CLI).
- **Mode Développeur Windows** : Activé (Paramètres > Confidentialité et sécurité > Pour les développeurs).
- **PATH Windows** : Vérifie que le chemin suivant est dans tes variables d'environnement `Path` :
  `%USERPROFILE%\AppData\Local\Pub\Cache\bin` (Indispensable pour FlutterFire).

---

## Étape 1 : Création du projet (Le bon emplacement)
**IMPORTANT** : Ne travaille jamais sur un disque Cloud (Google Drive, OneDrive, etc.) car cela crée des erreurs de liens symboliques.
1. Ouvre un terminal et va sur ton disque local **C:**.
2. Crée ton projet :
   ```bash
   cd C:\Projets
   flutter create mon_app
   cd mon_app
   ```

---

## Étape 2 : Installation des outils Firebase
Installe les outils qui permettent de discuter avec Firebase depuis ton terminal :
1. **Firebase CLI** : `npm install -g firebase-tools`
2. **FlutterFire CLI** : `dart pub global activate flutterfire_cli`
3. **Connexion au compte Google** :
   ```bash
   firebase login
   ```
   *(Choisis ton compte Gmail dans le navigateur)*.

---

## Étape 3 : Configuration de Firebase (FlutterFire)
Cette commande lie ton code à un projet Firebase (existant ou nouveau).
1. Lance la config :
   ```bash
   flutterfire configure
   ```
2. **Sélection du projet** : Choisis un projet existant ou sélectionne `<create a new project>`.
3. **Plateformes** : Sélectionne `android` et `web` (et ios si besoin) avec la touche **Espace**, puis **Entrée**.
4. Cela génère automatiquement le fichier : `lib/firebase_options.dart`.

---

## Étape 4 : Activation de Firestore sur le Web
1. Va sur la [Console Firebase](https://console.firebase.google.com/).
2. Clique sur ton projet.
3. Menu de gauche : **Firestore Database** > **Create Database**.
4. **Location** : Choisis une zone (ex: `europe-west`).
5. **Rules** : Choisis **"Start in TEST MODE"** (Démarrer en mode test). C'est crucial pour pouvoir tester sans être bloqué par les permissions.

---

## Étape 5 : Ajout des dépendances Flutter
Ajoute les bibliothèques nécessaires à ton projet :
```bash
flutter pub add firebase_core cloud_firestore
```

---

## Étape 6 : Configuration Android (Correctifs NDK/SDK)
Pour éviter les erreurs de compilation Firebase sur Android, modifie le fichier :
👉 `android/app/build.gradle.kts`

1. **NDK Version** : Dans le bloc `android { ... }`, ajoute :
   ```kotlin
   android {
       ndkVersion = "27.0.12077973" // À adapter selon le message d'erreur Flutter
       ...
   }
   ```
2. **Min SDK** : Dans `defaultConfig { ... }`, remplace par :
   ```kotlin
   minSdk = 23
   ```

---

## Étape 7 : Initialisation du Code (main.dart)
Remplace ton `main.dart` par ce code minimal pour tester la connexion :

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise Firebase avec les options générées
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: TestPage()));
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Firebase")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Test d'envoi de donnée
            await FirebaseFirestore.instance.collection('tests').add({
              'status': 'Connecté !',
              'date': DateTime.now(),
            });
            print("Donnée envoyée !");
          }, 
          child: const Text("Vérifier la connexion"),
        ),
      ),
    );
  }
}
```

---

## Étape 8 : Lancement et Premier Test
1. Connecte ton téléphone physique (Débogage USB activé).
2. Vérifie s'il est vu : `flutter devices`.
3. Si ADB bug : `adb kill-server` puis `adb start-server`.
4. Lance l'appli :
   ```bash
   flutter run
   ```
5. Appuie sur le bouton sur ton téléphone.
6. **Résultat** : La donnée doit apparaître instantanément dans l'onglet **Data** de Firestore dans ton navigateur.

---

## 🛠 Troubleshooting (En cas de pépin)
- **Erreur de Symlink** : Vérifie que le projet est sur le disque `C:` et que le "Mode Développeur" de Windows est ON.
- **Erreur Registrar** : Fais `flutter pub upgrade --major-versions` puis `flutter clean`.
- **NDK manquant** : Ouvre Android Studio > SDK Manager > SDK Tools > Coche "NDK (Side by side)" et installe.

---

*Fait avec ❤️ pour Wari-Gbê par Ulrich Blanchard.*