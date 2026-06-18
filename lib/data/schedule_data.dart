import 'package:flutter/material.dart';

class Lesson {
  final String id;
  final int num;
  final String subject;
  final String room;
  final String time;
  final String topic;
  final String hw;

  Lesson({
    required this.id,
    required this.num,
    required this.subject,
    required this.room,
    required this.time,
    this.topic = 'Обычный урок',
    this.hw = '',
  });

  Lesson copyWith({String? hw}) {
    return Lesson(
      id: id,
      num: num,
      subject: subject,
      room: room,
      time: time,
      topic: topic,
      hw: hw ?? this.hw,
    );
  }
}

class HomeworkItem {
  final String id;
  final String subject;
  final String task;
  final String deadline; // YYYY-MM-DD
  final String? imageUrl;
  final List<String>? imageUrls;
  final List<String>? fullResolutionUrls;
  bool done;
  final bool fromSchedule;

  HomeworkItem({
    required this.id,
    required this.subject,
    required this.task,
    required this.deadline,
    this.imageUrl,
    this.imageUrls,
    this.fullResolutionUrls,
    this.done = false,
    this.fromSchedule = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'task': task,
        'deadline': deadline,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'fullResolutionUrls': fullResolutionUrls,
        'done': done,
        'fromSchedule': fromSchedule,
      };

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    List<String>? parsedUrls;
    if (json['imageUrls'] != null && json['imageUrls'] is List) {
      parsedUrls = List<String>.from(json['imageUrls']);
    } else if (json['imageUrl'] != null &&
        json['imageUrl'].toString().isNotEmpty) {
      parsedUrls = [json['imageUrl']];
    }

    List<String>? parsedFullUrls;
    if (json['fullResolutionUrls'] != null &&
        json['fullResolutionUrls'] is List) {
      parsedFullUrls = List<String>.from(json['fullResolutionUrls']);
    }

    return HomeworkItem(
      id: json['id'],
      subject: json['subject'],
      task: json['task'],
      deadline: json['deadline'],
      imageUrl: json['imageUrl'],
      imageUrls: parsedUrls,
      fullResolutionUrls: parsedFullUrls,
      done: json['done'] ?? false,
      fromSchedule: json['fromSchedule'] ?? false,
    );
  }

  HomeworkItem copyWith(
      {String? task,
      List<String>? imageUrls,
      List<String>? fullResolutionUrls}) {
    return HomeworkItem(
      id: id,
      subject: subject,
      task: task ?? this.task,
      deadline: deadline,
      imageUrl: imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      fullResolutionUrls: fullResolutionUrls ?? this.fullResolutionUrls,
      done: done,
      fromSchedule: fromSchedule,
    );
  }
}

final Map<String, Color> subjectColors = {
  'Алгебра': const Color(0xFFE57373),
  'Геометрия': const Color(0xFFF06292),
  'Русский язык': const Color(0xFFBA68C8),
  'Литература': const Color(0xFF9575CD),
  'Физика': const Color(0xFF7986CB),
  'Химия': const Color(0xFF64B5F6),
  'История': const Color(0xFF4FC3F7),
  'Обществознание': const Color(0xFF4DD0E1),
  'Вероятность и статистика': const Color(0xFF4DB6AC),
  'Английский': const Color(0xFF81C784),
  'Информатика': const Color(0xFFAED581),
  'Биология': const Color(0xFFDCE775),
  'География': const Color(0xFFFFF176),
  'Физ-ра': const Color(0xFFFFD54F),
  'ИП': const Color(0xFFFFB74D),
  'РоВ': const Color(0xFFFF8A65),
  'Верстат': const Color(0xFFA1887F),
  'ОБЗР': const Color(0xFF90A4AE),
  'ВУД РМГ': const Color(0xFFB0BEC5),
};

Color getSubjectColor(String subject) {
  return subjectColors[subject] ?? Colors.grey;
}

const List<String> defaultSubjects = [
  "Алгебра",
  "Геометрия",
  "Русский язык",
  "Литература",
  "Физика",
  "Химия",
  "История",
  "Обществознание",
  "Вероятность и статистика",
  "Английский",
  "Информатика",
  "Биология",
  "География",
  "Физ-ра",
  "ИП",
  "РоВ",
  "Верстат",
  "ОБЗР",
  "ВУД РМГ"
];

List<String> get allSubjects => ClassSchedule.subjects;

// Times for 8 possible lessons
const List<String> defaultLessonTimes = [
  '09:00 - 09:45',
  '09:50 - 10:35',
  '10:45 - 11:30',
  '11:50 - 12:35',
  '12:55 - 13:40',
  '13:50 - 14:35',
  '14:40 - 15:25',
  '15:30 - 16:15',
];

List<String> get lessonTimes => ClassSchedule.lessonTimes;

String _getTime(int index) =>
    index < defaultLessonTimes.length ? defaultLessonTimes[index] : '';

