import 'package:intl/intl.dart';

/// Human-friendly relative time strings for "last seen" affordances.
class RelativeTime {
  const RelativeTime._();

  /// Returns a short, glance-able description of how long ago [moment] was.
  ///
  /// `< 10s`   → "Just now"
  /// `< 60s`   → "27s ago"
  /// `< 60min` → "12 min ago"
  /// otherwise → "14:32"
  static String short(DateTime moment) {
    final delta = DateTime.now().difference(moment);
    if (delta.isNegative) return 'Just now';
    if (delta.inSeconds < 10) return 'Just now';
    if (delta.inSeconds < 60) return '${delta.inSeconds}s ago';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    return DateFormat.Hm().format(moment);
  }
}
