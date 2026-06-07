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