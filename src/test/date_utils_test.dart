import 'package:flutter_test/flutter_test.dart';

import 'package:dnevnik_app/utils/app_date_utils.dart';

void main() {
  group('formatDateIso', () {
    test('дополняет месяц и день до двух цифр', () {
      expect(formatDateIso(DateTime(2025, 1, 5)), '2025-01-05');
    });

    test('оставляет двузначные месяц и день как есть', () {
      expect(formatDateIso(DateTime(2025, 12, 31)), '2025-12-31');
    });
  });

  group('parseHomeworkDeadline', () {
    test('валидная дата YYYY-MM-DD', () {
      expect(parseHomeworkDeadline('2025-03-14'), DateTime(2025, 3, 14));
    });

    test('неверный формат возвращает null', () {
      expect(parseHomeworkDeadline('14.03.2025'), isNull);
    });

    test('пустая строка возвращает null', () {
      expect(parseHomeworkDeadline(''), isNull);
    });

    test('null возвращает null', () {
      expect(parseHomeworkDeadline(null), isNull);
    });
  });
}
