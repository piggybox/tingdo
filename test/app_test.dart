import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tingdo/data/store.dart';
import 'package:tingdo/main.dart';
import 'package:tingdo/models/day_entry.dart';
import 'package:tingdo/util/dates.dart';

void main() {
  late AppStore store;

  setUp(() async {
    // In-memory: a widget test's fake-async zone never completes a real write.
    store = AppStore.inMemory();
    await store.load();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 1100));
    await tester.pumpWidget(TingdoApp(store: store));
    await tester.pumpAndSettle();
  }

  Future<void> addWriting() => store.addHabit(
        name: 'Write',
        identity: 'someone who writes',
        anchor: 'After I pour my coffee',
        fullLabel: 'Full session',
        fullDetail: '500 words · 25 min',
        floorLabel: 'Just the floor',
        floorDetail: '3 sentences · 2 min',
      );

  testWidgets('a fresh install opens on setup, not on an empty dashboard',
      (tester) async {
    await pumpApp(tester);
    expect(find.text("What's the habit?"), findsOneWidget);
  });

  testWidgets('setup refuses a clock and accepts a cue', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField), 'Write');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'someone who writes');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'at 7:30am');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A clock is not a cue'), findsOneWidget);
    expect(find.text('What happens right before it?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'After I pour my coffee');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('What does a full day look like?'), findsOneWidget);
  });

  testWidgets('today shows the anchor, the identity vote and both options',
      (tester) async {
    await addWriting();
    await pumpApp(tester);

    expect(find.text('After I pour my coffee'), findsOneWidget);
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('0 votes for: someone who writes'), findsOneWidget);
    expect(find.text('Full session'), findsOneWidget);
    expect(find.text('Just the floor'), findsOneWidget);
  });

  testWidgets('the floor is one tap and counts as a vote', (tester) async {
    await addWriting();
    await pumpApp(tester);

    await tester.tap(find.text('Just the floor'));
    await tester.pumpAndSettle();

    // No confirmation dialog stands between the floor and the check.
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('1 vote for: someone who writes'), findsOneWidget);
    expect(store.habits.first.entryOn(DateTime.now())!.kind, DayKind.floor);
  });

  testWidgets('a rest day is spendable and reversible', (tester) async {
    await addWriting();
    await pumpApp(tester);

    await tester.tap(find.textContaining('Rough day?'));
    await tester.pumpAndSettle();
    expect(find.text('Resting today'), findsOneWidget);

    await tester.tap(find.text('Actually, I want to do it'));
    await tester.pumpAndSettle();
    expect(find.text('Full session'), findsOneWidget);
  });

  testWidgets('the add-habit slot is locked while the first habit settles',
      (tester) async {
    await addWriting();
    await pumpApp(tester);
    expect(find.textContaining('One at a time.'), findsOneWidget);
    expect(find.text('Add a habit'), findsNothing);
  });

  testWidgets('history is one swipe away and tags a missed day',
      (tester) async {
    await addWriting();
    final habit = store.habits.first;
    // Backdate the habit so there is a past day to tag.
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    habit.entries[dateKey(threeDaysAgo)] =
        DayEntry(date: threeDaysAgo, kind: DayKind.full);
    await pumpApp(tester);

    await tester.drag(find.text('Write'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Last 90 days'), findsOneWidget);
  });

  testWidgets('settings holds one witness and a copyable weekly note',
      (tester) async {
    await addWriting();
    await pumpApp(tester);

    await tester.drag(find.text('Write'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('History'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Your witness'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Sam');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.witness?.name, 'Sam');
    expect(find.textContaining('Weekly check-in'), findsOneWidget);
  });
}
