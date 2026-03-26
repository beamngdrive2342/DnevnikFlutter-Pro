import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  // OpenRouter API Key and Model configuration
  static const String _apiKey = "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";
  static const String _model = "nvidia/nemotron-3-super-120b-a12b:free";
  static const String _apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  static final http.Client _client = http.Client();

  /// Gets the AI-generated response using the OpenRouter API.
  static Future<String> getAIResponse(String prompt) async {
    // If we have a placeholder, just tell the user to add the key.
    if (_apiKey.isEmpty) {
      return "Пожалуйста, добавь свой OpenRouter API Key в AIService, чтобы я мог по-настоящему помогать тебе с учёбой!";
    }

    try {
      final response = await _client.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json; charset=utf-8',
          'HTTP-Referer': 'https://github.com/dnevnik-app', 
          'X-Title': 'Dnevnik10A', 
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content": """
Ты — умный и дружелюбный помощник ученика 10-го класса в школьном дневнике. 
Твоя задача — помогать со школьными предметами, объяснять темы и давать советы по учёбе. 

КРИТИЧЕСКИ ВАЖНЫЕ ПРАВИЛА ОФОРМЛЕНИЯ:
1. НИКОГДА не используй LaTeX (формат \\frac{}{}, \\sqrt{} и т.д.). Твой ответ должен быть легко читаемым в обычном текстовом поле.
2. Для формул используй простые символы: 
   - Вместо дробей пиши (a + b) / c.
   - Вместо корня пиши √x или корень(x).
   - Вместо степеней пиши x^2 или x^3.
3. Не используй сложные таблицы или Markdown-разметку, которую трудно читать без специального рендерера. 
4. Будь кратким, полезным и вдохновляющим.
5. Если тебя задают вопрос про ДЗ, напомни, что актуальные задания всегда есть на главной странице.
"""
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.5, // Reduced temperature for more stable math formatting
          "max_tokens": 1000,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final bodyBytes = response.bodyBytes;
        final decodedBody = utf8.decode(bodyBytes);
        final data = jsonDecode(decodedBody);
        
        // OpenRouter / OpenAI format: data['choices'][0]['message']['content']
        if (data['choices'] != null &&
            data['choices'].isNotEmpty &&
            data['choices'][0]['message'] != null) {
          return data['choices'][0]['message']['content']?.trim() ??
              'Я не совсем уверен, что ответить. Попробуй спросить по-другому?';
        }
        return 'Ой, кажется, мой мозг на секунду отключился. Попробуешь еще раз?';
      } else {
        debugPrint('OpenRouter API Error: ${response.statusCode} - ${response.body}');
        return "Ошибка при связи с OpenRouter (HTTP ${response.statusCode}). Проверь свой ключ и баланс.";
      }
    } on SocketException {
      return "Похоже, интернета нет. Я смогу ответить, когда появится соединение!";
    } catch (e) {
      debugPrint("AIService Exception: $e");
      return "Произошла техническая ошибка. Давай попробуем снова?";
    }
  }
}
