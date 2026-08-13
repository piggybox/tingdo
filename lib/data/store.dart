import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../logic/stats.dart';
import '../models/day_entry.dart';
import '../models/habit.dart';
import '../util/dates.dart';

/// The one person who gets a weekly note with your consistency number.
/// One witness, not a leaderboard: performance anxiety is what kills the
/// social version of this.
class Witness {
  Witness({required this.name, this.note = '', this.lastSharedAt});

  String name;
  String note;
  DateTime? lastSharedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'note': note,
        if (lastSharedAt != null) 'lastSharedAt': lastSharedAt!.toIso8601String(),
      };

  static Witness fromJson(Map<String, dynamic> json) => Witness(
        name: json['name'] as String? ?? '',
        note: json['note'] as String? ?? '',
        lastSharedAt: DateTime.tryParse(json['lastSharedAt'] as String? ?? ''),
      );
}

/// All app state, persisted as a single JSON file on this machine. Nothing
/// leaves the device.
class AppStore extends ChangeNotifier {
  AppStore([this._file]) : _inMemory = false;

  /// A store that never touches disk. Used by widget tests, whose fake-async
  /// zone would otherwise never complete a real file write.
  AppStore.inMemory() : _inMemory = true;

  File? _file;
  final bool _inMemory;
  bool _loaded = false;
  var _habits = <Habit>[];
  Witness? witness;

  bool get isLoaded => _loaded;
  List<Habit> get habits => List.unmodifiable(_habits);
  List<Habit> get activeHabits => _habits.where((h) => !h.graduated).toList();
  List<Habit> get graduatedHabits => _habits.where((h) => h.graduated).toList();
  bool get isEmpty => _habits.isEmpty;

  String? get storagePath => _file?.path;

  Future<void> load() async {
    if (_inMemory) {
      _loaded = true;
      notifyListeners();
      return;
    }
    _file ??= await _defaultFile();
    try {
      if (await _file!.exists()) {
        final raw = jsonDecode(await _file!.readAsString());
        final map = Map<String, dynamic>.from(raw as Map);
        _habits = ((map['habits'] as List?) ?? [])
            .map((e) => Habit.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        witness = map['witness'] == null
            ? null
            : Witness.fromJson(Map<String, dynamic>.from(map['witness'] as Map));
      }
    } catch (e) {
      debugPrint('tingdo: could not read saved data ($e); starting fresh.');
      _habits = [];
    }
    _loaded = true;
    notifyListeners();
  }

  static Future<File> _defaultFile() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/tingdo.json');
  }

  Future<void> _save() async {
    notifyListeners();
    final file = _file;
    if (_inMemory || file == null) return;
    final payload = jsonEncode({
      'version': 1,
      'habits': _habits.map((h) => h.toJson()).toList(),
      if (witness != null) 'witness': witness!.toJson(),
    });
    await file.writeAsString(payload);
  }

  HabitStats statsFor(Habit habit, {DateTime? now}) =>
      HabitStats.of(habit, now: now);

  /// One habit at a time, enforced. A second slot only opens once the first
  /// has actually taken hold.
  bool canAddHabit({DateTime? now}) => activeHabits
      .every((h) => HabitStats.of(h, now: now).clearsUnlockBar);

  /// Why the add button is locked, phrased as a coach would.
  String? addHabitBlockedReason({DateTime? now}) {
    if (canAddHabit(now: now)) return null;
    final blocking = activeHabits
        .map((h) => HabitStats.of(h, now: now))
        .firstWhere((s) => !s.clearsUnlockBar);
    if (blocking.ageDays < unlockAgeDays) {
      final left = blocking.daysUntilUnlockEligible;
      return 'One at a time. ${blocking.habit.name} has '
          '$left more ${left == 1 ? 'day' : 'days'} to settle in.';
    }
    return 'One at a time. ${blocking.habit.name} is at '
        '${blocking.consistencyPercent ?? 0}% — get it to '
        '${(unlockConsistency * 100).round()}% first.';
  }

