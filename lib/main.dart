import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'firebase_options.dart';

// --- CONSTANTES & DESIGN SYSTEM  ---
const List<Map<String, String>> membersList = [
  {
    'name': 'Biigy',
    'role': 'member',
    'email': 'akaekuegnan@gmail.com',
    'init': 'BI',
  },
  {
    'name': 'Marco',
    'role': 'member',
    'email': 'marcoeloye@gmail.com',
    'init': 'MA',
  },
  {
    'name': 'Israël',
    'role': 'member',
    'email': 'saykanisrael1994@gmail.com',
    'init': 'IS',
  },
  {
    'name': 'Maguid',
    'role': 'controller',
    'email':
        'bkablam20@gmail.com', //maguidouattara@gmail.com bkablam20@gmail.com
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
const double kGlobalTarget = 250000.0;
const kIndigo = Color(0xFF4F46E5);
const kEmerald = Color(0xFF10B981);
const kSlateBg = Color(0xFFF8FAFC);
const kSlateBorder = Color(0xFFE2E8F0);
const kDark = Color(0xFF0F172A);

Map<String, String>? currentUserData;

// --- FONCTION GLOBALE POUR LE JOURNAL D'ACTIVITÉ ---
Future<void> _logActivity(String message, String type) async {
  await FirebaseFirestore.instance.collection('activities').add({
    'message': message,
    'type': type,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

// --- NAVIGATION PRINCIPALE ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  void changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    bool isController = currentUserData?['role'] == 'controller';
    final List<Widget> screens = [
      const DashboardScreen(),
      const ReceiptHomePage(),
      if (isController) const AdminHistoryScreen(),
      const ActivityFeedScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: kIndigo,
        unselectedItemColor: Colors.grey,
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
          if (isController)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: "Admin",
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "Histo",
          ),
        ],
      ),
    );
  }
}

