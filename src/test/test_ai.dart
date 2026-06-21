// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final client = http.Client();
  const apiKey = "AIzaSyBoHVkxPo_N31-zqcelSXpaBN_WDGUfV5E";

  // Model in AIService: gemma-3-27b-it
  // Let's test a few models:
  final models = [
    'gemma-3-27b-it',
    'gemma2-27b-it',
    'gemma-7b-it',
    'gemini-1.5-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash'
  ];

  for (final model in models) {
    print('--- Testing model: $model ---');
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";

    try {
      final res = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Hello, write one word."}
              ]
            }
          ]
        }),
      );
      print('Status: ${res.statusCode}');
      print('Body: ${res.body}');
    } catch (e) {
      print('Error: $e');
    }
  }

  client.close();
}
