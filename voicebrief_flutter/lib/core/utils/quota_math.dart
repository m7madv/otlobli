import 'dart:math' as math;

int billedMinutesForDuration(Duration duration) {
  if (duration <= Duration.zero) return 0;
  return math.max(1, (duration.inSeconds / 60).ceil());
}

int annualSaving({required int monthlyPrice, required int annualPrice}) {
  return (monthlyPrice * 12) - annualPrice;
}

int annualSavingPercent({required int monthlyPrice, required int annualPrice}) {
  final fullPrice = monthlyPrice * 12;
  if (fullPrice <= 0) return 0;
  return ((fullPrice - annualPrice) / fullPrice * 100).round();
}
