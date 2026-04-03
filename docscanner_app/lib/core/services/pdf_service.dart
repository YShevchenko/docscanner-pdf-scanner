import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import '../constants.dart';

class PdfService {
  /// Compile a list of image paths into a PDF file.
  /// [quality]: 'low' | 'medium' | 'high' (controls JPEG compression)
  /// Saves PDF to app documents dir as {documentId}.pdf.
  /// Returns the saved file path.
  /// NO WATERMARK — FR-045 critical.
  static Future<String> compilePdf(
    String documentId,
    List<String> imagePaths, {
    String quality = AppConstants.defaultExportQuality,
  }) async {
    final pdfDoc = pw.Document(
      author: 'DocScan',
      title: documentId,
    );

    final jpegQuality =
        AppConstants.jpegQuality[quality] ?? AppConstants.jpegQuality['medium']!;

    for (final imagePath in imagePaths) {
      final imageBytes = await File(imagePath).readAsBytes();
      final compressedBytes = _compressJpeg(imageBytes, jpegQuality);

      final pdfImage = pw.MemoryImage(compressedBytes);

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path_pkg.join(dir.path, 'pdfs'));
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    final pdfPath = path_pkg.join(pdfDir.path, '$documentId.pdf');
    final pdfBytes = await pdfDoc.save();
    await File(pdfPath).writeAsBytes(pdfBytes);

    return pdfPath;
  }

  /// Get the path where a document's PDF would be stored.
  static Future<String> getPdfPath(String documentId) async {
    final dir = await getApplicationDocumentsDirectory();
    return path_pkg.join(dir.path, 'pdfs', '$documentId.pdf');
  }

  /// Delete a document's PDF file.
  static Future<void> deletePdf(String documentId) async {
    try {
      final pdfPath = await getPdfPath(documentId);
      final file = File(pdfPath);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// Compress JPEG bytes at given quality (0–100).
  /// Decodes the image and re-encodes as JPEG at the requested quality.
  static Uint8List _compressJpeg(Uint8List bytes, int quality) {
    // At max quality, skip the decode/encode cycle to preserve original data.
    if (quality >= 95) return bytes;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes; // unrecognised format — return as-is

    return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }
}