  Habit? habitById(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  Future<Habit> addHabit({
    required String name,
    required String identity,
    required String anchor,
    required String fullLabel,
    required String fullDetail,
    required String floorLabel,
    required String floorDetail,
    Set<int>? activeWeekdays,
    DateTime? createdAt,
  }) async {
    final habit = Habit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      identity: identity.trim(),
      anchor: anchor.trim(),
      fullLabel: fullLabel.trim(),
      fullDetail: fullDetail.trim(),
      floorLabel: floorLabel.trim(),
      floorDetail: floorDetail.trim(),
      createdAt: createdAt ?? DateTime.now(),
      activeWeekdays: activeWeekdays,
    );
    _habits.add(habit);
    await _save();
    return habit;
  }

  Future<void> updateHabit(Habit habit, void Function(Habit) change) async {
    change(habit);
    await _save();
  }

  Future<void> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    await _save();
  }

  /// Log today. Tapping the option you already chose clears it — undo has to be
  /// as cheap as the check, or people stop trusting the buttons.
  Future<void> logToday(Habit habit, DayKind kind, {DateTime? now}) async {
    final today = dateOnly(now ?? DateTime.now());
    final key = dateKey(today);
    final existing = habit.entries[key];
    if (existing != null && existing.kind == kind) {
      habit.entries.remove(key);
    } else {
      habit.entries[key] = DayEntry(date: today, kind: kind);
    }
    await _save();
  }

  Future<void> clearDay(Habit habit, DateTime date) async {
    habit.entries.remove(dateKey(date));
    await _save();
  }

  /// The blameless miss review: a one-word reason on a past day.
  Future<void> setMissReason(
    Habit habit,
    DateTime date,
    MissReason? reason,
  ) async {
    final key = dateKey(date);
    if (reason == null) {
      habit.entries.remove(key);
    } else {
      habit.entries[key] =
          DayEntry(date: date, kind: DayKind.missed, reason: reason);
    }
    await _save();
  }

  Future<void> dropWeekday(Habit habit, int weekday) async {
    if (habit.activeWeekdays.length <= 1) return;
    habit.activeWeekdays = {...habit.activeWeekdays}..remove(weekday);
    await _save();
  }

  Future<void> setActiveWeekdays(Habit habit, Set<int> weekdays) async {
    if (weekdays.isEmpty) return;
    habit.activeWeekdays = {...weekdays};
    await _save();
  }

  /// Graduation: the app stepping out of the way on purpose.
  Future<void> graduate(Habit habit, {DateTime? now}) async {
    habit.graduated = true;
    habit.graduatedAt = dateOnly(now ?? DateTime.now());
    await _save();
  }

  Future<void> snoozeGraduation(Habit habit, {DateTime? now}) async {
    habit.graduationSnoozedAt = dateOnly(now ?? DateTime.now());
    await _save();
  }

  Future<void> unGraduate(Habit habit) async {
    habit.graduated = false;
    habit.graduatedAt = null;
    await _save();
  }

  Future<void> setWitness(Witness? w) async {
    witness = w;
    await _save();
  }

  Future<void> markWitnessShared({DateTime? now}) async {
    if (witness == null) return;
    witness!.lastSharedAt = now ?? DateTime.now();
    await _save();
  }

  /// The weekly note, ready to paste into a message.
  String witnessMessage({DateTime? now}) {
    final lines = <String>[];
    for (final habit in activeHabits) {
      final stats = HabitStats.of(habit, now: now);
      final pct = stats.consistencyPercent;
      lines.add('${habit.name}: ${pct == null ? 'just started' : '$pct%'} '
          'over the last 30 days (${stats.votes} '
          '${stats.votes == 1 ? 'day' : 'days'} total).');
    }
    if (lines.isEmpty) return 'No active habits this week.';
    return 'Weekly check-in:\n${lines.join('\n')}';
  }
}
