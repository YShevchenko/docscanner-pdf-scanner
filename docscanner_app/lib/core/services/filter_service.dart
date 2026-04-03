import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum FilterType {
  original,
  blackAndWhite,
  grayscale,
  colorEnhance,
}

class FilterService {
  /// Apply [filter] to the image at [imagePath].
  /// Returns filtered image bytes as JPEG Uint8List.
  /// Returns null on error.
  static Future<Uint8List?> applyFilter(
      String imagePath, FilterType filter) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      switch (filter) {
        case FilterType.original:
          // Return original bytes unchanged
          return bytes;

        case FilterType.blackAndWhite:
          // Grayscale then threshold at 128 for hard B&W
          image = img.grayscale(image);
          image = _threshold(image, 128);

        case FilterType.grayscale:
          image = img.grayscale(image);

        case FilterType.colorEnhance:
          image = _colorEnhance(image);
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    } catch (e) {
      return null;
    }
  }

  /// Apply [filter] to already-loaded image bytes.
  static Uint8List? applyFilterToBytes(Uint8List bytes, FilterType filter) {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      switch (filter) {
        case FilterType.original:
          return bytes;
        case FilterType.blackAndWhite:
          image = img.grayscale(image);
          image = _threshold(image, 128);
        case FilterType.grayscale:
          image = img.grayscale(image);
        case FilterType.colorEnhance:
          image = _colorEnhance(image);
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    } catch (e) {
      return null;
    }
  }

  static img.Image _threshold(img.Image src, int threshold) {
    final result = img.Image(width: src.width, height: src.height);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        // For grayscale image, r == g == b
        final luma = pixel.r.toInt();
        final val = luma >= threshold ? 255 : 0;
        result.setPixelRgb(x, y, val, val, val);
      }
    }
    return result;
  }

  static img.Image _colorEnhance(img.Image src) {
    // Boost saturation by adjusting HSL and increase contrast
    img.Image result = img.adjustColor(
      src,
      saturation: 1.4,
      contrast: 1.2,
    );
    return result;
  }

  static String filterLabel(FilterType filter) {
    switch (filter) {
      case FilterType.original:
        return 'Original';
      case FilterType.blackAndWhite:
        return 'B&W';
      case FilterType.grayscale:
        return 'Grayscale';
      case FilterType.colorEnhance:
        return 'Color';
    }
  }
}
