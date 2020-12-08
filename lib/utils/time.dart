import 'package:intl/intl.dart';

formatTime(String format, DateTime time) {
  return DateFormat(format).format(time);
}
