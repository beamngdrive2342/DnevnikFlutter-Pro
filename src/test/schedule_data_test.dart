import 'package:flutter_test/flutter_test.dart';

import 'package:dnevnik_app/data/schedule_data.dart';

void main() {
  // Статика ClassSchedule течёт между тестами — обязательно сбрасываем.
  setUp(ClassSchedule.reset);
  tearDown(ClassSchedule.reset);

  test('loadFromFirestoreDoc заполняет subjects / lessonTimes / weekSchedule', () {
    ClassSchedule.loadFromFirestoreDoc({
      'fields': {
        'classId': {'stringValue': 'cls_1'},
        'className': {'stringValue': '10А'},
        'schoolName': {'stringValue': 'Школа 1'},
        'code': {'stringValue': 'ABC123'},
        'subjects': {
          'arrayValue': {
            'values': [
              {'stringValue': 'Алгебра'},
              {'stringValue': 'Физика'},
            ],
          },
        },
        'lessonTimes': {
          'arrayValue': {
            'values': [
              {'stringValue': '09:00 - 09:45'},
              {'stringValue': '09:50 - 10:35'},
            ],
          },
        },
        'schedule': {
          'mapValue': {
            'fields': {
              '0': {
                'arrayValue': {
                  'values': [
                    {
                      'mapValue': {
                        'fields': {
                          'subject': {'stringValue': 'Алгебра'},
                          'room': {'stringValue': 'Каб. 1'},
                        },
                      },
                    },
                    {
                      'mapValue': {
                        'fields': {
                          'subject': {'stringValue': 'Физика'},
                          'room': {'stringValue': 'Каб. 2'},
                        },
                      },
                    },
                  ],
                },
              },
            },
          },
        },
      },
    });

    expect(ClassSchedule.isLoaded, isTrue);
    expect(ClassSchedule.className, '10А');
    expect(ClassSchedule.subjects, ['Алгебра', 'Физика']);
    expect(ClassSchedule.lessonTimes, ['09:00 - 09:45', '09:50 - 10:35']);

    final monday = ClassSchedule.weekSchedule[0]!;
    expect(monday.length, 2);
    expect(monday[0].subject, 'Алгебра');
    expect(monday[0].time, '09:00 - 09:45');
    expect(monday[1].room, 'Каб. 2');
  });

  test('reset возвращает расписание к дефолтам', () {
    ClassSchedule.loadFromFirestoreDoc({
      'fields': {
        'classId': {'stringValue': 'cls_1'},
        'subjects': {
          'arrayValue': {
            'values': [
              {'stringValue': 'Алгебра'},
            ],
          },
        },
      },
    });
    expect(ClassSchedule.isLoaded, isTrue);

    ClassSchedule.reset();

    expect(ClassSchedule.isLoaded, isFalse);
    expect(ClassSchedule.subjects, defaultSubjects);
    expect(ClassSchedule.weekSchedule, isNotEmpty);
  });
}
