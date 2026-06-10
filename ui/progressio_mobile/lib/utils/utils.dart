import 'package:intl/intl.dart';

String formatNumber(dynamic number) {
  if (number == null) return '';
  var f = NumberFormat('#,##0.00', 'en_US');
  return f.format(number);
}

String formatDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd.MM.yyyy').format(date);
}

String formatDateTime(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}

String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(date);
}

String ratingString(double? rating) {
  if (rating == null) return '—';
  return rating.toStringAsFixed(1);
}