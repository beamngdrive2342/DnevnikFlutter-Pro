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
      return {'subject': null, 'deadline': null, 'task': null};
    }

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
Ты — интеллектуальный парсер школьных заданий. Твоя задача — строго и точно извлекать из входного текста три поля: предмет, дату сдачи и само задание.

Цель: Преобразовать произвольный текст (часто с лишними словами) в структурированный JSON строго заданного формата.

Входные данные:
1. Текст администратора: "$adminText"
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
  - Пример: "алгебру", "алгебре", "алгебры" -> "Алгебра"
- НЕ придумывай предметы.
- Если предмет не найден -> subject = null

2. Определи дату сдачи
Применяй правила строго по приоритету:
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
- "на [день недели] [предмет]" (например: "на пятничную алгебру"):
  - найти ближайший день недели, где есть этот предмет
- "на [число]" (например: "на 23"):
  - если число ещё впереди в текущем месяце -> текущий месяц
  - если уже прошло -> следующий месяц
- "на [число] [месяц]" (например: "на 5 апреля"):
  - конкретная дата
- "через [N] дней":
  - текущая дата + N дней
- "на следующей неделе [день]":
  - день на следующей календарной неделе
- Если дату определить невозможно -> deadline = null

3. Извлеки текст задания
Извлеки ТОЛЬКО суть задания:
Удаляй слова и конструкции:
- "добавь", "запиши", "поставь"
- "на [предмет]", "по [предмету]"
- любые указания даты
Правила:
- Оставь только действие (глагол + объект)
- Сделай первую букву заглавной
- Не добавляй ничего от себя
Примеры:
- "добавь на алгебру решить номера 45 и 46" -> "Решить номера 45 и 46"
- "задание по литературе на пятницу читать параграф 12" -> "Читать параграф 12"
- "добавь на следующий урок алгебры" -> ""
Если задания нет -> task = ""

Формат ответа (СТРОГО)
Верни ТОЛЬКО JSON:
{"subject": "Алгебра", "deadline": "2026-04-04", "task": "Решить номера 45 и 46"}

Ограничения
- Никаких пояснений
- Никакого markdown
- Никакого текста вне JSON
- Дата строго в формате YYYY-MM-DD

Проверка качества (перед ответом)
- Предмет есть в расписании?
- Дата соответствует правилам?
- Задание очищено от мусора?
- JSON валиден?

Если данных недостаточно
- subject -> null
- deadline -> null
- task -> ""
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
      };
    } catch (_) {
      return {'subject': null, 'deadline': null, 'task': null};
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

    return <String, dynamic>{'subject': null, 'deadline': null, 'task': null};
  }
}