// 0 - Monday
final Map<int, List<Lesson>> _defaultWeekSchedule = {
  0: [
    Lesson(
        id: 'mon_1',
        num: 1,
        subject: 'РоВ',
        room: 'Каб. 1',
        time: _getTime(0),
        hw: ''),
    Lesson(
        id: 'mon_2',
        num: 2,
        subject: 'Обществознание',
        room: 'Каб. 2',
        time: _getTime(1),
        hw: ''),
    Lesson(
        id: 'mon_3',
        num: 3,
        subject: 'ИП',
        room: 'Каб. 3',
        time: _getTime(2),
        hw: ''),
    Lesson(
        id: 'mon_4',
        num: 4,
        subject: 'Алгебра',
        room: 'Каб. 4',
        time: _getTime(3),
        hw: ''),
    Lesson(
        id: 'mon_5',
        num: 5,
        subject: 'Геометрия',
        room: 'Каб. 5',
        time: _getTime(4),
        hw: ''),
    Lesson(
        id: 'mon_6',
        num: 6,
        subject: 'История',
        room: 'Каб. 6',
        time: _getTime(5),
        hw: ''),
    Lesson(
        id: 'mon_7',
        num: 7,
        subject: 'Русский язык',
        room: 'Каб. 7',
        time: _getTime(6),
        hw: ''),
    Lesson(
        id: 'mon_8',
        num: 8,
        subject: 'Английский',
        room: 'Каб. 8',
        time: _getTime(7),
        hw: ''),
  ],
  1: [
    Lesson(
        id: 'tue_1',
        num: 1,
        subject: 'Английский',
        room: 'Каб. 1',
        time: _getTime(0),
        hw: ''),
    Lesson(
        id: 'tue_2',
        num: 2,
        subject: 'Геометрия',
        room: 'Каб. 2',
        time: _getTime(1),
        hw: ''),
    Lesson(
        id: 'tue_3',
        num: 3,
        subject: 'Химия',
        room: 'Каб. 3',
        time: _getTime(2),
        hw: ''),
    Lesson(
        id: 'tue_4',
        num: 4,
        subject: 'Химия',
        room: 'Каб. 4',
        time: _getTime(3),
        hw: ''),
    Lesson(
        id: 'tue_5',
        num: 5,
        subject: 'Литература',
        room: 'Каб. 5',
        time: _getTime(4),
        hw: ''),
    Lesson(
        id: 'tue_6',
        num: 6,
        subject: 'Алгебра',
        room: 'Каб. 6',
        time: _getTime(5),
        hw: ''),
    Lesson(
        id: 'tue_7',
        num: 7,
        subject: 'Русский язык',
        room: 'Каб. 7',
        time: _getTime(6),
        hw: ''),
  ],
  2: [
    Lesson(
        id: 'wed_1',
        num: 1,
        subject: 'Английский',
        room: 'Каб. 1',
        time: _getTime(0),
        hw: ''),
    Lesson(
        id: 'wed_2',
        num: 2,
        subject: 'Физика',
        room: 'Каб. 2',
        time: _getTime(1),
        hw: ''),
    Lesson(
        id: 'wed_3',
        num: 3,
        subject: 'Верстат',
        room: 'Каб. 3',
        time: _getTime(2),
        hw: ''),
    Lesson(
        id: 'wed_4',
        num: 4,
        subject: 'ОБЗР',
        room: 'Каб. 4',
        time: _getTime(3),
        hw: ''),
    Lesson(
        id: 'wed_5',
        num: 5,
        subject: 'Физ-ра',
        room: 'Каб. 5',
        time: _getTime(4),
        hw: ''),
    Lesson(
        id: 'wed_6',
        num: 6,
        subject: 'Физ-ра',
        room: 'Каб. 6',
        time: _getTime(5),
        hw: ''),
    Lesson(
        id: 'wed_7',
        num: 7,
        subject: 'Информатика',
        room: 'Каб. 7',
        time: _getTime(6),
        hw: ''),
  ],
  3: [
    Lesson(
        id: 'thu_1',
        num: 1,
        subject: 'ВУД РМГ',
        room: 'Каб. 1',
        time: _getTime(0),
        hw: ''),
    Lesson(
        id: 'thu_2',
        num: 2,
        subject: 'История',
        room: 'Каб. 2',
        time: _getTime(1),
        hw: ''),
    Lesson(
        id: 'thu_3',
        num: 3,
        subject: 'Биология',
        room: 'Каб. 3',
        time: _getTime(2),
        hw: ''),
    Lesson(
        id: 'thu_4',
        num: 4,
        subject: 'Физика',
        room: 'Каб. 4',
        time: _getTime(3),
        hw: ''),
    Lesson(
        id: 'thu_5',
        num: 5,
        subject: 'Алгебра',
        room: 'Каб. 5',
        time: _getTime(4),
        hw: ''),
    Lesson(
        id: 'thu_6',
        num: 6,
        subject: 'Геометрия',
        room: 'Каб. 6',
        time: _getTime(5),
        hw: ''),
    Lesson(
        id: 'thu_7',
        num: 7,
        subject: 'Обществознание',
        room: 'Каб. 7',
        time: _getTime(6),
        hw: ''),
  ],
  4: [
    Lesson(
        id: 'fri_1',
        num: 1,
        subject: 'Алгебра',
        room: 'Каб. 1',
        time: _getTime(0),
        hw: ''),
    Lesson(
        id: 'fri_2',
        num: 2,
        subject: 'Химия',
        room: 'Каб. 2',
        time: _getTime(1),
        hw: ''),
    Lesson(
        id: 'fri_3',
        num: 3,
        subject: 'Биология',
        room: 'Каб. 3',
        time: _getTime(2),
        hw: ''),
    Lesson(
        id: 'fri_4',
        num: 4,
        subject: 'Биология',
        room: 'Каб. 4',
        time: _getTime(3),
        hw: ''),
    Lesson(
        id: 'fri_5',
        num: 5,
        subject: 'География',
        room: 'Каб. 5',
        time: _getTime(4),
        hw: ''),
    Lesson(
        id: 'fri_6',
        num: 6,
        subject: 'Литература',
        room: 'Каб. 6',
        time: _getTime(5),
        hw: ''),
    Lesson(
        id: 'fri_7',
        num: 7,
        subject: 'Литература',
        room: 'Каб. 7',
        time: _getTime(6),
        hw: ''),
  ],
};

