import '../models/order.dart';

/// "Smart scheduling" — customers lock a specific window rather than an
/// arbitrary time, so partners/drivers can batch pickups efficiently.
const List<List<int>> _windows = [
  [9, 11],
  [11, 13],
  [13, 15],
  [15, 17],
  [17, 19],
  [19, 21],
];

List<TimeSlot> slotsForDay(DateTime day) {
  return _windows.map((w) {
    final start = DateTime(day.year, day.month, day.day, w[0]);
    final end = DateTime(day.year, day.month, day.day, w[1]);
    return TimeSlot(start, end);
  }).toList();
}

/// The next [count] calendar days, starting today, for the day picker.
List<DateTime> nextDays(int count) {
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  return List.generate(count, (i) => startOfToday.add(Duration(days: i)));
}

String weekdayLabel(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final today = DateTime.now();
  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
  return isToday ? 'Today' : days[date.weekday - 1];
}

String monthDayLabel(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${date.day} ${months[date.month - 1]}';
}
