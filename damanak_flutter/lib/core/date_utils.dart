import 'package:damanak/l10n/l10n.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime date) =>
    DateFormat.yMd(L10n.instance.locale.languageCode).format(date);

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

  if (days < 0) return L10n.current.msg529b4943dc94(days.abs());
  if (days == 0) return L10n.current.msge708fda7a521;
  if (days == 1) return L10n.current.msgf3bf57cfc04a;
  if (days <= 10) return L10n.current.msgf1aaf0762596(days);
  return L10n.current.msg4a4ac1d2f9bb(days);
}
