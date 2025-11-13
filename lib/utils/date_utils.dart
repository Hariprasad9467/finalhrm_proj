// 📁 lib/utils/date_utils.dart
import 'package:intl/intl.dart';

String formatToDDMMYYYY(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final parsedDate = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  } catch (e) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        String day = parts[2].padLeft(2, '0');
        String month = parts[1].padLeft(2, '0');
        String year = parts[0];
        return '$day/$month/$year';
      }
    } catch (_) {}
    return dateStr;
  }
}