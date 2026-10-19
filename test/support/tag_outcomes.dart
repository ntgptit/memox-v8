import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

// How the tests of Tag Management read what the tag domain returns. Apart
// from tag_fixtures.dart, which writes rows: the tests that read no database
// do not depend on it, and diff-based test selection follows imports
// (build_verification_plan.py).

/// A tag write the repository accepted.
final isTagOk = isA<Ok<void, TagRejection>>();

/// A tag write the repository refused for [reason].
Matcher isTagRefused<T>(TagRejection reason) => isA<Rejected<T, TagRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

/// Why [result] was refused, or null when it was accepted.
TagRejection? tagReasonOf(Outcome<void, TagRejection> result) =>
    switch (result) {
      Ok() => null,
      Rejected(:final reason) => reason,
    };

/// The tags of [counts] as (name, cards carrying it).
List<(String, int)> tagRows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];
