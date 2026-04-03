import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts text from the image at [imagePath] using on-device MLKit OCR.
  /// Returns empty string if no text found or on error.
  static Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } catch (e) {
      // OCR failure is non-fatal — document can still be saved without text
      return '';
    }
  }

  static void dispose() => _recognizer.close();
}
