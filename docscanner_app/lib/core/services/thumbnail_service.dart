import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import '../constants.dart';

class ThumbnailService {
  /// Generate a thumbnail from the image at [imagePath].
  /// Saves it to the app documents dir and returns the thumbnail path.
  static Future<String?> generateThumbnail(
      String imagePath, String pageId) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: AppConstants.thumbnailWidth,
        height: AppConstants.thumbnailHeight,
        interpolation: img.Interpolation.average,
      );

      final dir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory(path_pkg.join(dir.path, 'thumbnails'));
      if (!thumbDir.existsSync()) {
        thumbDir.createSync(recursive: true);
      }

      final thumbPath = path_pkg.join(thumbDir.path, '$pageId.jpg');
      await File(thumbPath)
          .writeAsBytes(img.encodeJpg(thumbnail, quality: 70));
      return thumbPath;
    } catch (e) {
      return null;
    }
  }

  /// Generate thumbnail bytes in memory (for first-page preview).
  static Future<Uint8List?> generateThumbnailBytes(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final thumbnail = img.copyResize(
        image,
        width: AppConstants.thumbnailWidth,
        height: AppConstants.thumbnailHeight,
        interpolation: img.Interpolation.average,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70));
    } catch (e) {
      return null;
    }
  }

  /// Delete a thumbnail file.
  static Future<void> deleteThumbnail(String? thumbPath) async {
    if (thumbPath == null) return;
    try {
      final file = File(thumbPath);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
