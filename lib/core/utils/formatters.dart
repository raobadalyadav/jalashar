import 'package:intl/intl.dart';

class Fmt {
  static String currency(num value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

  static String date(DateTime d) => DateFormat.yMMMd().format(d);
  static String dateTime(DateTime d) => DateFormat.yMMMd().add_jm().format(d);
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);
}
