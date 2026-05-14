import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:image/image.dart'
    as img; // Ajoute ce package : flutter pub add image
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Pour Uint8List
// import 'notification_service.dart'; // TODO: Notifications feature - to be implemented later

// --- CONSTANTES & DESIGN SYSTEM ---
const List<Map<String, String>> membersList = [
  {
    'name': 'Biigy',
    'role': 'member',
    'email': 'akaekuegnan@gmail.com',
    'init': 'BI',
  },
  {'name': 'Marco', 'role': 'member', 'email': 'marco@v12.com', 'init': 'MA'},
  {
    'name': 'Israël',
    'role': 'member',
    'email': 'saykanisrael1994@gmail.com',
    'init': 'IS',
  },
  {
    'name': 'Maguid',
    'role': 'controller',
    'email': 'maguidouattara@gmail.com',
    'init': 'MA',
  },
  {
    'name': 'Blanchard',
    'role': 'member',
    'email': 'bkablam11@gmail.com',
    'init': 'BL',
  },
];

const double kTargetAmount = 50000.0;
const kIndigo = Color(0xFF4F46E5);
const kEmerald = Color(0xFF10B981);
const kSlateBg = Color(0xFFF8FAFC);
const kSlateBorder = Color(0xFFE2E8F0);
const kDark = Color(0xFF0F172A);

Map<String, String>? currentUserData;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: Notifications feature - to be implemented later
  // await NotificationService.init();

  runApp(const WariGbeApp());
}

class WariGbeApp extends StatelessWidget {
  const WariGbeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WARI-GBÊ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kSlateBg,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final email = snapshot.data!.email;
            final member = membersList.firstWhere(
              (m) => m['email'] == email,
              orElse: () => {},
            );
            if (member.isNotEmpty) {
              currentUserData = member;
              return const MainNavigation();
            } else {
              FirebaseAuth.instance.signOut();
              return const LoginScreen(
                error: "Accès refusé : Membre non reconnu.",
              );
            }
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

// --- NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // --- AJOUTE CETTE MÉTHODE POUR PERMETTRE LE CHANGEMENT D'ONGLET ---
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isController = currentUserData?['role'] == 'controller';

    final List<Widget> screens = [
      const DashboardScreen(),
      const ReceiptHomePage(),
      if (isController) const AdminHistoryScreen(),
      if (!isController)
        const Center(child: Text("Historique personnel bientôt disponible")),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: kIndigo,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Board",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded, size: 38),
            label: "Scanner",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              isController
                  ? Icons.admin_panel_settings_rounded
                  : Icons.history_rounded,
            ),
            label: isController ? "Admin" : "Histo",
          ),
        ],
      ),
    );
  }
}

