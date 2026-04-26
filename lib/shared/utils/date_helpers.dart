import 'package:intl/intl.dart';

/// Format a DateTime for display.
String formatDate(DateTime dt) {
  return DateFormat('dd MMM yyyy, HH:mm').format(dt);
}

/// Format a DateTime as relative time (e.g., "2 hours ago").
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 30) return DateFormat('dd MMM yyyy').format(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

/// Days until a future date.
int daysUntil(DateTime future) {
  return future.difference(DateTime.now()).inDays;
}
