import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'firebase_options.dart';

// --- CONSTANTES & DESIGN SYSTEM V12 ---
const List<Map<String, String>> MEMBERS = [
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
    'email': 'bkablam11@gmail.com',
    'init': 'MA',
  },
  {
    'name': 'Blanchard',
    'role': 'member',
    'email': 'bkablam20@gmail.com',
    'init': 'BL',
  },
];

const kIndigo = Color(0xFF4F46E5);
const kEmerald = Color(0xFF10B981);
const kSlateBg = Color(0xFFF8FAFC);
const kSlateBorder = Color(0xFFE2E8F0);
const kDark = Color(0xFF0F172A);

// Variable globale pour l'utilisateur actuel
Map<String, String>? currentUserData;

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
            final member = MEMBERS.firstWhere(
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

// --- ÉCRAN DE CONNEXION ---
class LoginScreen extends StatelessWidget {
  final String? error;
  const LoginScreen({super.key, this.error});

  Future<void> _signIn(BuildContext context) async {
    try {
      // 1. On initialise Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 2. On lance la fenêtre de sélection de compte
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Si l'utilisateur fait "retour" ou annule, on arrête là
      if (googleUser == null) return;

      // 3. On récupère les jetons d'authentification (tokens)
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. On crée l'identifiant pour Firebase
      // On utilise l'opérateur '!' car on est sûr que les tokens existent après l'étape 3
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // 5. Connexion finale à Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Note : Une fois connecté, le StreamBuilder dans main.dart
      // te redirigera automatiquement vers le Dashboard.
    } catch (e) {
      debugPrint("Erreur Google Sign-In: $e");

      // Affichage d'un message d'erreur propre pour l'utilisateur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Échec de la connexion : Vérifie ta connexion internet ou tes clés SHA-1",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              const Text(
                "\"L'ARGENT EST CLAIR, L'AMITIÉ EST FORTE.\"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.w800,
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
              const SizedBox(height: 40),
              const Divider(color: kSlateBorder),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "OBJECTIF",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "50.000 F",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "LIMITE MENSUELLE",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Le 12",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: kIndigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ReceiptHomePage(),
    const Center(child: Text("Histo")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: kIndigo,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded, size: 38),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: ""),
        ],
      ),
    );
  }
}

// --- ÉCRAN DASHBOARD ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
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
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tableau de Bord",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  "MAI 2026",
                  style: TextStyle(
                    color: kIndigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Text(
              "Émulation et suivi en temps réel",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _buildCaisse(),
            const SizedBox(height: 16),
            _buildDelay(),
            const SizedBox(height: 32),
            const Text(
              "Mur de Vérité",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            ...MEMBERS
                .map(
                  (m) =>
                      _buildMemberRow(m['init']!, m['name']!, "EN ATTENTE", 0),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaisse() {
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CAISSE DE TRANSPARENCE",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "10.000 F",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
                    "50.000 F",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.2,
              minHeight: 8,
              backgroundColor: kSlateBg,
              valueColor: AlwaysStoppedAnimation<Color>(kIndigo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelay() {
    return Container(
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
    );
  }

  Widget _buildMemberRow(String init, String name, String status, int amount) {
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
                status,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$amount F",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Text(
                "SUR 50.000 F",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
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

  Future<void> _save() async {
    if (_amountController.text.isEmpty) return;
    setState(() => _isProcessing = true);
    await FirebaseFirestore.instance.collection('contributions').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'userName': currentUserData?['name'],
      'amount':
          int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'transactionId': _idController.text,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contribution envoyée pour validation !")),
    );
    setState(() {
      _isProcessing = false;
      _status = "Terminé.";
    });
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
                        letterSpacing: 1.0,
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

// --- SERVICE OCR ---
class OCRService {
  static Future<Map<String, String>> extractData(String path) async {
    final input = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognized = await recognizer.processImage(input);
    String text = recognized.text;
    recognizer.close();

    Iterable<RegExpMatch> phones = RegExp(
      r"0[157][\s\d]{8,12}",
    ).allMatches(text);
    List<String> pList = phones
        .map((m) => m.group(0)!.trim().replaceAll(' ', ''))
        .toList();
    String rawID = RegExp(r"N°\s*([\w,.]+)").firstMatch(text)?.group(1) ?? "";

    return {
      "issue_date":
          RegExp(
            r"Issue date\s*[:]\s*([^\n]+)",
          ).firstMatch(text)?.group(1)?.trim() ??
          "",
      "type":
          RegExp(
            r"Type of transaction\s*\n\s*([^\n]+)",
          ).firstMatch(text)?.group(1)?.trim() ??
          "",
      "sender": pList.isNotEmpty ? pList[0] : "",
      "transaction_id": rawID.replaceAll(',', '.'),
      "amount":
          RegExp(
            r"CFA\s*F?\d+",
          ).firstMatch(text)?.group(0)?.replaceAll(RegExp(r'[^0-9]'), '') ??
          "",
      "recipient": pList.length > 1 ? pList[1] : "",
    };
  }
}
