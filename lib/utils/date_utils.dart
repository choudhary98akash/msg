import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String format(DateTime date) => _dateFormat.format(date);
  static String formatDisplay(DateTime date) => _displayFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);

  static DateTime? parse(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime parseDob(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static DateTime addMonths(DateTime date, int months) {
    var newMonth = date.month + months;
    var newYear = date.year;
    
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    
    final maxDay = getDaysInMonth(DateTime(newYear, newMonth));
    final newDay = date.day > maxDay ? maxDay : date.day;
    
    return DateTime(newYear, newMonth, newDay);
  }

  static int monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isBefore(DateTime a, DateTime b) {
    return a.isBefore(getEndOfDay(b));
  }

  static bool isAfter(DateTime a, DateTime b) {
    return a.isAfter(getStartOfDay(b));
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = getStartOfDay(now);
    final targetDay = getStartOfDay(date);
    
    final difference = today.difference(targetDay).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    if (difference > 0 && difference < 7) return '$difference days ago';
    if (difference < 0 && difference > -7) return 'In ${-difference} days';
    
    return formatDisplay(date);
  }

  static DateTime adjustToMonthEnd(DateTime date) {
    final lastDay = getDaysInMonth(date);
    if (date.day > lastDay) {
      return DateTime(date.year, date.month, lastDay);
    }
    return date;
  }
}
