import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'image_data.dart';

/// Quality for picked images (0-100).
const int pickedImageQuality = 55;

/// Max width/height for picked images in pixels.
const double pickedImageMaxSide = 1280;

/// Maximum total base64 characters allowed for embedded images.
const int maxEmbeddedImageChars = 700000;

/// Reads and encodes a local image file as a data URI string.
Future<String?> prepareEmbeddedImage(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return encodeInlineImageData(
      bytes,
      mimeType: inferImageMimeType(path),
    );
  } catch (e) {
    debugPrint('Image prepare error: $e');
  }
  return null;
}

/// Deletes any temporary picker files that reside in the system temp directory.
Future<void> cleanupTemporaryPickerFiles(Iterable<String> paths) async {
  try {
    final tempDirPath = (await getTemporaryDirectory()).path;
    final tempRoot = Directory(tempDirPath).absolute.path;

    for (final path in paths) {
      final absolutePath = File(path).absolute.path;
      if (!absolutePath.startsWith(tempRoot)) {
        continue;
      }

      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  } catch (e) {
    debugPrint('Temp cleanup error: $e');
  }
}
