import 'package:intl/intl.dart';

/// Friendly relative-time label. Falls back to absolute clock time once
/// the gap exceeds an hour so the label stays meaningful across long
/// windows.
String relativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 10) return 'just now';
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return DateFormat.MMMd().format(t);
}

/// Sync-row variant: matches the Profile screen's previous formatting.
String relativeSyncTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return DateFormat.MMMd().format(t);
}
