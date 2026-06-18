import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

bool isRemoteImageUrl(String source) =>
    source.startsWith('http://') || source.startsWith('https://');

bool isInlineImageData(String source) => source.startsWith('data:image/');

String inferImageMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

String encodeInlineImageData(
  Uint8List bytes, {
  String mimeType = 'image/jpeg',
}) {
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Uint8List? decodeInlineImageData(String source) {
  if (!isInlineImageData(source)) {
    return null;
  }

  final commaIndex = source.indexOf(',');
  if (commaIndex <= 0 || commaIndex >= source.length - 1) {
    return null;
  }

  try {
    return base64Decode(source.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> loadImageBytes(
  String source, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 12),
}) async {
  if (source.isEmpty) {
    return null;
  }

  if (isInlineImageData(source)) {
    return decodeInlineImageData(source);
  }

  if (isRemoteImageUrl(source)) {
    try {
      final response = await (client ?? http.Client())
          .get(Uri.parse(source))
          .timeout(timeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return Uint8List.fromList(response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  try {
    final file = File(source);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  } catch (_) {
    return null;
  }
}
