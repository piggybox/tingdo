# tingdo

A local, offline habit tracker for macOS desktop, built in Flutter.

It is deliberately not a streak app. Streaks are fragile by design: one miss and
the artifact you have been protecting shatters, which is precisely the moment
people quit. Everything here is built to absorb bad days instead of punishing
them.

## Running it

```sh
flutter run -d macos      # dev
flutter test              # 49 tests
flutter build macos       # release build → build/macos/Build/Products/Release
```

Data lives in a single JSON file under the app's support directory
(`~/Library/Containers/com.tingdo.tingdo/Data/Library/Application Support/…/tingdo.json`).
The exact path is shown on the Settings page. Nothing leaves the machine.

## The mechanics

**The floor and the ceiling.** Every habit has two versions: the full one and a
floor that takes under two minutes. Both count as a check, identically. The
floor sits below the full version but is exactly as tappable — one tap, no
confirmation, no "are you sure you don't want to do the real thing?". Friction
there would teach people the floor is cheating, and the mechanic would die.

**A consistency ribbon, not a streak.** A rolling 30-day percentage. One miss
moves 87% to 84% — a nudge, not a collapse. There is nothing to lose, so there
is nothing to abandon.

**One habit at a time, enforced.** A second habit stays locked until the first
is 14 days old and holding at 70%. Artificial scarcity is the feature.

**Anchors, not clocks.** Setup insists on a cue ("After I pour my coffee") and
refuses vague ones and clock times. See `lib/logic/anchor.dart`.

**Identity framing.** Checks are counted as "24 votes for: someone who writes",
not as a day count — evidence about who you are, not points in a game.

**The app tries to lose you.** Nudges quiet down as consistency rises. At 90
days above 80% it offers to graduate the habit into the background and stop
asking about it entirely. A habit app that still needs you daily after six
months has failed.

**Blameless miss review.** Tap any grey day in History, pick one of four
one-word reasons. Once a pattern is real the app says so — "You miss Thursdays,
3 of your last 7 misses. Move the anchor, or take Thursdays off" — with the
adjustment one tap away. Data as a diagnostic, not a scolding.

**Rest days.** Four per rolling window, spent deliberately. They are neutral in
both terms of the consistency fraction — not a miss, not a check.

**One witness.** A single person who gets a weekly note with your number.
Leaderboards create performance anxiety and then abandonment; one person who
asks about it at dinner is the mechanism that actually works. The app composes
the note; you send it.

## UX rules the code holds to

- The home screen is only today. History and Settings are one swipe (or arrow
  key) away.
- Missed days are warm grey, never red. Red reads as failure, failure reads as
  "this app makes me feel bad", and that is how habit apps get deleted.
- Undo is as cheap as the check: tapping the option you already picked clears
  it.
- Copy is a coach, not a drill sergeant. "Rough day? Take a rest day", never
  "Don't break your streak!".

## Layout

```
lib/
  main.dart              app entry, first-run routing
  theme.dart             colour tokens (the grey-not-red rule lives here)
  models/                Habit, DayEntry
  logic/
    stats.dart           consistency, votes, unlock gate, graduation, nudges
    anchor.dart          cue validation
    insights.dart        weekday and reason patterns
  data/store.dart        JSON persistence + all mutations
  screens/               today · history · settings · setup
  widgets/               option tiles, day grid, miss-reason dialog
test/                    unit tests for the logic, widget tests for the flows
```
