import 'dart:convert';

import 'package:http/http.dart' as http;

class AIService {
  // VERCEL PROXY CONFIG
  // URL вашего задеплоенного сервера на Vercel
  static const String _apiUrl =
      "https://vercel-proxy-delta-red.vercel.app/api/api/gemini";

  static final http.Client _client = http.Client();

  /// Gets the AI-generated response using the Google AI REST API.
  static Future<String> getAIResponse(
    String prompt, {
    String? homeworkContext,
    String? base64Image,
    String? mimeType,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
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

      List<Map<String, dynamic>> contents = [];

      if (chatHistory != null && chatHistory.isNotEmpty) {
        bool isFirstUserMessage = true;
        for (final msg in chatHistory) {
          final isUser = msg['isUser'] == true;
          final text = msg['text'] as String? ?? '';
          final image = msg['image'] as String?;

          if (!isUser && contents.isEmpty) {
            continue;
          }

          List<Map<String, dynamic>> parts = [];
          String messageText = text;

          if (isUser && isFirstUserMessage) {
            messageText = "$systemPrompt\n\n$messageText";
            isFirstUserMessage = false;
          }

          if (messageText.isNotEmpty) {
            parts.add({"text": messageText});
          }

          if (image != null && image.isNotEmpty) {
            parts.add({
              "inline_data": {
                "mime_type": mimeType ?? "image/jpeg",
                "data": image,
              }
            });
          }

          if (parts.isNotEmpty) {
            contents.add({
              "role": isUser ? "user" : "model",
              "parts": parts,
            });
          }
        }
      } else {
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
        contents.add({
          "role": "user",
          "parts": parts,
        });
      }

      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              "contents": contents,
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

  static Future<Map<String, dynamic>> recognizeQuickHomework({
    required DateTime today,
    required String scheduleText,
    required String adminText,
  }) async {


    final todayText =
        '${today.year}-${today.month.toString().padLeft(2, "0")}-${today.day.toString().padLeft(2, "0")}';

    final now = DateTime.now();
    final currentTimeText =
        '${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}';

    final weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье'
    ];
    final weekdayName = weekdays[today.weekday - 1];

    final prompt = '''
ПРАВИЛО ОШИБКИ:
Ты должен определить три поля: предмет, дату и задание.
Каждое поле заполняй независимо друг от друга.

Если предмет не найден в расписании → "subject": null
Если дата не указана или непонятна → "deadline": null  
Если задание не указано → "task": null

Если хотя бы одно поле равно null → добавь "fallback": true

Цель: Преобразовать произвольный текст в структурированный JSON.

Входные данные:
1. Текст: "$adminText"
2. Расписание ученика:
$scheduleText

Дополнительные данные:
- Текущая дата: $todayText
- Текущий день недели: $weekdayName
- Текущее время: $currentTimeText

Задачи:

1. Определи предмет
- Найди предмет ТОЛЬКО из расписания.
- Учитывай все формы слов (падежи, склонения, сокращения).
- Если предмет не найден -> subject = null

2. Определи дату сдачи (deadline)
Применяй правила по приоритету:
- "на сегодня" -> сегодняшняя дата
- "на завтра" -> завтрашняя дата
- "на следующий урок [предмет]":
  - Найди ближайший урок этого предмета ПОСЛЕ текущего момента
  - Если сегодня есть урок:
    - если он уже прошёл -> взять следующий день по расписанию
    - если ещё не прошёл -> взять сегодня
- "на [день недели]" (например: "на пятницу"):
  - ближайший такой день
  - если сегодня этот день -> взять СЛЕДУЮЩИЙ
- "на [число]" (например: "на 23"):
  - если число ещё впереди в текущем месяце -> текущий месяц
  - если уже прошло -> следующий месяц
- "через [N] дней" -> текущая дата + N дней
- Если дату определить невозможно -> deadline = null

3. Извлеки текст задания (task)
- Очисти текст от команд типа "добавь на [предмет]", "запиши по [предмету]" и указаний дат.
- Оставь только суть: действие + объект.
- Сделай первую букву заглавной.
- Если задания нет -> task = null

Формат ответа (СТРОГО):
Верни ТОЛЬКО JSON:
{"subject": "Название", "deadline": "YYYY-MM-DD", "task": "Текст задания", "fallback": false}

Примеры:
1. "Алгебра на завтра номера 45 46" -> {"subject": "Алгебра", "deadline": "...", "task": "Номера 45 46", "fallback": false}
2. "Задание на пятницу читать параграф" (без предмета) -> {"subject": null, "deadline": "...", "task": "Читать параграф", "fallback": true}
3. "Математика на 5 апреля" (без задания) -> {"subject": "Математика", "deadline": "...", "task": null, "fallback": true}

Никаких пояснений, только JSON.
''';

    try {
      final response = await _client
          .post(
            Uri.parse(_apiUrl),
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
                "maxOutputTokens": 2048,
              }
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        return {'subject': null, 'deadline': null, 'task': null};
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return {'subject': null, 'deadline': null, 'task': null};
      }

      final parsed = _extractQuickHomeworkJson(text);
      return {
        'subject': parsed['subject'] as String?,
        'deadline': parsed['deadline'] as String?,
        'task': parsed['task'] as String?,
        'fallback': parsed['fallback'] == true,
      };
    } catch (_) {
      return {
        'subject': null,
        'deadline': null,
        'task': null,
        'fallback': true
      };
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

    return <String, dynamic>{
      'subject': null,
      'deadline': null,
      'task': null,
      'fallback': true
    };
  }
}
