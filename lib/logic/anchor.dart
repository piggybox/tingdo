/// Validation for the cue a habit hangs off.
///
/// Time-based reminders arrive when you are busy; cue-based ones arrive when
/// the behaviour actually fits. So the app insists on an anchor, and refuses
/// vague ones — a wish is not a cue.
library;

final _leadIn = RegExp(r'^\s*(after|before|when)\b', caseSensitive: false);

final _clockTime = RegExp(
  r'(\b\d{1,2}\s*:\s*\d{2}\b)|(\b\d{1,2}\s*(am|pm)\b)|\bo.?clock\b',
  caseSensitive: false,
);

const _vaguePhrases = <String>[
  'sometime',
  'some time',
  'whenever',
  'when i can',
  'when i have time',
  'if i have time',
  'when i feel like it',
  'when i remember',
  'when i get a chance',
  'when possible',
  'later',
  'at some point',
  'free time',
];

/// Returns null when the anchor is good enough, otherwise the coaching line to
/// show under the field.
String? validateAnchor(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return 'Name the thing that already happens right before it.';
  }

  final lower = text.toLowerCase();

  for (final phrase in _vaguePhrases) {
    if (lower.contains(phrase)) {
      return 'That is a wish, not a cue. Pick something that reliably happens.';
    }
  }

  if (_clockTime.hasMatch(lower)) {
    return 'A clock is not a cue — it arrives when you are busy. '
        'Anchor it to something you already do.';
  }

  if (!_leadIn.hasMatch(lower)) {
    return 'Start with After, Before or When, so it hangs off a real moment.';
  }

  final words = lower.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  if (words < 4) {
    return 'Be more specific — what exactly happens just before?';
  }

  return null;
}

const anchorExamples = <String>[
  'After I pour my coffee',
  'After I close my laptop for the day',
  'Before I get in the shower',
  'When I sit down at my desk',
];
