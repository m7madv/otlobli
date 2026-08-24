import 'package:intl/intl.dart';

final DateFormat _displayDate = DateFormat('yyyy/MM/dd', 'ar');

String formatDate(DateTime date) => _displayDate.format(date);

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime addMonths(DateTime date, int months) {
  final targetMonth = date.month + months;
  final firstOfTarget = DateTime(date.year, targetMonth, 1);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    date.day.clamp(1, lastDay),
  );
}

String warrantyRemainingLabel(DateTime expiryDate, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final expiry = dateOnly(expiryDate);
  final days = expiry.difference(today).inDays;

  if (days < 0) return 'منتهي منذ ${days.abs()} يوم';
  if (days == 0) return 'ينتهي اليوم';
  if (days == 1) return 'متبقٍ يوم واحد';
  if (days <= 10) return 'متبقي $days أيام';
  return 'متبقي $days يوماً';
}
