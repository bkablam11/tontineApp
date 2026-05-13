# 🏦 WARI-GBÊ - Application Tontine Mobile

**Système de gestion de tontine (épargne mutuelle) mobile avec OCR et validation en temps réel**

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Fonctionnalités implémentées](#fonctionnalités-implémentées)
3. [Architecture technique](#architecture-technique)
4. [Installation et configuration](#installation-et-configuration)
5. [Améliorations possibles](#améliorations-possibles)
6. [Guide de développement](#guide-de-développement)

---

## 🎯 Vue d'ensemble

**WARI-GBÊ** est une application mobile Flutter qui facilite la gestion des tontines (système d'épargne collective où chaque membre cotise régulièrement). L'application utilise la reconnaissance optique de caractères (OCR) pour extraire automatiquement les informations des reçus de transaction et propose une plateforme centralisée pour le suivi des contributions et la validation des paiements.

### Objectif principal
- **Objectif cible** : 250 000 F CFA
- **Montant par cotisant** : 50 000 F CFA
- **Nombre de membres** : 5

### Utilisateurs
- **Membres** : Peuvent ajouter leurs contributions et signaler des retards
- **Contrôleur** : (Maguid) Administre les validations de reçus et la gestion des retards

---

## ✅ Fonctionnalités implémentées

### 1. **Authentification sécurisée** 🔐
- ✔️ Connexion via Google Sign-In
- ✔️ Gestion des sessions Firebase
- ✔️ Contrôle d'accès basé sur la liste de membres autorisés
- ✔️ Affichage du rôle de l'utilisateur connecté

**Détails techniques** :
- Service : Firebase Authentication
- Intégration : Google Sign-In
- Vérification : Matching avec liste locale de membres

---

### 2. **Tableau de bord dynamique (Dashboard)** 📊

#### Affichage principal
- ✔️ **Caisse de transparence** : Total collecté en temps réel
- ✔️ **Progression graphique** : Barre de progression vers l'objectif de 250 000 F
- ✔️ **Objectif cycle** : Affichage de la cible 
- ✔️ **Mur de Vérité** : Liste de tous les membres avec :
  - Avatar avec initiales
  - Nom du membre
  - Statut : "EN ATTENTE", "EN COURS", "COMPLÉTÉ"
  - Montant déjà payé
  - Montant restant à payer
  - Indicateur "SOLDÉ ✅" si paiement complet

#### Données en temps réel
- ✔️ Synchronisation Firebase Firestore
- ✔️ Calcul dynamique des montants validés
- ✔️ Formatage numérique (format français avec séparateurs)

#### Fonction de communication
- ✔️ Bouton "SIGNALER UN RETARD"
- ✔️ Modal avec formulaire :
  - Champ raison du retard (multilignes)
  - Champ date prévue de paiement
  - Envoi à Firestore pour notification du contrôleur

**Détails techniques** :
- Source de données : Firestore (collection 'contributions')
- Filtrage : Uniquement les contributions avec statut 'validated'
- Formatage : NumberFormat avec locale 'fr_FR'

---

### 3. **Scanner OCR & Charger preuve** 📸

#### Fonctionnalités
- ✔️ **Sélection d'image** : Interface FilePicker pour choisir un reçu
- ✔️ **Extraction intelligente** : OCR Google ML Kit pour :
  - Date d'émission
  - Type de transaction
  - Numéro d'expéditeur (1er numéro détecté)
  - Numéro de transaction (ID unique)
  - Montant en CFA
  - Numéro de destinataire (2e numéro détecté)
  - Validité de la date de transaction

#### Processus de compression et envoi
1. Chargement de l'image originale
2. **Compression intelligente** :
   - Redimensionnement à 800px de largeur
   - Encodage JPG avec qualité 70%
   - Réduction de taille de 70-80%
3. Encodage Base64 pour Firestore
4. Envoi avec métadonnées :
   - Identité de l'utilisateur
   - Nom du membre
   - Montant (parsé et validé)
   - ID transaction
   - Image compressée en Base64
   - Statut initial : "pending"
   - Timestamp serveur

#### Validation des champs
- ✔️ Vérification non-vide avant envoi
- ✔️ Parsing du montant (suppression des caractères non-numériques)
- ✔️ Messages de feedback utilisateur

**Détails techniques** :
- Librairie OCR : google_mlkit_text_recognition
- Format image : Base64 (stocké dans Firestore)
- Regex patterns pour extraction :
  - Téléphones : `0[157][\s\d]{8,12}`
  - Montant : `CFA\s*F?\d+`
  - ID transaction : `N°\s*([\w,.]+)`

---

### 4. **Espace Admin (Contrôle)** 👨‍💼

#### Vue d'ensemble
- ✔️ Accès exclusif au rôle "controller"
- ✔️ Interface avec onglets pour organisation

#### Onglet 1 : Reçus à valider
- ✔️ Liste en temps réel des contributions "pending"
- ✔️ Affichage de l'image du reçu (décodage Base64)
- ✔️ Infos du contribuant :
  - Nom du membre
  - Montant
  - ID transaction
- ✔️ Actions pour chaque reçu :
  - ✅ Bouton validation (change statut à 'validated')
  - ❌ Bouton rejet (change statut à 'rejected')
- ✔️ Message "Aucun reçu à valider" quand queue vide

#### Onglet 2 : Retards signalés
- ✔️ Liste de tous les retards signalés
- ✔️ Affichage par ordre chronologique décroissant
- ✔️ Infos affichées :
  - Nom du membre ayant signalé
  - Raison du retard
  - Date prévue de paiement
  - Icône d'info en orange
- ✔️ Message si aucun retard

**Détails techniques** :
- Firestore queries :
  - Reçus : `WHERE status == 'pending'`
  - Retards : `ORDER BY createdAt DESC`
- Update atomique du statut avec timestamp

---

### 5. **Gestion des retards** ⏰
- ✔️ Signalement volontaire par le membre
- ✔️ Formulaire modal avec :
  - Raison textuelle du retard
  - Date prévue de paiement
  - Validation des champs requis
- ✔️ Envoi à Firestore collection 'delays'
- ✔️ Notification via Snackbar
- ✔️ Visibilité totale pour le contrôleur

---

### 6. **Design système & UX** 🎨

#### Palette de couleurs
- **Indigo (Primaire)** : #4F46E5
- **Émeraude (Validation)** : #10B981
- **Ardoise (Background)** : #F8FAFC
- **Sombre (Accents)** : #0F172A
- **Bordures** : #E2E8F0

#### Typographie
- Police : Inter
- Poids : Regular, W900 (bold)
- Tailles : 9px (labels), 11px (petits textes), 14px (corps), 22px (titres)

#### Composants réutilisables
- ✔️ Inputs stylisés avec icônes
- ✔️ Boutons primaires arrondis
- ✔️ Cards avec bordures
- ✔️ Avatars circulaires
- ✔️ Barres de progression
- ✔️ Modals bottom sheet

**Détails techniques** :
- Material Design 3
- `useMaterial3: true`
- Responsive design avec MediaQuery
- Gestion des clavier avec `viewInsets`

---

### 7. **Firebase Integration** ☁️

#### Services utilisés
- ✔️ **Firebase Core** : Initialisation (v4.7.0)
- ✔️ **Firebase Auth** : Authentification (v6.4.0)
- ✔️ **Cloud Firestore** : Base de données temps réel (v6.3.0)
- ✔️ **Firebase Storage** : Préparé pour futurs uploads (v13.4.0)

#### Collections Firestore

**Collection : `contributions`**
```json
{
  "userId": "uid_firebase",
  "userName": "Nom du membre",
  "amount": 50000,
  "transactionId": "ref123456",
  "imageRaw": "iVBORw0KGgoAAAANSUhEUgAA... (Base64)",
  "status": "pending|validated|rejected",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

**Collection : `delays`**
```json
{
  "userName": "Nom du membre",
  "reason": "Raison du retard",
  "expectedDate": "15/05",
  "status": "reported",
  "createdAt": Timestamp
}
```

---

## 🏗️ Architecture technique

### Structure du projet
```
lib/
├── main.dart                 # Application principale + tous les écrans
├── ocr_service.dart          # Service de reconnaissance OCR
└── firebase_options.dart     # Configuration Firebase générée
```

### Stack technique
- **Framework** : Flutter (Dart)
- **Plateforme** : iOS, Android, Web, Windows, macOS, Linux
- **Base de données** : Firestore
- **Authentification** : Firebase Auth + Google Sign-In
- **OCR** : Google ML Kit
- **Stockage image** : Base64 dans Firestore
- **UI Framework** : Material 3

### Flux de données

**Connexion utilisateur**
```
Google Sign-In → Firebase Auth → Vérification liste locale → Dashboard
```

**Ajout de contribution**
```
Image sélectionnée → OCR extraction → Compression → Firestore (pending)
                    → Admin validation → Firestore update → Dashboard refresh
```

**Signalement de retard**
```
Formulaire modal → Firestore delays → Admin notification
```

---

## 🚀 Installation et configuration

### Prérequis
- Flutter SDK ^3.8.1
- Dart SDK compatible
- Un projet Firebase configuré
- Google OAuth credentials

### Dépendances principales
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^4.7.0
  cloud_firestore: ^6.3.0
  firebase_auth: ^6.4.0
  google_sign_in: ^6.2.1
  google_mlkit_text_recognition: ^0.15.1
  file_picker: ^11.0.2
  intl: ^0.20.2
  image: ^4.8.0
  firebase_storage: ^13.4.0
```

### Étapes de configuration

1. **Clonage et installation**
```bash
flutter pub get
```

2. **Firebase setup**
- Créer un projet Firebase
- Télécharger google-services.json pour Android
- Générer fichier de configuration iOS
- Lancer : `flutterfire configure`

3. **Mise à jour des informations**
- Modifier le liste de `membersList` avec les vrais utilisateurs
- Mettre à jour les emails Google des membres
- Ajuster `kTargetAmount` si nécessaire

4. **Compilation et test**
```bash
flutter run
```

---

## 💡 Améliorations possibles

### 🔴 **HAUTE PRIORITÉ** (Impact direct sur UX)

#### 1. **Historique personnel des membres**
- **État actuel** : "Historique personnel bientôt disponible"
- **À faire** : 
  - Créer écran affichant les contributions de l'utilisateur connecté
  - Statuts pour chaque contribution (pending, validated, rejected)
  - Historique des retards signalés par l'utilisateur
  - Export/impression de reçu validé

#### 2. **Notifications en temps réel**
- **À ajouter** : 
  - Push notifications quand reçu est validé/rejeté
  - Notifications au contrôleur quand nouveau reçu à valider
  - Rappel de cotisation si délai approche
  - Alerte quand retard est signalé
- **Package recommandé** : `firebase_messaging`

#### 3. **Gestion des rejets de reçu**
- **État actuel** : Peut rejeter mais aucun feedback au membre
- **À ajouter** :
  - Motif du rejet (optionnel mais visible)
  - Message personnalisé du contrôleur
  - Historique des rejets
  - Possibilité de renvoyer un nouveau reçu

#### 4. **Pagination et filtrages avancés**
- **Amélioration du dashboard** :
  - Filtre par statut (EN ATTENTE, EN COURS, COMPLÉTÉ)
  - Tri par montant ou nom
  - Pagination des retards
  - Recherche de membre
- **Dans l'admin** :
  - Filtre par date
  - Recherche par ID transaction
  - Export des données validées

### 🟡 **MOYENNE PRIORITÉ** (Robustesse et sécurité)

#### 5. **Validation des données côté client**
- **À ajouter** :
  - Validation du format du numéro de transaction
  - Détection de doublons (même transaction ID)
  - Montant minimum et maximum
  - Validation des dates
- **Impact** : Réduire les erreurs et rejets

#### 6. **Amélioration OCR**
- **Issues actuelles** :
  - Peut ne pas extraire correctement tous les formats de reçu
  - Sensibilité à la qualité/angle de la photo
  - Pas de fallback intelligente
- **À améliorer** :
  - Permettre l'édition des champs après OCR
  - Ajouter des hints de formats (ex: "Montant en format 50000 CFA")
  - Améliorer regex pour plus de formats de reçu
  - Comparer plusieurs scans du même reçu pour vérifier cohérence

#### 7. **Gestion des erreurs améliorée**
- **À ajouter** :
  - Try-catch plus granulaires avec messages spécifiques
  - Logging d'erreurs pour debug
  - Retry automatique pour opérations réseau
  - Gestion offline (synchronisation quand connexion rétablie)

#### 8. **Sécurité Firebase Rules**
- **État actuel** : Pas de règles de sécurité (vulnérable)
- **À faire** :
  ```firestore
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /contributions/{document=**} {
        allow read: if request.auth != null;
        allow create: if request.auth != null && 
                      request.resource.data.userId == request.auth.uid;
        allow update: if request.auth.token.email == 'bkablam11@gmail.com';
      }
      match /delays/{document=**} {
        allow read, create: if request.auth != null;
      }
    }
  }
  ```

#### 9. **Formatage et parsing robuste**
- **Amélioration** :
  - Parser plus robuste du montant (gérer différents formats)
  - Gérer les espaces et caractères spéciaux
  - Support multidevises (convertir si nécessaire)
  - Format de date flexible (15/05 ou 15/05/2026)

### 🟢 **BASSE PRIORITÉ** (Nice-to-have)

#### 10. **Statistiques et analytics** 📈
- Graphiques de progression mensuelle
- Taux de validation moyen
- Tableau des "meilleurs contributeurs"
- Export de données en PDF/CSV
- Visualisation de la répartition des retards

#### 11. **Profils utilisateurs améliorés** 👤
- Photo de profil personnalisée
- IBAN/compte bancaire du membre
- Historique complet consultable
- Badge de statut (contributeur régulier, etc.)

#### 12. **Fonctionnalités sociales**
- Commentaires sur chaque contribution
- Discussion entre membres
- Notifications dans l'app
- Centre d'aide/FAQ

#### 13. **Optimisations de performance**
- Lazy loading pour listes longues
- Cache local avec Hive
- Pagination des contributions anciennes
- Optimisation des images OCR

#### 14. **Internationalisation** 🌍
- **État actuel** : Tout en français dur-codé
- **À faire** : 
  - Fichiers i18n pour en/fr
  - Format numérique localisé
  - Support des dates localisées

#### 15. **Téléchargement de documents** 📄
- Télécharger reçu validé (PDF)
- Certificat de contribution
- Déclaration pour la taxe
- Export de l'historique

### 🛠️ **TECHNIQUE** (Refactorisation code)

#### 16. **Séparation des concerns**
**État actuel** : Tout dans `main.dart` (1500+ lignes)
**À faire** :
```
lib/
├── screens/
│   ├── dashboard_screen.dart
│   ├── receipt_scanner_screen.dart
│   ├── admin_screen.dart
│   └── login_screen.dart
├── services/
│   ├── ocr_service.dart
│   ├── firestore_service.dart
│   └── auth_service.dart
├── models/
│   ├── contribution.dart
│   ├── member.dart
│   └── delay.dart
├── widgets/
│   ├── member_card.dart
│   ├── contribution_card.dart
│   └── custom_inputs.dart
└── constants/
    ├── theme.dart
    └── members.dart
```

#### 17. **State Management**
- **Considérer** : Provider ou Riverpod pour meilleure gestion d'état
- **Bénéfices** : Moins de rebuilds, meilleure testabilité

#### 18. **Tests unitaires et intégration**
- Tests des services OCR
- Tests Firestore avec emulator
- Tests UI des composants
- Tests des validations

#### 19. **Logging et monitoring**
- Crashlytics pour erreurs
- Analytics des actions utilisateurs
- Performance monitoring

---

## 📱 Guide de développement

### Structure recommandée pour ajouter une nouvelle fonctionnalité

1. **Créer le modèle de données** si nécessaire
2. **Créer le service Firestore** pour opérations CRUD
3. **Créer le widget/écran**
4. **Intégrer dans la navigation**
5. **Tester avec données réelles**
6. **Optimiser et refactoriser**

### Commandes utiles

```bash
# Générer configuration Firebase
flutterfire configure

# Exécuter sur appareils spécifiques
flutter run -d chrome     # Web
flutter run -d emulator   # Android emulator

# Analyser code
flutter analyze

# Formatter
dart format lib/

# Publier
flutter build apk
flutter build ipa
```

### Debugging
- FirebaseFirestore Emulator
- Chrome DevTools
- Logcat pour Android

---

## 📞 Informations sur les membres

```dart
membersList = [
  {'name': 'Biigy', 'role': 'member', 'email': 'akaekuegnan@gmail.com'},
  {'name': 'Marco', 'role': 'member', 'email': 'marco@v12.com'},
  {'name': 'Israël', 'role': 'member', 'email': 'saykanisrael1994@gmail.com'},
  {'name': 'Maguid', 'role': 'controller', 'email': 'bkablam11@gmail.com'},
  {'name': 'Blanchard', 'role': 'member', 'email': 'bkablam20@gmail.com'},
]
```

**Objectif** : 250 000 F CFA  
**Par personne** : 50 000 F CFA  
**Contrôleur** : Maguid (seul accès admin)

---

## 📄 Licence & Contact

Application développée pour la gestion interne d'une tontine.
Tous droits réservés.

---

## 🎯 Résumé du projet

| Aspect | Status |
|--------|--------|
| Authentification | ✅ Complète |
| Dashboard temps réel | ✅ Complète |
| Scanner OCR | ✅ Fonctionnel |
| Validation admin | ✅ Complète |
| Gestion retards | ✅ Complète |
| Historique personnel | ⏳ À faire |
| Notifications push | ⏳ À faire |
| Tests | ⏳ À faire |
| Sécurité Firestore | ⏳ À faire |
| Internationalisation | ⏳ À faire |

**État global** : Application fonctionnelle et prête pour l'utilisation !  
**Prochaines étapes recommandées** : Notification, historique personnel, sécurité Firebase