Map<int, List<Lesson>> get weekSchedule => ClassSchedule.weekSchedule;

const List<String> weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const List<String> weekdaysFull = [
  'Понедельник',
  'Вторник',
  'Среда',
  'Четверг',
  'Пятница',
  'Суббота',
  'Воскресенье'
];
const List<String> weekDaysNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
const List<String> monthsShort = [
  'янв',
  'фев',
  'мар',
  'апр',
  'май',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек'
];

const List<String> _dayPrefixes = [
  'mon',
  'tue',
  'wed',
  'thu',
  'fri',
  'sat',
  'sun'
];

class ClassSchedule {
  static String className = '';
  static String schoolName = '';
  static String classCode = '';
  static String classId = '';

  static Map<int, List<Lesson>> _schedule = {};
  static List<String> _subjects = [];
  static List<String> _lessonTimes = [];
  static bool _loaded = false;

  static Map<int, List<Lesson>> get weekSchedule =>
      _loaded ? _schedule : _defaultWeekSchedule;

  static List<String> get subjects => _loaded ? _subjects : defaultSubjects;

  static List<String> get lessonTimes =>
      _loaded ? _lessonTimes : defaultLessonTimes;

  static bool get isLoaded => _loaded;

  static void load({
    required String classId,
    required String className,
    required String schoolName,
    required String classCode,
    required Map<int, List<Lesson>> schedule,
    required List<String> subjects,
    required List<String> lessonTimes,
  }) {
    ClassSchedule.classId = classId;
    ClassSchedule.className = className;
    ClassSchedule.schoolName = schoolName;
    ClassSchedule.classCode = classCode;
    _schedule = schedule;
    _subjects = subjects;
    _lessonTimes = lessonTimes;
    _loaded = true;
  }

  static void reset() {
    className = '';
    schoolName = '';
    classCode = '';
    classId = '';
    _schedule = {};
    _subjects = [];
    _lessonTimes = [];
    _loaded = false;
  }

  static void loadFromFirestoreDoc(Map<String, dynamic> doc) {
    final fields = (doc['fields'] ?? {}) as Map<String, dynamic>;

    final id = fields['classId']?['stringValue'] ?? '';
    final name = fields['className']?['stringValue'] ?? '';
    final school = fields['schoolName']?['stringValue'] ?? '';
    final code = fields['code']?['stringValue'] ?? '';

    final subArr =
        (fields['subjects']?['arrayValue']?['values'] as List?) ?? [];
    final subs = subArr
        .map((v) => (v as Map)['stringValue'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    final timesArr =
        (fields['lessonTimes']?['arrayValue']?['values'] as List?) ?? [];
    final times = timesArr
        .map((v) => (v as Map)['stringValue'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    final schedMap =
        (fields['schedule']?['mapValue']?['fields'] as Map<String, dynamic>?) ??
            {};
    final schedule = <int, List<Lesson>>{};

    for (final entry in schedMap.entries) {
      final dayIdx = int.tryParse(entry.key);
      if (dayIdx == null) continue;

      final arr = (entry.value['arrayValue']?['values'] as List?) ?? [];
      final lessons = <Lesson>[];
      for (var i = 0; i < arr.length; i++) {
        final lf =
            (arr[i]['mapValue']?['fields'] ?? {}) as Map<String, dynamic>;
        final subject = lf['subject']?['stringValue'] ?? '';
        final room = lf['room']?['stringValue'] ?? '';
        if (subject.isEmpty) continue;

        final prefix =
            dayIdx < _dayPrefixes.length ? _dayPrefixes[dayIdx] : 'd$dayIdx';
        lessons.add(Lesson(
          id: '${prefix}_${i + 1}',
          num: i + 1,
          subject: subject,
          room: room,
          time: i < times.length ? times[i] : '',
        ));
      }
      schedule[dayIdx] = lessons;
    }

    load(
      classId: id,
      className: name,
      schoolName: school,
      classCode: code,
      schedule: schedule,
      subjects: subs,
      lessonTimes: times,
    );
  }
}
