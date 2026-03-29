import 'dart:convert';

import 'package:http/http.dart' as http;

class AIService {
  // GOOGLE AI STUDIO CONFIG
  static const String _apiKey = "AIzaSyBoHVkxPo_N31-zqcelSXpaBN_WDGUfV5E";
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:generateContent";

  static final http.Client _client = http.Client();

  /// Gets the AI-generated response using the Google AI REST API.
  static Future<String> getAIResponse(
    String prompt, {
    String? homeworkContext,
    String? base64Image,
    String? mimeType,
  }) async {
    if (_apiKey.isEmpty) {
      return "API Key не найден!";
    }

    try {
      final String systemPrompt = """
Ты — умный и полезный ассистент по учёбе в электронном дневнике школьника.
Отвечай на вопросы пользователя в свободной форме. Будь максимально полезным и вежливым.
Не упоминай название модели, бренда или внутреннюю реализацию.
Не напоминай в каждом ответе про расписание, уроки, темы и домашние задания.
Используй данные дневника только когда это действительно помогает ответу или когда пользователь сам спрашивает об этом.
Если вопрос не связан с дневником, отвечай естественно и без навязчивых ссылок на дневник.

ДАННЫЕ ИЗ ТВОЕГО ДНЕВНИКА:
$homeworkContext

Если пользователь прислал изображение, сначала проанализируй его и опирайся на него в ответе.
""";

      final List<Map<String, dynamic>> parts = [
        {"text": "$systemPrompt\n\nВопрос: $prompt"}
      ];

      if (base64Image != null && base64Image.isNotEmpty) {
        parts.add({
          "inline_data": {
            "mime_type": mimeType ?? "image/jpeg",
            "data": base64Image,
          }
        });
      }

      final response = await _client
          .post(
            Uri.parse("$_apiUrl?key=$_apiKey"),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              "contents": [
                {"parts": parts}
              ],
              "generationConfig": {
                "temperature":
                    0.5, // Increased temperature for more natural conversation
                "maxOutputTokens": 4096,
              }
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ??
              'Пустой ответ.';
        }
        return 'Ответ не распознан.';
      } else {
        return "Ошибка API (${response.statusCode}). Проверь доступ к Google.";
      }
    } catch (e) {
      return "Ошибка связи: $e";
    }
  }

  static Future<Map<String, String?>> recognizeQuickHomework({
    required DateTime today,
    required String scheduleText,
    required String adminText,
  }) async {
    if (_apiKey.isEmpty) {
      return {'subject': null, 'deadline': null};
    }

    final todayText =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final prompt = '''
Сегодня $todayText. Расписание класса: $scheduleText
Администратор сказал: "$adminText".
Определи предмет и дату ближайшего подходящего урока.
Верни ТОЛЬКО JSON без пояснений: {"subject": "Алгебра", "deadline": "2026-04-04"}
Если не удалось определить — {"subject": null, "deadline": null}
''';

    try {
      final response = await _client
          .post(
            Uri.parse("$_apiUrl?key=$_apiKey"),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt}
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.1,
                "maxOutputTokens": 256,
              }
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        return {'subject': null, 'deadline': null};
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return {'subject': null, 'deadline': null};
      }

      final parsed = _extractQuickHomeworkJson(text);
      return {
        'subject': parsed['subject'] as String?,
        'deadline': parsed['deadline'] as String?,
      };
    } catch (_) {
      return {'subject': null, 'deadline': null};
    }
  }

  static Map<String, dynamic> _extractQuickHomeworkJson(String raw) {
    final trimmed = raw.trim();
    final fenced = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true)
        .firstMatch(trimmed);
    final candidate = fenced?.group(1) ??
        RegExp(r'\{.*\}', dotAll: true).firstMatch(trimmed)?.group(0) ??
        trimmed;

    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return <String, dynamic>{'subject': null, 'deadline': null};
  }
}
