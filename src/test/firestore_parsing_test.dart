import 'package:flutter_test/flutter_test.dart';

import 'package:dnevnik_app/data/firestore_service.dart';

void main() {
  group('FirestoreService.homeworkFromFirestore', () {
    test('парсит imageUrls / fullResolutionUrls / textbookNumbers', () {
      final Map<String, dynamic> doc = {
        'name': 'projects/p/databases/(default)/documents/homework/doc1',
        'fields': {
          'id': {'stringValue': 'hw1'},
          'subject': {'stringValue': 'Алгебра'},
          'task': {'stringValue': 'Номера 45'},
          'deadline': {'stringValue': '2025-03-14'},
          'imageUrls': {
            'arrayValue': {
              'values': [
                {'stringValue': 'u1'},
                {'stringValue': 'u2'},
              ],
            },
          },
          'fullResolutionUrls': {
            'arrayValue': {
              'values': [
                {'stringValue': 'f1'},
              ],
            },
          },
          'textbookNumbers': {
            'arrayValue': {
              'values': [
                {'stringValue': '45'},
              ],
            },
          },
          'fromSchedule': {'booleanValue': true},
        },
      };

      final hw = FirestoreService.homeworkFromFirestore(doc);

      expect(hw.id, 'hw1');
      expect(hw.subject, 'Алгебра');
      expect(hw.task, 'Номера 45');
      expect(hw.deadline, '2025-03-14');
      expect(hw.imageUrls, ['u1', 'u2']);
      expect(hw.fullResolutionUrls, ['f1']);
      expect(hw.textbookNumbers, ['45']);
      expect(hw.fromSchedule, isTrue);
    });

    test('без поля id берёт id из имени документа', () {
      final Map<String, dynamic> doc = {
        'name': 'projects/p/databases/(default)/documents/homework/generated_id',
        'fields': {
          'subject': {'stringValue': 'Физика'},
          'task': {'stringValue': 'Параграф'},
          'deadline': {'stringValue': '2025-04-01'},
        },
      };

      final hw = FirestoreService.homeworkFromFirestore(doc);

      expect(hw.id, 'generated_id');
      expect(hw.subject, 'Физика');
      expect(hw.imageUrls, isNull);
      expect(hw.textbookNumbers, isEmpty);
    });

    test('пустой/битый документ не роняет парсер', () {
      final Map<String, dynamic> doc = {
        'name': 'projects/p/databases/(default)/documents/homework/empty1',
        'fields': <String, dynamic>{},
      };

      final hw = FirestoreService.homeworkFromFirestore(doc);

      expect(hw.id, 'empty1');
      expect(hw.subject, '');
      expect(hw.task, '');
      expect(hw.deadline, '');
      expect(hw.fromSchedule, isFalse);
    });
  });
}
