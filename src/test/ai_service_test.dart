import 'package:flutter_test/flutter_test.dart';

import 'package:dnevnik_app/data/ai_service.dart';

void main() {
  group('AIService.extractQuickHomeworkJson', () {
    test('чистый JSON парсится в поля', () {
      final result = AIService.extractQuickHomeworkJson(
        '{"subject":"Алгебра","deadline":"2025-03-14","task":"Номера 45 46",'
        '"textbookNumbers":["45","46"],"fallback":false}',
      );

      expect(result['subject'], 'Алгебра');
      expect(result['deadline'], '2025-03-14');
      expect(result['task'], 'Номера 45 46');
      expect(result['textbookNumbers'], ['45', '46']);
      expect(result['fallback'], false);
    });

    test('JSON внутри ```json fenced-блока', () {
      const raw =
          '```json\n{"subject":"Физика","deadline":null,"task":null,"fallback":true}\n```';

      final result = AIService.extractQuickHomeworkJson(raw);

      expect(result['subject'], 'Физика');
      expect(result['deadline'], isNull);
      expect(result['fallback'], true);
    });

    test('JSON с мусорным текстом до и после', () {
      const raw =
          'Вот результат: {"subject":"Химия","deadline":"2025-01-02",'
          '"task":"Параграф 5","fallback":false} — готово.';

      final result = AIService.extractQuickHomeworkJson(raw);

      expect(result['subject'], 'Химия');
      expect(result['task'], 'Параграф 5');
      expect(result['deadline'], '2025-01-02');
    });

    test('не-JSON возвращает fallback с null-полями', () {
      final result = AIService.extractQuickHomeworkJson('совсем не json');

      expect(result['fallback'], true);
      expect(result['subject'], isNull);
      expect(result['deadline'], isNull);
      expect(result['task'], isNull);
    });
  });
}
