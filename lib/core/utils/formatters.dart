import 'package:intl/intl.dart';

class Fmt {
  static String currency(num value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

  static String date(DateTime d) => DateFormat.yMMMd().format(d);
  static String dateTime(DateTime d) => DateFormat.yMMMd().add_jm().format(d);
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(d);
  }
}
