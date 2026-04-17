import '../data/schedule_data.dart';

/// Normalizes a subject name for fuzzy matching.
String normalizeSubjectKey(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('\u0451', '\u0435') // ё → е
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// Attempts to match a recognized subject string against known subjects.
/// Returns the canonical subject name or null.
String? matchRecognizedSubject(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final normalizedValue = normalizeSubjectKey(value);
  for (final subject in allSubjects) {
    if (normalizeSubjectKey(subject) == normalizedValue) {
      return subject;
    }
  }
  for (final subject in allSubjects) {
    final normalizedSubject = normalizeSubjectKey(subject);
    if (normalizedSubject.contains(normalizedValue) ||
        normalizedValue.contains(normalizedSubject)) {
      return subject;
    }
  }
  return null;
}

/// Returns true if the given subject has a lesson on the given date.
bool hasSubjectOnDate(String subject, DateTime date) {
  final lessons = weekSchedule[date.weekday - 1] ?? const <Lesson>[];
  return lessons.any((lesson) => lesson.subject == subject);
}

/// Builds a summary of the weekly schedule suitable for AI prompts.
String buildScheduleSummaryForAI() {
  final buffer = StringBuffer();
  for (var dayIndex = 0; dayIndex < 6; dayIndex++) {
    final dayName = weekdaysFull[dayIndex];
    final lessons = weekSchedule[dayIndex] ?? const <Lesson>[];
    if (lessons.isEmpty) {
      buffer.writeln('$dayName: нет уроков.');
      continue;
    }

    final subjects = lessons
        .map((lesson) => '${lesson.subject} (${lesson.time})')
        .join(', ');
    buffer.writeln('$dayName: $subjects.');
  }
  return buffer.toString().trim();
}