// --- ÉCRAN 1 : DASHBOARD ---
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          double totalCaisse = 0;
          Map<String, int> memberSums = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int amount = (data['amount'] ?? 0).toInt();
            if (data['status'] == 'validated') {
              totalCaisse += amount;
              memberSums[data['userName']] =
                  (memberSums[data['userName']] ?? 0) + amount;
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
                  final int val = memberSums[m['name']] ?? 0;
                  final int rest = (kTargetAmount - val).toInt();
                  int percent = ((val / kTargetAmount) * 100).toInt();
                  return _buildMemberRow(
                    m['init']!,
                    m['name']!,
                    percent,
                    val,
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
              value: (total / kGlobalTarget).clamp(0.0, 1.0),
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
    return GestureDetector(
      onTap: () => _showDelaySheet(context),
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

  void _showDelaySheet(BuildContext context) {
    final reasonController = TextEditingController();
    final dateController = TextEditingController();
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
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildPopupInput(
              reasonController,
              "RAISON DU RETARD",
              Icons.chat_bubble_outline,
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            _buildPopupInput(
              dateController,
              "DATE PRÉVUE (ex: 15/05)",
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
                await _logActivity(
                  "${currentUserData?['name']} a signalé un retard pour le ${dateController.text}.",
                  "delay",
                );
                Navigator.pop(context);
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

  Widget _buildMemberRow(
    String init,
    String name,
    int percent,
    int amount,
    int rest,
    NumberFormat f,
  ) {
    Color sColor = percent >= 100
        ? kEmerald
        : (percent > 0 ? Colors.orange : Colors.grey);
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
              Text(
                "$percent%",
                style: TextStyle(
                  color: sColor,
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

// --- ÉCRAN 2 : SCANNER & OCR ---
class ReceiptHomePage extends StatefulWidget {
  const ReceiptHomePage({super.key});
  @override
  State<ReceiptHomePage> createState() => _ReceiptHomePageState();
}

class _ReceiptHomePageState extends State<ReceiptHomePage> {
  String? _currentImagePath;
  Uint8List? _webImageBytes;
  final _issueDateController = TextEditingController();
  // final _typeController = TextEditingController();
  final _senderController = TextEditingController();
  // final _idController = TextEditingController();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  String _status = "Scanner un reçu...";
  bool _isProcessing = false;

  void _clear() {
    _issueDateController.clear();
    // _typeController.clear();
    _senderController.clear();
    //_idController.clear();
    _amountController.clear();
    _recipientController.clear();
    setState(() {
      _currentImagePath = null;
      _webImageBytes = null;
      _status = "Prêt.";
    });
  }

  Future<void> _pickAndProcess() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        if (kIsWeb) {
          setState(() {
            _webImageBytes = result.files.single.bytes;
            _status = "Mode Web : Remplissage manuel.";
          });
        } else {
          _currentImagePath = result.files.single.path;
          setState(() {
            _isProcessing = true;
            _status = "Analyse intelligente...";
          });
          final data = await OCRService.extractData(_currentImagePath!);
          setState(() {
            _issueDateController.text = data["issue_date"]!;
            //_typeController.text = data["type"]!;
            _senderController.text = data["sender"]!;
            //_idController.text = data["transaction_id"]!;
            _amountController.text = data["amount"]!;
            _recipientController.text = data["recipient"]!;
            _status = "✅ Vérifiez et enregistrez.";
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur sélection : $e");
    }
  }

  Future<void> _save() async {
    if (currentUserData == null || _amountController.text.isEmpty) return;
    Uint8List? bytes = kIsWeb
        ? _webImageBytes
        : (_currentImagePath != null
              ? await File(_currentImagePath!).readAsBytes()
              : null);
    if (bytes == null) return;

    setState(() => _isProcessing = true);
    try {
      img.Image? decoded = img.decodeImage(bytes);
      img.Image resized = img.copyResize(decoded!, width: 800);
      String base64Img = base64Encode(img.encodeJpg(resized, quality: 70));

      int amount =
          int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      await FirebaseFirestore.instance.collection('contributions').add({
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userName': currentUserData!['name'],
        'amount': amount,
        //'transactionId': _idController.text,
        'imageRaw': base64Img,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(
        "${currentUserData!['name']} a envoyé un reçu de $amount F.",
        "payment",
      );
      context.findAncestorStateOfType<_MainNavigationState>()?.changeTab(0);
      _clear();
    } catch (e) {
      debugPrint("Erreur sauvegarde: $e");
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
            //_buildInp(_typeController, "OPÉRATION"),
            _buildInp(_senderController, "EXPÉDITEUR"),
            //_buildInp(_idController, "N° TRANSACTION"),
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

// --- ÉCRAN 3 : ADMIN (VALIDATION AVEC ZOOM) ---
class AdminHistoryScreen extends StatelessWidget {
  const AdminHistoryScreen({super.key});

  void _showZoom(BuildContext context, String base64) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(base64Decode(base64), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kSlateBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "CONTRÔLE ",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            labelColor: kIndigo,
            indicatorColor: kIndigo,
            tabs: [
              Tab(text: "REÇUS"),
              Tab(text: "RETARDS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildContributionsTab(context), _buildDelaysTab()],
        ),
      ),
    );
  }

  Widget _buildContributionsTab(BuildContext context) {
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
          return const Center(child: Text("Tout est validé ! 😴"));
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return Card(
              margin: const EdgeInsets.only(bottom: 25),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: kSlateBorder),
              ),
              child: Column(
                children: [
                  if (data['imageRaw'] != null)
                    GestureDetector(
                      onTap: () => _showZoom(context, data['imageRaw']),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Container(
                          height: 250,
                          width: double.infinity,
                          color: kDark,
                          child: Image.memory(
                            base64Decode(data['imageRaw']),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ListTile(
                    title: Text(
                      data['userName'] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text("${data['amount']} F"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: kEmerald,
                            size: 30,
                          ),
                          onPressed: () =>
                              _update(id, 'validated', data['userName']),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 30,
                          ),
                          onPressed: () =>
                              _update(id, 'rejected', data['userName']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
        if (docs.isEmpty) return const Center(child: Text("Aucun retard."));
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
                  data['userName'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  "RAISON: ${data['reason']}\nPRÉVU: ${data['expectedDate']}",
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _update(String id, String status, String userName) async {
    await FirebaseFirestore.instance.collection('contributions').doc(id).update(
      {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
    );
    String msg = status == 'validated'
        ? "Maguid a validé le paiement de $userName."
        : "Maguid a rejeté le reçu de $userName.";
    await _logActivity(msg, status == 'validated' ? 'validation' : 'rejection');
  }
}

// --- ÉCRAN 4 : FIL D'ACTUALITÉ ---
class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSlateBg,
      appBar: AppBar(
        title: const Text(
          "FIL D'ACTUALITÉ ",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              IconData icon;
              Color color;
              switch (data['type']) {
                case 'validation':
                  icon = Icons.check_circle;
                  color = kEmerald;
                  break;
                case 'rejection':
                  icon = Icons.cancel;
                  color = Colors.red;
                  break;
                case 'delay':
                  icon = Icons.warning_rounded;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.info_rounded;
                  color = kIndigo;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kSlateBorder),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        data['message'] ?? "",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatelessWidget {
  final String? error;
  const LoginScreen({super.key, this.error});

  Future<void> _signIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '806151428631-b4u4add9uk5umc9c6o483efe2r6mbbvm.apps.googleusercontent.com',
      );
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

// --- SERVICE OCR (MOBILE) ---
class OCRService {
  static Future<Map<String, String>> extractData(String path) async {
    final input = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognized = await recognizer.processImage(input);
    String text = recognized.text;
    recognizer.close();
    Iterable<RegExpMatch> phones = RegExp(
      r"(?:225)?\s?(0[157]\d{8})",
    ).allMatches(text);
    List<String> pList = [];
    for (var m in phones) {
      if (!pList.contains(m.group(1)!)) pList.add(m.group(1)!);
    }
    String amount =
        RegExp(
          r"(\d{3,})\s*FCFA",
          caseSensitive: false,
        ).firstMatch(text)?.group(1) ??
        "";
    if (amount.isEmpty)
      amount =
          RegExp(
            r"transféré\s*\n\s*(\d+)",
            caseSensitive: false,
          ).firstMatch(text)?.group(1) ??
          "";
    String transID =
        RegExp(
          r"((?:PP|CO)\d{6}\.\d{4}\.[A-Z]\d+)",
          caseSensitive: false,
        ).firstMatch(text)?.group(1) ??
        "";
    String dateVal =
        RegExp(
          r"(\d{2}-\d{2}-\d{4}\s?,\s?\d{2}:\d{2})",
        ).firstMatch(text)?.group(0) ??
        "";
    String sender = "";
    String recipient = "";
    if (pList.length >= 2) {
      recipient = pList[0];
      sender = pList[1];
    } else if (pList.isNotEmpty) {
      sender = pList[0];
    }
    return {
      "issue_date": dateVal,
      "type": text.contains("P2P") ? "Transfert P2P" : "Transfert d'argent",
      "sender": sender,
      "transaction_id": transID
          .toUpperCase()
          .replaceAll(' ', '')
          .replaceAll(',', '.'),
      "transaction_date": dateVal,
      "amount": amount.replaceAll(' ', ''),
      "recipient": recipient,
    };
  }
}
