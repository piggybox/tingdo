import 'package:flutter_test/flutter_test.dart';
import 'package:tingdo/logic/anchor.dart';

void main() {
  group('validateAnchor', () {
    test('accepts a concrete cue', () {
      expect(validateAnchor('After I pour my coffee'), isNull);
      expect(validateAnchor('Before I get in the shower'), isNull);
      expect(validateAnchor('When I sit down at my desk'), isNull);
    });

    test('rejects clock times, which arrive when you are busy', () {
      expect(validateAnchor('At 7:30am'), isNotNull);
      expect(validateAnchor('After 7 pm'), isNotNull);
      expect(validateAnchor("When it's 8 o'clock"), isNotNull);
    });

    test('rejects wishes dressed up as cues', () {
      expect(validateAnchor('Whenever I can'), isNotNull);
      expect(validateAnchor('When I have time'), isNotNull);
      expect(validateAnchor('Sometime in the day'), isNotNull);
    });

    test('requires the sentence to hang off a moment', () {
      expect(validateAnchor('Coffee'), isNotNull);
      expect(validateAnchor('I write in the kitchen'), isNotNull);
    });

    test('requires enough detail to be findable', () {
      expect(validateAnchor('After coffee'), isNotNull);
    });

    test('every built-in example passes its own validator', () {
      for (final example in anchorExamples) {
        expect(validateAnchor(example), isNull, reason: example);
      }
    });
  });
}
