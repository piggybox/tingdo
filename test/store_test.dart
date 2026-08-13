import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tingdo/data/store.dart';
import 'package:tingdo/models/day_entry.dart';
import 'package:tingdo/util/dates.dart';

void main() {
  late Directory dir;
  late AppStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tingdo_test');
    store = AppStore(File('${dir.path}/tingdo.json'));
    await store.load();
  });

  tearDown(() async => dir.delete(recursive: true));

  Future<void> addWriting() => store.addHabit(
        name: 'Write',
        identity: 'someone who writes',
        anchor: 'After I pour my coffee',
        fullLabel: 'Full session',
        fullDetail: '500 words · 25 min',
        floorLabel: 'Just the floor',
        floorDetail: '3 sentences · 2 min',
      );

  test('survives a round trip through disk', () async {
    await addWriting();
    await store.logToday(store.habits.first, DayKind.floor);
    await store.setWitness(Witness(name: 'Sam'));

    final reopened = AppStore(File('${dir.path}/tingdo.json'));
    await reopened.load();

    expect(reopened.habits, hasLength(1));
    expect(reopened.habits.first.floorDetail, '3 sentences · 2 min');
    expect(reopened.habits.first.votes, 1);
    expect(reopened.witness?.name, 'Sam');
  });

  test('tapping the same option again undoes it, with no confirmation', () async {
    await addWriting();
    final habit = store.habits.first;
    await store.logToday(habit, DayKind.full);
    expect(habit.votes, 1);
    await store.logToday(habit, DayKind.full);
    expect(habit.votes, 0);
  });

  test('switching from full to floor replaces rather than stacks', () async {
    await addWriting();
    final habit = store.habits.first;
    await store.logToday(habit, DayKind.full);
    await store.logToday(habit, DayKind.floor);
    expect(habit.entries, hasLength(1));
    expect(habit.entryOn(DateTime.now())!.kind, DayKind.floor);
  });

  test('a second habit is blocked until the first one holds', () async {
    await addWriting();
    expect(store.canAddHabit(), isFalse);
    expect(store.addHabitBlockedReason(), contains('Write'));
  });

  test('a graduated habit stops occupying the slot', () async {
    await addWriting();
    await store.graduate(store.habits.first);
    expect(store.canAddHabit(), isTrue);
    expect(store.activeHabits, isEmpty);
    expect(store.graduatedHabits, hasLength(1));
  });

  test('a miss reason is stored on the day it belongs to', () async {
    await addWriting();
    final habit = store.habits.first;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await store.setMissReason(habit, yesterday, MissReason.tired);
    expect(habit.entryOn(yesterday)!.reason, MissReason.tired);
    expect(habit.entryOn(yesterday)!.kind, DayKind.missed);

    await store.setMissReason(habit, yesterday, null);
    expect(habit.entryOn(yesterday), isNull);
  });

  test('dropping a weekday never empties the schedule', () async {
    await addWriting();
    final habit = store.habits.first;
    await store.dropWeekday(habit, DateTime.thursday);
    expect(habit.activeWeekdays, hasLength(6));
    for (var d = 1; d <= 7; d++) {
      await store.dropWeekday(habit, d);
    }
    expect(habit.activeWeekdays, hasLength(1));
  });

  test('the witness note carries the number, not a streak', () async {
    await addWriting();
    final habit = store.habits.first;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    habit.entries[dateKey(yesterday)] =
        DayEntry(date: yesterday, kind: DayKind.full);
    await store.logToday(habit, DayKind.full);

    final message = store.witnessMessage();
    expect(message, contains('Write'));
    expect(message, contains('%'));
    expect(message, contains('2 days total'));
  });

  test('recovers from a corrupt data file instead of failing to start', () async {
    final file = File('${dir.path}/tingdo.json');
    await file.writeAsString('{ not json');
    final recovered = AppStore(file);
    await recovered.load();
    expect(recovered.isLoaded, isTrue);
    expect(recovered.habits, isEmpty);
  });
}
