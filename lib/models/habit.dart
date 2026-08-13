import '../util/dates.dart';
import 'day_entry.dart';

/// One habit, with its two versions.
///
/// [fullLabel]/[floorLabel] are the ceiling and the floor. The floor exists to
/// be taken on bad days without it feeling like cheating, so it is stored,
/// displayed and counted as a first-class way of showing up.
class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.identity,
    required this.anchor,
    required this.fullLabel,
    required this.fullDetail,
    required this.floorLabel,
    required this.floorDetail,
    required DateTime createdAt,
    Set<int>? activeWeekdays,
    Map<String, DayEntry>? entries,
    this.graduated = false,
    DateTime? graduatedAt,
    DateTime? graduationSnoozedAt,
  })  : createdAt = dateOnly(createdAt),
        activeWeekdays = activeWeekdays ?? {1, 2, 3, 4, 5, 6, 7},
        entries = entries ?? <String, DayEntry>{},
        graduatedAt = graduatedAt == null ? null : dateOnly(graduatedAt),
        graduationSnoozedAt =
            graduationSnoozedAt == null ? null : dateOnly(graduationSnoozedAt);

  final String id;
  String name;
  String identity;
  String anchor;
  String fullLabel;
  String fullDetail;
  String floorLabel;
  String floorDetail;
  final DateTime createdAt;
  Set<int> activeWeekdays;
  Map<String, DayEntry> entries;
  bool graduated;
  DateTime? graduatedAt;

  /// Set when the graduation offer is waved off, so the app asks again later
  /// rather than every single day.
  DateTime? graduationSnoozedAt;

  DayEntry? entryOn(DateTime date) => entries[dateKey(date)];

  bool isScheduledOn(DateTime date) =>
      activeWeekdays.contains(date.weekday) &&
      !dateOnly(date).isBefore(createdAt);

  /// Every check ever, full or floor. This is the number shown as "votes",
  /// because the habit being built is showing up, not the volume.
  int get votes => entries.values.where((e) => e.isShowingUp).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'identity': identity,
        'anchor': anchor,
        'fullLabel': fullLabel,
        'fullDetail': fullDetail,
        'floorLabel': floorLabel,
        'floorDetail': floorDetail,
        'createdAt': dateKey(createdAt),
        'activeWeekdays': activeWeekdays.toList()..sort(),
        'graduated': graduated,
        if (graduatedAt != null) 'graduatedAt': dateKey(graduatedAt!),
        if (graduationSnoozedAt != null)
          'graduationSnoozedAt': dateKey(graduationSnoozedAt!),
        'entries': entries.map((k, v) => MapEntry(k, v.toJson())),
      };

  static Habit fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as Map?) ?? {};
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      identity: json['identity'] as String? ?? '',
      anchor: json['anchor'] as String? ?? '',
      fullLabel: json['fullLabel'] as String? ?? '',
      fullDetail: json['fullDetail'] as String? ?? '',
      floorLabel: json['floorLabel'] as String? ?? '',
      floorDetail: json['floorDetail'] as String? ?? '',
      createdAt: parseDateKey(json['createdAt'] as String),
      activeWeekdays: ((json['activeWeekdays'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7])
          .map((e) => e as int)
          .toSet(),
      graduated: json['graduated'] as bool? ?? false,
      graduatedAt: json['graduatedAt'] == null
          ? null
          : parseDateKey(json['graduatedAt'] as String),
      graduationSnoozedAt: json['graduationSnoozedAt'] == null
          ? null
          : parseDateKey(json['graduationSnoozedAt'] as String),
      entries: rawEntries.map(
        (k, v) => MapEntry(
          k as String,
          DayEntry.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
    );
  }
}
