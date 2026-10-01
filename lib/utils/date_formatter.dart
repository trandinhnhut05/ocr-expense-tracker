import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _monthYearFormat = DateFormat('MM/yyyy');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes <= 1) return 'Vừa xong';
        return '${diff.inMinutes} phút trước';
      }
      return 'Hôm nay, ${formatTime(date)}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua, ${formatTime(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return formatDate(date);
  }
}
