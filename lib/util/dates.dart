/// Date helpers. Everything in this app is day-granular: a habit is either
/// done on a calendar day or it isn't, so all dates are normalised to midnight
/// and keyed by `yyyy-MM-dd`.
library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dateKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Whole days from [from] to [to]. Negative when [to] is earlier.
int daysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The [count] days ending on [end], oldest first.
List<DateTime> daysEndingOn(DateTime end, int count) {
  final last = dateOnly(end);
  return List.generate(count, (i) => last.subtract(Duration(days: count - 1 - i)));
}

/// Indexed by `DateTime.weekday - 1`.
const weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const weekdayInitials = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

String weekdayName(int weekday) => weekdayNames[weekday - 1];
