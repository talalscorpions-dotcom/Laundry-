/// The rolling time window the admin analytics screen filters every report
/// by. Covers the "annually / monthly / weekly / daily" breakdowns requested
/// for partner performance, revenue, and driver pickup-time reporting, plus
/// an unfiltered view.
enum ReportPeriod { today, thisWeek, thisMonth, thisYear, allTime }

extension ReportPeriodX on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This week';
      case ReportPeriod.thisMonth:
        return 'This month';
      case ReportPeriod.thisYear:
        return 'This year';
      case ReportPeriod.allTime:
        return 'All time';
    }
  }

  /// The earliest moment this period includes, relative to [now] — null for
  /// [allTime], meaning "no lower bound."
  DateTime? startFrom(DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (this) {
      case ReportPeriod.today:
        return startOfToday;
      case ReportPeriod.thisWeek:
        // Monday as the start of the week.
        return startOfToday.subtract(Duration(days: now.weekday - 1));
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.allTime:
        return null;
    }
  }
}

/// One driver's pickup performance within a [ReportPeriod] — how many
/// pickups they completed, how long they took on average (measured from
/// being assigned the job to marking it picked up), and how many of those
/// pickups ran over the slow-pickup threshold.
class DriverPickupStats {
  const DriverPickupStats({required this.pickupCount, required this.average, required this.slowCount});

  final int pickupCount;
  final Duration average;
  final int slowCount;
}