// --- ÉCRAN DASHBOARD DYNAMIQUE ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat("#,###", "fr_FR");

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contributions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("Erreur de chargement"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          double totalCaisse = 0;
          Map<String, int> memberSums = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int amount = (data['amount'] ?? 0).toInt();
            if (data['status'] == 'validated') {
              totalCaisse += amount;
              String uName = data['userName'] ?? '';
              memberSums[uName] = (memberSums[uName] ?? 0) + amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TONTINE",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "WARI-GBÊ",
                          style: TextStyle(
                            color: kDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentUserData?['role']?.toUpperCase() ?? "",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              currentUserData?['name'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _buildCaisseCard(totalCaisse, f),
                const SizedBox(height: 16),
                _buildDelay(context),
                const SizedBox(height: 32),
                const Text(
                  "Mur de Vérité",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                ...membersList.map((m) {
                  final int validatedAmount = memberSums[m['name']] ?? 0;
                  final int rest = (kTargetAmount - validatedAmount).toInt();

                  // CALCUL DU POURCENTAGE
                  double doublePercent =
                      (validatedAmount / kTargetAmount) * 100;
                  int percentage = doublePercent
                      .toInt(); // On garde un chiffre entier (ex: 17%)

                  return _buildMemberRow(
                    m['init']!,
                    m['name']!,
                    percentage, // On envoie le pourcentage au lieu du texte
                    validatedAmount,
                    rest < 0 ? 0 : rest,
                    f,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDelaySheet(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController dateController =
        TextEditingController(); // Nouveau champ

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SIGNALER UN RETARD",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: kDark,
              ),
            ),
            const SizedBox(height: 20),

            // CHAMP RAISON
            _buildPopupInput(
              reasonController,
              "RAISON DU RETARD",
              Icons.chat_bubble_outline,
              maxLines: 2,
            ),
            const SizedBox(height: 15),

            // CHAMP DATE PRÉVUE
            _buildPopupInput(
              dateController,
              "DATE PRÉVUE DE PAIEMENT (ex: 15/05)",
              Icons.calendar_today,
            ),

            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.isEmpty ||
                    dateController.text.isEmpty)
                  return;

                await FirebaseFirestore.instance.collection('delays').add({
                  'userName': currentUserData?['name'],
                  'reason': reasonController.text,
                  'expectedDate': dateController.text,
                  'status': 'reported',
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Retard signalé à Maguid.")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kIndigo,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "ENVOYER L'INFO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Petit widget d'aide pour le design des inputs dans le popup
  Widget _buildPopupInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kIndigo),
        filled: true,
        fillColor: kSlateBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCaisseCard(double total, NumberFormat f) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kSlateBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kIndigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CAISSE DE TRANSPARENCE",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${f.format(total)} F",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "FÊTE CYCLE",
                    style: TextStyle(
                      fontSize: 9,
                      color: kIndigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "250.000 F",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (total / kTargetAmount).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: kSlateBg,
              valueColor: const AlwaysStoppedAnimation<Color>(kIndigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelay(BuildContext context) {
    // Ajoute le context ici
    return GestureDetector(
      onTap: () => _showDelaySheet(context), // Ouvre le formulaire au clic
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSlateBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kSlateBorder),
        ),
        child: const Column(
          children: [
            Text(
              "UN EMPÊCHEMENT ? COMMUNIQUEZ.",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: kIndigo, size: 14),
                SizedBox(width: 6),
                Text(
                  "SIGNALER UN RETARD",
                  style: TextStyle(
                    color: kIndigo,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(
    String init,
    String name,
    int percentage,
    int amount,
    int rest,
    NumberFormat f,
  ) {
    // CHOIX DE LA COULEUR SELON LA PROGRESSION
    Color progressColor;
    if (percentage >= 100) {
      progressColor = kEmerald; // Vert si fini
    } else if (percentage > 0) {
      progressColor = Colors.orange; // Orange si commencé
    } else {
      progressColor = Colors.grey; // Gris si rien payé
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kDark,
            radius: 20,
            child: Text(
              init,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              // AFFICHAGE DU POURCENTAGE
              Text(
                "$percentage%",
                style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${f.format(amount)} F",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              Text(
                amount >= kTargetAmount
                    ? "SOLDÉ ✅"
                    : "RESTE : ${f.format(rest)} F",
                style: TextStyle(
                  color: amount >= kTargetAmount
                      ? kEmerald
                      : kIndigo.withOpacity(0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- ÉCRAN OCR ---
class ReceiptHomePage extends StatefulWidget {
  const ReceiptHomePage({super.key});
  @override
  State<ReceiptHomePage> createState() => _ReceiptHomePageState();
}

class _ReceiptHomePageState extends State<ReceiptHomePage> {
  String? _currentImagePath;
  final _issueDateController = TextEditingController();
  final _typeController = TextEditingController();
  final _senderController = TextEditingController();
  final _idController = TextEditingController();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();

  String _status = "Prêt à scanner un reçu...";
  bool _isProcessing = false;

  Future<void> _pickAndProcess() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      _currentImagePath = result.files.single.path;
      setState(() {
        _isProcessing = true;
        _status = "Analyse intelligente...";
      });
      final data = await OCRService.extractData(result.files.single.path!);
      setState(() {
        _issueDateController.text = data["issue_date"]!;
        _typeController.text = data["type"]!;
        _senderController.text = data["sender"]!;
        _idController.text = data["transaction_id"]!;
        _amountController.text = data["amount"]!;
        _recipientController.text = data["recipient"]!;
        _status = "✅ Vérifiez les informations.";
        _isProcessing = false;
      });
    }
  }

  // --- FONCTION POUR VIDER LES CHAMPS ---
  void _clear() {
    _issueDateController.clear();
    _typeController.clear();
    _senderController.clear();
    _idController.clear();
    _amountController.clear();
    _recipientController.clear();
    setState(() {
      _currentImagePath = null;
      _status = "Prêt à scanner un reçu...";
    });
  }

  Future<void> _save() async {
    // Sécurité 1 : Vérifier si l'utilisateur est bien identifié dans ta liste MEMBERS
    if (currentUserData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erreur : Utilisateur non identifié. Reconnectez-vous.",
          ),
        ),
      );
      return;
    }

    if (_amountController.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le montant et l'ID sont obligatoires")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Charger l'image originale
      File imageFile = File(_currentImagePath!);
      List<int> imageBytes = await imageFile.readAsBytes();

      // 2. COMPRESSION (pour être sûr que ça passe dans Firestore gratuitement)
      img.Image? decodedImage = img.decodeImage(Uint8List.fromList(imageBytes));
      // On redimensionne l'image (800px de large c'est largement assez pour lire un reçu)
      img.Image resizedImage = img.copyResize(decodedImage!, width: 800);
      // On compresse en JPG (qualité 70%)
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 70);

      // 3. Transformer en texte (Base64)
      String base64Image = base64Encode(compressedBytes);

      // 4. Envoi à Firestore
      await FirebaseFirestore.instance.collection('contributions').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userName': currentUserData!['name'],
        'amount':
            int.tryParse(
              _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0,
        'transactionId': _idController.text,
        'imageRaw': base64Image, // L'image est ici !
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TODO: Notifications feature - to be implemented later
      // await NotificationService.showInstantNotification(
      //   "Reçu bien envoyé ! ",
      //   "Ta cotisation a été transmise à Maguid pour validation.",
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reçu envoyé pour validation !")),
        );

        // --- AJOUTE CES LIGNES ICI POUR LA REDIRECTION ---
        // On cherche le parent MainNavigation et on lui dit d'aller à l'onglet 0
        final mainNav = context.findAncestorStateOfType<_MainNavigationState>();
        if (mainNav != null) {
          mainNav.changeTab(0); // 0 correspond à l'onglet "Board"
        }
      }

      // Redirection après succès
      final mainNav = context.findAncestorStateOfType<_MainNavigationState>();
      if (mainNav != null) mainNav.changeTab(0);
    } catch (e) {
      print("Erreur réelle : $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CHARGER UNE PREUVE",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: kSlateBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isProcessing ? null : _pickAndProcess,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: kDark,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "SÉLECTIONNER LE REÇU",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isProcessing) const LinearProgressIndicator(color: kIndigo),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildInp(_issueDateController, "DATE ÉMISSION"),
            _buildInp(_typeController, "OPÉRATION"),
            _buildInp(_senderController, "EXPÉDITEUR"),
            _buildInp(_idController, "N° TRANSACTION"),
            _buildInp(_amountController, "MONTANT (CFA)"),
            _buildInp(_recipientController, "BÉNÉFICIAIRE"),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kIndigo,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "ENREGISTRER LA COTISATION",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInp(TextEditingController ctrl, String lbl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        decoration: InputDecoration(
          labelText: lbl,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kSlateBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kIndigo, width: 2),
          ),
        ),
      ),
    );
  }
}

// --- ÉCRAN 3 : ADMIN (ESPACE VALIDATION MAGUID) ---
class AdminHistoryScreen extends StatelessWidget {
  const AdminHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 onglets : Reçus et Retards
      child: Scaffold(
        backgroundColor: kSlateBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "CONTRÔLE",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: kIndigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kIndigo,
            tabs: [
              Tab(text: "REÇUS À VALIDER"),
              Tab(text: "RETARDS SIGNALÉS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildContributionsTab(), // Ton code actuel avec images
            _buildDelaysTab(), // Nouvel onglet pour les retards
          ],
        ),
      ),
    );
  }

  // --- ONGLET 1 : LES REÇUS (Ton code existant optimisé) ---
  Widget _buildContributionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contributions')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("Aucun reçu à valider 😴"));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return _buildAdminCard(id, data);
          },
        );
      },
    );
  }

  // --- ONGLET 2 : LES RETARDS ---
  Widget _buildDelaysTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('delays')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("Aucun retard signalé."));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                title: Text(
                  data['userName'] ?? "Membre",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "RAISON : ${data['reason']}",
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "PAIEMENT PRÉVU : ${data['expectedDate']}",
                      style: const TextStyle(
                        color: kIndigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.info_outline, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }

  // Widget pour la carte de contribution (avec image Base64)
  Widget _buildAdminCard(String id, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          if (data['imageRaw'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.memory(
                base64Decode(data['imageRaw']),
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
                color: kDark,
                colorBlendMode: BlendMode.dstOver,
              ),
            ),
          ListTile(
            title: Text(
              data['userName'] ?? "",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              "${data['amount']} F - ID: ${data['transactionId']}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: kEmerald,
                    size: 30,
                  ),
                  onPressed: () => _update(id, 'validated'),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                  onPressed: () => _update(id, 'rejected'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _update(String id, String status) async {
    FirebaseFirestore.instance.collection('contributions').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // TODO: Notifications feature - to be implemented later
    // String titre = status == 'validated' ? "Félicitations ! " : "Reçu Refusé ";
    // String message = status == 'validated'
    //     ? "Le paiement a été validé avec succès."
    //     : "Le reçu ne semble pas conforme. Recommencez.";
    //
    // await NotificationService.showInstantNotification(titre, message);
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatelessWidget {
  final String? error;
  const LoginScreen({super.key, this.error});

  Future<void> _signIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Erreur Google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: kDark.withOpacity(0.05), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kIndigo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "W",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "WARI-GBÊ",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => _signIn(context),
                icon: const Icon(Icons.account_circle, color: kDark),
                label: const Text(
                  "Accès Membre",
                  style: TextStyle(fontWeight: FontWeight.w900, color: kDark),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: kSlateBorder),
                  ),
                  elevation: 0,
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SERVICE OCR DÉFINITIF (ORANGE MONEY V12) ---
class OCRService {
  static Future<Map<String, String>> extractData(String path) async {
    final input = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognized = await recognizer.processImage(input);
    String text = recognized.text;
    recognizer.close();

    // 1. EXTRACTION DES TÉLÉPHONES
    Iterable<RegExpMatch> phones = RegExp(
      r"0[157][\s\d]{8,12}",
    ).allMatches(text);
    List<String> pList = phones
        .map((m) => m.group(0)!.trim().replaceAll(' ', ''))
        .toList();

    // 2. EXTRACTION DU NUMÉRO DE TRANSACTION (Version Ultra-Robuste)
    // On capture tout ce qui ressemble à l'ID, même s'il y a des espaces à l'intérieur
    RegExp idRegex = RegExp(
      r"(?:N'|N°|No|N)?\s*((?:PP|CO)[A-Z0-9,\s]{8,})",
      caseSensitive: false,
    );
    String rawID = idRegex.firstMatch(text)?.group(1) ?? "";

    // NETTOYAGE : Enlève les espaces, change les virgules en points, met en majuscules
    String cleanID = rawID
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .toUpperCase();

    // 3. EXTRACTION DU MONTANT
    String amountRaw =
        RegExp(
          r"CFA\s*F?\s*(\d+[\s\d]*)",
          caseSensitive: false,
        ).firstMatch(text)?.group(1) ??
        "";

    return {
      "issue_date":
          RegExp(
            r"Issue date\s*[:]\s*([^\n]+)",
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.trim() ??
          "",
      "type":
          RegExp(
            r"Type of transaction\s*\n\s*([^\n]+)",
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.trim() ??
          "",
      "sender": pList.isNotEmpty ? pList[0] : "",
      "transaction_id":
          cleanID, // Maintenant il affichera PP260510.2122.B02254 en entier
      "transaction_date":
          RegExp(
            r"Transaction[\s\S]*?Date\s*([^\n]+)",
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.trim() ??
          "",
      "amount": amountRaw.replaceAll(' ', '').trim(),
      "recipient": pList.length > 1 ? pList[1] : "",
    };
  }
}
