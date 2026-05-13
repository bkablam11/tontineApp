import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  static Future<Map<String, String>> extractData(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String fullText = recognizedText.text;
    textRecognizer.close();

    // --- EXTRACTION DES TÉLÉPHONES (On cherche tous les numéros 07, 05, 01) ---
    // Cette regex cherche des blocs de 10 chiffres avec ou sans espaces
    Iterable<RegExpMatch> phoneMatches = RegExp(
      r"0[157][\s\d]{8,12}",
    ).allMatches(fullText);
    List<String> phones = phoneMatches.map((m) => m.group(0)!.trim()).toList();

    // --- EXTRACTION DU NUMÉRO DE TRANSACTION ---
    String rawID =
        RegExp(r"N°\s*([\w,.]+)").firstMatch(fullText)?.group(1) ?? "";
    // On remplace les virgules par des points comme demandé
    String cleanID = rawID.replaceAll(',', '.');

    return {
      // 1. Date d'émission
      "issue_date":
          RegExp(
            r"Issue date\s*[:]\s*([^\n]+)",
            caseSensitive: false,
          ).firstMatch(fullText)?.group(1)?.trim() ??
          "",

      // 2. Type (Money transfer, etc.)
      "type":
          RegExp(
            r"Type of transaction\s*\n\s*([^\n]+)",
            caseSensitive: false,
          ).firstMatch(fullText)?.group(1)?.trim() ??
          "",

      // 3. Expéditeur : c'est le 1er numéro de téléphone trouvé
      "sender": phones.isNotEmpty ? phones[0] : "",

      // 4. Numéro de transaction (corrigé avec des points)
      "transaction_id": cleanID,

      // 5. Date réelle de la transaction
      "transaction_date":
          RegExp(
            r"Transaction[\s\S]*?Date\s*([^\n]+)",
            caseSensitive: false,
          ).firstMatch(fullText)?.group(1)?.trim() ??
          "",

      // 6. Montant (Recherche le bloc contenant CFA)
      "amount": RegExp(r"CFA\s*F?\d+").firstMatch(fullText)?.group(0) ?? "",

      // 7. Bénéficiaire : c'est le 2ème numéro de téléphone trouvé
      "recipient": phones.length > 1 ? phones[1] : "",
    };
  }
}
