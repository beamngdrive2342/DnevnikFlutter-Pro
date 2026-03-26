import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  // OPENROUTER CONFIG
  static const String _apiKey =
      "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";
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";
  // The new Vision-Language model from NVIDIA
  static const String _model = "nvidia/nemotron-nano-12b-v2-vl:free";

  static final http.Client _client = http.Client();

  /// Gets the AI-generated response using the OpenRouter API.
  static Future<String> getAIResponse(
    String prompt, {
    String? homeworkContext,
    String? base64Image,
    String? mimeType,
  }) async {
    if (_apiKey.isEmpty) return "API Key не найден!";

    try {
      final String systemPrompt = """
Ты — помощник по учёбе в электронном дневнике школьника на базе NVIDIA Nemotron Nano VL. 
Объясняй решения задач понятным языком, как будто объясняешь другу.

ДАННЫЕ ИЗ ДНЕВНИКА ШКОЛЬНИКА:
$homeworkContext

ПРАВИЛА ОФОРМЛЕНИЯ РЕШЕНИЙ (КРИТИЧНО):
1. НИКОГДА не пиши формулы в одну строку через знаки умножения.
2. ВСЕГДА разбивай решение на пронумерованные шаги (Шаг 1, Шаг 2...).
3. Каждый шаг с пояснением (Что, Почему, Результат).
4. Числа вставляй прямо в текст.
5. Ответ выделяй отдельно в конце.

ВАЖНО: Пиши ТОЛЬКО чистым текстом. НИКАКОГО LaTeX (символы \\, {, }, frac ЗАПРЕЩЕНЫ). Пиши на русском.
""";

      final List<Map<String, dynamic>> messages = [
        {"role": "system", "content": systemPrompt},
        {
          "role": "user",
          "content": [
            if (prompt.isNotEmpty) {"type": "text", "text": prompt},
            if (base64Image != null && base64Image.isNotEmpty)
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:${mimeType ?? 'image/jpeg'};base64,$base64Image"
                }
              }
          ]
        },
      ];

      debugPrint("AIService: Request to OpenRouter using $_model...");

      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://dnevnik-app.local',
              'X-Title': 'Dnevnik App',
            },
            body: jsonEncode({
              "model": _model,
              "messages": messages,
              "temperature": 0.35,
              "max_tokens": 1500,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String content = data['choices'][0]['message']['content'];

          // Safety cleanup
          content = content.replaceAll(RegExp(r'\\\[|\\\]|\\\(|\\\)'), '');
          content = content
              .replaceAll('\\', '')
              .replaceAll('{', '')
              .replaceAll('}', '');

          return content.trim();
        }
        return 'Ответа не получено.';
      } else {
        debugPrint(
            'OpenRouter ERROR: ${response.statusCode} - ${response.body}');
        return "Ошибка ${response.statusCode}.";
      }
    } catch (e) {
      if (e.toString().contains("TimeoutException")) {
        return "ИИ не уложился в 90 секунд. Повтори позже.";
      }
      return "Ошибка: $e";
    }
  }
}
