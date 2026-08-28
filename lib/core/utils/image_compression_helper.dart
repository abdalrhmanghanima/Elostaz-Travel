import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageCompressionHelper {
  // Maximum Base64 string length (~450KB binary, safely below 1MB Firestore limit)
  static const int maxBase64Length = 600000;

  /// Compresses a [file] and returns its Base64 string.
  /// If the image is too large, it iteratively resizes it until it fits within [maxBase64Length].
  static Future<String?> compressAndEncodeBase64(
    File file, {
    int initialMaxDimension = 1400,
  }) async {
    if (!await file.exists()) {
      developer.log('File does not exist: ${file.path}', name: 'ImageCompression');
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      // If file is already very small (e.g. < 200KB), check direct base64
      if (bytes.lengthInBytes <= 250 * 1024) {
        final directBase64 = base64Encode(bytes);
        if (directBase64.length <= maxBase64Length) {
          return directBase64;
        }
      }

      int targetDimension = initialMaxDimension;
      String? bestBase64;

      // Attempt resizing with progressively smaller dimensions if needed
      for (int attempt = 0; attempt < 4; attempt++) {
        final compressedBytes = await _resizeImage(bytes, targetDimension);
        if (compressedBytes != null) {
          final encoded = base64Encode(compressedBytes);
          if (encoded.length <= maxBase64Length) {
            return encoded;
          }
          bestBase64 = encoded;
        }
        // Reduce dimension for next attempt
        targetDimension = (targetDimension * 0.7).round();
      }

      // If best attempt is still within 900KB, use it; otherwise reject
      if (bestBase64 != null && bestBase64.length <= 900000) {
        return bestBase64;
      }

      developer.log('Image exceeds maximum allowed Firestore document size after compression', name: 'ImageCompression');
      return null;
    } catch (e, st) {
      developer.log('Error compressing image: $e', error: e, stackTrace: st, name: 'ImageCompression');
      return null;
    }
  }

  static Future<Uint8List?> _resizeImage(Uint8List sourceBytes, int maxDimension) async {
    try {
      final codec = await ui.instantiateImageCodec(sourceBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      int width = image.width;
      int height = image.height;

      if (width <= maxDimension && height <= maxDimension) {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      }

      if (width > height) {
        height = (height * maxDimension / width).round();
        width = maxDimension;
      } else {
        width = (width * maxDimension / height).round();
        height = maxDimension;
      }

      final resizedCodec = await ui.instantiateImageCodec(
        sourceBytes,
        targetWidth: width,
        targetHeight: height,
      );
      final resizedFrame = await resizedCodec.getNextFrame();
      final resizedImage = resizedFrame.image;

      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      developer.log('Resize error: $e', name: 'ImageCompression');
      return null;
    }
  }
}
