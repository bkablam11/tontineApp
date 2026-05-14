# 🏦 WARI-GBÊ - Application Tontine Mobile

**Système intelligent de gestion de tontine avec OCR, calcul de reliquat en temps réel et transparence totale via Fil d'Actualité.**

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Fonctionnalités implémentées](#fonctionnalités-implémentées)
3. [Intelligence Artificielle (OCR)](#intelligence-artificielle-ocr)
4. [Architecture & Stockage](#architecture--stockage)
5. [Déploiement & CI/CD](#déploiement--cicd)
6. [Roadmap & Améliorations](#roadmap)

---

## 🎯 Vue d'ensemble

**WARI-GBÊ** ("L'argent clair") est une solution Full-Stack développée avec Flutter pour un groupe de personnes. Elle transforme la gestion manuelle des cotisations en un processus automatisé, sécurisé et transparent.

### Chiffres clés du cycle
- **Objectif Global** : 250 000 F CFA
- **Cible Individuelle** : 50 000 F CFA / membre
- **Date limite** : Le 12 de chaque mois

---

## ✅ Fonctionnalités implémentées

### 1. Authentification & Rôles 🔐
- **Google Sign-In** : Accès simplifié et sécurisé.
- **Whitelist Strict** : Seuls les e-mails de la `membersList` (Biigy, Marco, Israël, Maguid, Blanchard) peuvent entrer.
- **Espace Contrôleur** : Interface spécifique pour **Maguid** permettant la validation humaine des preuves.

### 2. Dashboard Dynamique (Mur de Vérité) 📊
- **Caisse de Transparence** : Somme automatique de toutes les contributions validées.
- **Progression Individuelle** : 
    - Affichage de la progression en **pourcentage (0% à 100%)**.
    - Calcul en temps réel du **Reliquat** (Reste à payer).
    - Badge "SOLDÉ ✅" automatique dès l'atteinte de l'objectif.
- **Interaction** : Signalement de retard avec raison et date prévue via BottomSheet.

### 3. Fil d'actualité (Historique Global) 📜
- **Journal de bord** : Chaque action est tracée et visible par tous.
    - *"Blanchard a envoyé un reçu de 20.000 F."*
    - *"Maguid a validé le paiement de Biigy."*
    - *"Israël a signalé un retard pour le 15/05."*
- **Transparence** : Utilisation d'icônes de couleurs pour différencier les types d'activités (Succès, Alerte, Information).

### 4. Espace Admin (Contrôle ) 👨‍💼
- **Système d'onglets (Tabs)** :
    - **Onglet Reçus** : File d'attente des preuves avec affichage visuel du reçu.
    - **Onglet Retards** : Liste des membres ayant communiqué un empêchement.
- **Validation en 1 clic** : Boutons de validation/rejet avec mise à jour instantanée du Dashboard global.

---

## 🧠 Intelligence Artificielle (OCR)

L'application intègre un moteur de reconnaissance optique (**Google ML Kit**) optimisé pour les reçus **Orange Money (Version App)**.

### Extraction robuste (Regex)
- **ID Transaction** : Capture intelligente des formats `PP...` ou `CO...` même avec des espaces ou des virgules (corrigés automatiquement en points).
- **Montant** : Détection automatique des blocs financiers suivis de "FCFA".
- **Téléphones** : Filtrage strict sur 10 chiffres (commençant par 01, 05, 07) avec gestion de l'indicatif pays (+225).

---

## 🏗️ Architecture & Stockage

### Stockage Optimisé (Zéro Frais) 💸
Pour éviter les coûts de *Firebase Storage*, l'application utilise une stratégie de stockage hybride :
1. **Compression** : L'image est redimensionnée (800px) et compressée (70% Qualité JPG) côté client via le package `image`.
2. **Encodage Base64** : La preuve est convertie en texte et stockée directement dans le document Firestore.
3. **Affichage** : Reconversion instantanée du texte en image pour le contrôleur.

### Structure Firestore
- `contributions` : Détails des paiements, ID, et images Base64.
- `activities` : Logs du fil d'actualité.
- `delays` : Registre des retards signalés.

---

## 🚀 Déploiement & CI/CD

L'application est disponible sur trois supports :
1. **Android** : Via fichier APK.
2. **Web / iPhone** : Via l'URL [warigbe-app.web.app](https://warigbe-app.web.app).

### Automatisation GitHub
Le projet utilise **GitHub Actions**. À chaque `git push` sur la branche `main` :
- Un robot compile automatiquement la version Web.
- Le site est mis à jour instantanément sur **Firebase Hosting**.

---

## 📈 Roadmap (Améliorations futures)

- [ ] **Notifications Push** : Alertes directes sur le téléphone via OneSignal (Gratuit).
- [ ] **Multi-Opérateurs** : Ajout des Regex pour les reçus MTN MoMo et Moov Money.
- [ ] **Export PDF** : Génération d'un rapport de fin de cycle pour les archives du groupe.
- [ ] **Historique Perso** : Vue filtrée pour que chaque membre voie son propre relevé.

---

## 🛠 Commandes de Maintenance

**Mise à jour du code (Local -> GitHub -> Web) :**
```bash
git add .
git commit -m "Description du changement"
git push