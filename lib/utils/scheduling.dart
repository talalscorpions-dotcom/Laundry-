import '../models/order.dart';

/// "Smart scheduling" — customers lock a specific window rather than an
/// arbitrary time, so partners/drivers can batch pickups efficiently.
///
/// Public (not `_windows`) because a slot *index* into this list is also
/// how a driver's weekly availability is stored (`Driver.weeklyAvailability`)
/// and how booking-capacity is checked (`AppState.isSlotFullyBooked`) — all
/// three need to agree on what "slot 3" means.
const List<List<int>> kSlotWindows = [
  [9, 11],
  [11, 13],
  [13, 15],
  [15, 17],
  [17, 19],
  [19, 21],
];

List<TimeSlot> slotsForDay(DateTime day) {
  return kSlotWindows.map((w) {
    final start = DateTime(day.year, day.month, day.day, w[0]);
    final end = DateTime(day.year, day.month, day.day, w[1]);
    return TimeSlot(start, end);
  }).toList();
}

/// The display label for slot [index] on its own (no date attached) — used
/// on the driver's weekly schedule screen, where a slot represents a
/// recurring weekly window rather than a specific day's `TimeSlot`.
String slotWindowLabel(int index) {
  final window = kSlotWindows[index];
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(window[0])}:00 - ${two(window[1])}:00';
}

/// The [kSlotWindows] index whose window starts at [hour], or null if
/// [hour] doesn't line up with any of them.
int? slotIndexForHour(int hour) {
  for (var i = 0; i < kSlotWindows.length; i++) {
    if (kSlotWindows[i][0] == hour) return i;
  }
  return null;
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
