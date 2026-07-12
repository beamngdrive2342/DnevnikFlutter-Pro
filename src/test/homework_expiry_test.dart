import 'package:flutter_test/flutter_test.dart';

import 'package:dnevnik_app/utils/app_date_utils.dart';

void main() {
  // Фиксированная "сегодня" для детерминированности: cutoff = 2025-06-01.
  final now = DateTime(2025, 6, 15);

  group('isHomeworkExpired', () {
    test('дедлайн старше 14 дней -> true', () {
      expect(isHomeworkExpired('2025-05-01', now: now), isTrue);
    });

    test('сегодняшний дедлайн -> false', () {
      expect(isHomeworkExpired('2025-06-15', now: now), isFalse);
    });

    test('будущий дедлайн -> false', () {
      expect(isHomeworkExpired('2025-07-01', now: now), isFalse);
    });

    test('невалидная дата -> false', () {
      expect(isHomeworkExpired('not-a-date', now: now), isFalse);
    });

    test('ровно 14 дней назад (граница cutoff) -> false', () {
      expect(isHomeworkExpired('2025-06-01', now: now), isFalse);
    });

    test('15 дней назад -> true', () {
      expect(isHomeworkExpired('2025-05-31', now: now), isTrue);
    });
  });
}
