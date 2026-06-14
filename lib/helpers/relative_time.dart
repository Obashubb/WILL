import 'package:intl/intl.dart';

class RelativeTime {
  const RelativeTime._();

  static String short(DateTime moment) {
    final delta = DateTime.now().difference(moment);
    if (delta.isNegative) return 'Just now';
    if (delta.inSeconds < 10) return 'Just now';
    if (delta.inSeconds < 60) return '${delta.inSeconds}s ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    return DateFormat.Hm().format(moment);
  }
}
