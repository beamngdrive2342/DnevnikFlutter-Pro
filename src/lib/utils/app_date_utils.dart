/// Date utility functions for the Dnevnik app.
library app_date_utils;

/// Returns the next weekday (skipping Saturday/Sunday) as the default deadline.
DateTime defaultHomeworkDeadline() {
  var date = DateTime.now().add(const Duration(days: 1));
  while (date.weekday == 6 || date.weekday == 7) {
    date = date.add(const Duration(days: 1));
  }
  return date;
}

/// Parses a date string in YYYY-MM-DD format, returns null on failure.
DateTime? parseHomeworkDeadline(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) {
    return null;
  }

  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) {
    return null;
  }

  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

/// Formats a DateTime as "d.MM.yyyy".
String formatDate(DateTime date) {
  return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// Formats a DateTime as "YYYY-MM-DD".
String formatDateIso(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Returns today's date as "YYYY-MM-DD".
String todayString() {
  final now = DateTime.now();
  return formatDateIso(now);
}

/// Returns true if [deadline] (YYYY-MM-DD) is more than 14 days before today.
///
/// Invalid or empty deadlines are treated as not expired.
/// [now] can be injected for deterministic testing.
bool isHomeworkExpired(String deadline, {DateTime? now}) {
  final parsed = parseHomeworkDeadline(deadline);
  if (parsed == null) {
    return false;
  }

  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final cutoff = today.subtract(const Duration(days: 14));
  return parsed.isBefore(cutoff);
}
